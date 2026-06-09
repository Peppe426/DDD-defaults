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
$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$scaffoldingScriptPath = Join-Path $PSScriptRoot 'New-DomainTemplate.ps1'
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

    $commonSourceFiles = @(
        'AggregateRoot.cs',
        'DomainEvent.cs',
        'DomainEventDispatcher.cs',
        'Entity.cs',
        'IDomainEventDispatcher.cs',
        'IDomainEventHandler.cs',
        'ValueObject.cs'
    )

    foreach ($sourceFile in $commonSourceFiles)
    {
        if (-not (Test-Path -LiteralPath (Join-Path $commonOutput $sourceFile)))
        {
            throw "Expected generated Domain.Common source file '$sourceFile' at the project root."
        }
    }

    $unexpectedCommonPaths = @(
        (Join-Path $commonOutput 'Common'),
        (Join-Path $commonOutput 'Aggregates'),
        (Join-Path $commonOutput 'Entities'),
        (Join-Path $commonOutput 'ValueObjects'),
        (Join-Path $commonOutput 'Events')
    )

    foreach ($unexpectedPath in $unexpectedCommonPaths)
    {
        if (Test-Path -LiteralPath $unexpectedPath)
        {
            throw "Did not expect generated Domain.Common placeholder path '$unexpectedPath'."
        }
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

    $solutionWorkspace = Join-Path $outputRoot 'SolutionWorkspace'
    $nestedWorkingDirectory = Join-Path $solutionWorkspace 'tools\scaffolding'
    $solutionDestinationRoot = Join-Path $solutionWorkspace 'Domain'
    $solutionPath = $null
    $scaffoldedProjectPath = Join-Path $solutionDestinationRoot 'Domain.Common\Domain.Common.csproj'

    New-Item -ItemType Directory -Path $nestedWorkingDirectory -Force | Out-Null
    Invoke-DotNetCommand -Arguments @('new', 'sln', '-n', 'TemplateSmoke', '-o', $solutionWorkspace)
    $solutionPath = @(
        Join-Path $solutionWorkspace 'TemplateSmoke.slnx'
        Join-Path $solutionWorkspace 'TemplateSmoke.sln'
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1

    if ([string]::IsNullOrWhiteSpace($solutionPath))
    {
        throw "Expected dotnet new sln to create a solution file in '$solutionWorkspace'."
    }

    Push-Location $nestedWorkingDirectory
    try
    {
        & $scaffoldingScriptPath -Template 'common' -DestinationRoot $solutionDestinationRoot -LocalRepositoryRoot $repositoryRoot

        if ($LASTEXITCODE -ne 0)
        {
            throw "Scaffolding script failed with exit code $LASTEXITCODE."
        }
    }
    finally
    {
        Pop-Location
    }

    if (-not (Test-Path -LiteralPath $scaffoldedProjectPath))
    {
        throw "Expected scaffolded project at '$scaffoldedProjectPath'."
    }

    $solutionListOutput = & dotnet sln $solutionPath list
    if ($LASTEXITCODE -ne 0)
    {
        throw "dotnet sln list failed with exit code $LASTEXITCODE."
    }

    if (-not ($solutionListOutput -match 'Domain\\Domain\.Common\\Domain\.Common\.csproj'))
    {
        throw "Expected the scaffolded Domain.Common project to be added to '$solutionPath'."
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
