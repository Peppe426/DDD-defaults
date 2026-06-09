[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('common', 'domain')]
    [string]$Template,

    [string]$DomainName,

    [string]$DestinationRoot = (Join-Path (Get-Location) 'Domain'),

    [string]$LocalRepositoryRoot,

    [string]$Repository = 'Peppe426/DDD-defaults',

    [Alias('Ref')]
    [string]$ReleaseTag
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$templatePackageId = 'Peppe426.DDDDefaults.Templates'
$templatePackageAssetPattern = "$templatePackageId*.nupkg"

function Get-GitHubApiHeaders {
    return @{
        'Accept' = 'application/vnd.github+json'
        'User-Agent' = 'DDD-defaults-scaffolder'
    }
}

function Get-ReleaseMetadata {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepositoryName,

        [string]$Tag
    )

    $headers = Get-GitHubApiHeaders
    $releaseUri = if ([string]::IsNullOrWhiteSpace($Tag))
    {
        "https://api.github.com/repos/$RepositoryName/releases/latest"
    }
    else
    {
        "https://api.github.com/repos/$RepositoryName/releases/tags/$Tag"
    }

    return Invoke-RestMethod -Uri $releaseUri -Headers $headers
}

function Get-ReleaseAsset {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepositoryName,

        [Parameter(Mandatory = $true)]
        [string]$AssetNamePattern,

        [string]$Tag
    )

    $release = Get-ReleaseMetadata -RepositoryName $RepositoryName -Tag $Tag
    $asset = @($release.assets) |
        Where-Object { $_.name -like $AssetNamePattern } |
        Select-Object -First 1

    if ($null -eq $asset)
    {
        $resolvedTag = if ([string]::IsNullOrWhiteSpace($Tag)) { $release.tag_name } else { $Tag }
        throw "Could not locate a release asset matching '$AssetNamePattern' for release '$resolvedTag'."
    }

    return $asset
}

function Download-ReleaseAsset {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Asset
    )

    $downloadPath = Join-Path ([System.IO.Path]::GetTempPath()) ("DDD-defaults-{0}-{1}" -f ([Guid]::NewGuid().ToString('N')), $Asset.name)
    $headers = Get-GitHubApiHeaders

    Invoke-WebRequest -Uri $Asset.browser_download_url -Headers $headers -OutFile $downloadPath

    return $downloadPath
}

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

function Get-TemplateInstallSource {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('common', 'domain')]
        [string]$TemplateName,

        [string]$RepositoryName,

        [string]$Tag,

        [string]$ResolvedRepositoryRoot
    )

    if (-not [string]::IsNullOrWhiteSpace($ResolvedRepositoryRoot))
    {
        if ($TemplateName -eq 'common')
        {
            return (Join-Path $ResolvedRepositoryRoot 'src\Domain.Common')
        }

        return (Join-Path $ResolvedRepositoryRoot 'src\Domain.XXX')
    }

    $templateAsset = Get-ReleaseAsset -RepositoryName $RepositoryName -AssetNamePattern $templatePackageAssetPattern -Tag $Tag
    return Download-ReleaseAsset -Asset $templateAsset
}

function Get-TemplateShortName {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('common', 'domain')]
        [string]$TemplateName
    )

    if ($TemplateName -eq 'common')
    {
        return 'ddd-domain-common'
    }

    return 'ddd-domain-project'
}

function Get-DomainCommonProjectPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SearchRoot,

        [Parameter(Mandatory = $true)]
        [string]$GeneratedProjectPath
    )

    $generatedProjectRoot = (Resolve-Path -LiteralPath $GeneratedProjectPath).Path

    return Get-ChildItem -Path $SearchRoot -Recurse -Filter 'Domain.Common.csproj' -File |
        Where-Object { $_.DirectoryName -ne $generatedProjectRoot } |
        Select-Object -ExpandProperty FullName -First 1
}

