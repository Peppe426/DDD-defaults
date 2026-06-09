[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PackagePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-DotNetCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    & dotnet @Arguments

    if ($LASTEXITCODE -ne 0)
    {
        throw "dotnet $($Arguments -join ' ') failed with exit code $LASTEXITCODE."
    }
}

$resolvedPackagePath = (Resolve-Path -LiteralPath $PackagePath -ErrorAction Stop).Path
$templateHive = Join-Path ([System.IO.Path]::GetTempPath()) ("ddd-defaults-hive-{0}" -f ([Guid]::NewGuid().ToString('N')))
$outputRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("ddd-defaults-smoke-{0}" -f ([Guid]::NewGuid().ToString('N')))

try
{
    $commonOutput = Join-Path $outputRoot 'Domain.Common'
    $domainOutput = Join-Path $outputRoot 'Domain.Sales'

    Invoke-DotNetCommand -Arguments @('new', '--debug:custom-hive', $templateHive, 'install', $resolvedPackagePath)
    Invoke-DotNetCommand -Arguments @('new', '--debug:custom-hive', $templateHive, 'ddd-domain-common', '-n', 'Domain.Common', '-o', $commonOutput)
    Invoke-DotNetCommand -Arguments @('new', '--debug:custom-hive', $templateHive, 'ddd-domain-project', '-n', 'Domain.Sales', '-o', $domainOutput)

    $commonProject = Join-Path $commonOutput 'Domain.Common.csproj'
    $domainProject = Join-Path $domainOutput 'Domain.Sales.csproj'

    if (-not (Test-Path -LiteralPath $commonProject))
    {
        throw "Expected generated Domain.Common project at '$commonProject'."
    }

    if (-not (Test-Path -LiteralPath $domainProject))
    {
        throw "Expected generated Domain.Sales project at '$domainProject'."
    }

    [xml]$domainProjectXml = Get-Content -Path $domainProject -Raw
    $projectReference = $domainProjectXml.SelectSingleNode('/Project/ItemGroup/ProjectReference')

    if ($null -eq $projectReference -or $projectReference.Include -ne '..\Domain.Common\Domain.Common.csproj')
    {
        throw "Expected Domain.Sales to reference '..\Domain.Common\Domain.Common.csproj'."
    }

    Invoke-DotNetCommand -Arguments @('build', $commonProject, '--configuration', 'Release')
    Invoke-DotNetCommand -Arguments @('build', $domainProject, '--configuration', 'Release')
}
finally
{
    if (Test-Path -LiteralPath $templateHive)
    {
        Remove-Item -LiteralPath $templateHive -Recurse -Force
    }

    if (Test-Path -LiteralPath $outputRoot)
    {
        Remove-Item -LiteralPath $outputRoot -Recurse -Force
    }
}