function Set-DomainCommonReference {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectFilePath,

        [string]$DomainCommonProjectPath
    )

    [xml]$projectXml = Get-Content -Path $ProjectFilePath -Raw

    $projectNode = $projectXml.SelectSingleNode('/Project')
    $existingReferences = @($projectXml.SelectNodes('/Project/ItemGroup/ProjectReference')) |
        Where-Object { $null -ne $_ -and $_.Include -like '*Domain.Common.csproj' }

    foreach ($reference in $existingReferences)
    {
        $null = $reference.ParentNode.RemoveChild($reference)
    }

    if ([string]::IsNullOrWhiteSpace($DomainCommonProjectPath))
    {
        $projectXml.Save($ProjectFilePath)
        return
    }

    $projectDirectory = Split-Path -Path $ProjectFilePath -Parent
    $relativeReference = [System.IO.Path]::GetRelativePath($projectDirectory, $DomainCommonProjectPath)

    $itemGroup = $projectXml.SelectSingleNode('/Project/ItemGroup')
    if ($null -eq $itemGroup)
    {
        $itemGroup = $projectXml.CreateElement('ItemGroup')
        $null = $projectNode.AppendChild($itemGroup)
    }

    $projectReference = $projectXml.CreateElement('ProjectReference')
    $projectReference.SetAttribute('Include', $relativeReference)
    $null = $itemGroup.AppendChild($projectReference)

    $projectXml.Save($ProjectFilePath)
}

$templateInstallSource = $null
$templateHive = $null

try
{
    if ($Template -eq 'domain' -and [string]::IsNullOrWhiteSpace($DomainName))
    {
        throw 'DomainName is required when Template is ''domain''.'
    }

    $projectName = if ($Template -eq 'common') { 'Domain.Common' } else { "Domain.$DomainName" }
    $repositoryRoot = $null

    if (-not [string]::IsNullOrWhiteSpace($LocalRepositoryRoot))
    {
        $resolvedRepositoryRoot = Resolve-Path -LiteralPath $LocalRepositoryRoot -ErrorAction Stop
        $repositoryRoot = $resolvedRepositoryRoot.Path
    }

    $templateInstallSource = Get-TemplateInstallSource `
        -TemplateName $Template `
        -RepositoryName $Repository `
        -Tag $ReleaseTag `
        -ResolvedRepositoryRoot $repositoryRoot

    if (-not (Test-Path -LiteralPath $templateInstallSource))
    {
        throw "Template source '$templateInstallSource' was not found in the resolved template source."
    }

    New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null

    $destinationPath = Join-Path $DestinationRoot $projectName
    if (Test-Path -LiteralPath $destinationPath)
    {
        throw "Destination '$destinationPath' already exists."
    }

    $templateHive = Join-Path ([System.IO.Path]::GetTempPath()) ("DDD-defaults-hive-{0}" -f ([Guid]::NewGuid().ToString('N')))
    $templateShortName = Get-TemplateShortName -TemplateName $Template

    Invoke-DotNetCommand -Arguments @('new', '--debug:custom-hive', $templateHive, 'install', $templateInstallSource)
    Invoke-DotNetCommand -Arguments @('new', '--debug:custom-hive', $templateHive, $templateShortName, '-n', $projectName, '-o', $destinationPath)

    if ($Template -eq 'domain')
    {
        $projectFilePath = Join-Path $destinationPath "$projectName.csproj"
        $domainCommonProjectPath = Get-DomainCommonProjectPath -SearchRoot (Get-Location).Path -GeneratedProjectPath $destinationPath
        Set-DomainCommonReference -ProjectFilePath $projectFilePath -DomainCommonProjectPath $domainCommonProjectPath
    }

    Write-Host "Scaffolded $projectName to $destinationPath"
}
finally
{
    if ($null -ne $templateInstallSource -and [System.IO.Path]::GetExtension($templateInstallSource) -eq '.nupkg' -and (Test-Path -LiteralPath $templateInstallSource))
    {
        Remove-Item -LiteralPath $templateInstallSource -Force
    }

    if ($null -ne $templateHive -and (Test-Path -LiteralPath $templateHive))
    {
        Remove-Item -LiteralPath $templateHive -Recurse -Force
    }
}
