[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('common', 'domain')]
    [string]$Template,

    [string]$DomainName,

    [string]$DestinationRoot = (Join-Path (Get-Location) 'Domain'),

    [string]$LocalRepositoryRoot,

    [string]$Repository = 'Peppe426/DDD-defaults',

    [string]$Ref = 'main'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-RepositoryArchive {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepositoryName,

        [Parameter(Mandatory = $true)]
        [string]$RepositoryRef
    )

    $archivePath = Join-Path ([System.IO.Path]::GetTempPath()) ("DDD-defaults-{0}.zip" -f ([Guid]::NewGuid().ToString('N')))
    $archiveUrl = "https://codeload.github.com/$RepositoryName/zip/refs/heads/$RepositoryRef"

    Invoke-WebRequest -Uri $archiveUrl -OutFile $archivePath

    return $archivePath
}

function Expand-RepositoryArchive {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ArchivePath
    )

    $extractPath = Join-Path ([System.IO.Path]::GetTempPath()) ("DDD-defaults-{0}" -f ([Guid]::NewGuid().ToString('N')))
    Expand-Archive -Path $ArchivePath -DestinationPath $extractPath

    $expandedRoot = Get-ChildItem -Path $extractPath -Directory | Select-Object -First 1
    if ($null -eq $expandedRoot)
    {
        throw "Could not locate the extracted repository folder."
    }

    return @{
        ExtractPath = $extractPath
        RepositoryRoot = $expandedRoot.FullName
    }
}

function Copy-TemplateProject {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath
    )

    if (Test-Path -LiteralPath $DestinationPath)
    {
        throw "Destination '$DestinationPath' already exists."
    }

    New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null

    Get-ChildItem -Path $SourcePath -Force |
        Where-Object { $_.Name -notin 'bin', 'obj' } |
        ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $DestinationPath -Recurse -Force
        }
}

function Replace-PlaceholderText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,

        [Parameter(Mandatory = $true)]
        [string]$ProjectName
    )

    $files = Get-ChildItem -Path $ProjectPath -Recurse -File |
        Where-Object { $_.Extension -in '.cs', '.csproj', '.md', '.json', '.yml', '.yaml', '.props', '.targets' }

    foreach ($file in $files)
    {
        $content = Get-Content -Path $file.FullName -Raw
        $updatedContent = $content.Replace('Domain.XXX', $ProjectName)

        if ($updatedContent -ne $content)
        {
            Set-Content -Path $file.FullName -Value $updatedContent -NoNewline
        }
    }

    $templateProjectFile = Join-Path $ProjectPath 'Domain.XXX.csproj'
    if (Test-Path -LiteralPath $templateProjectFile)
    {
        Rename-Item -Path $templateProjectFile -NewName "$ProjectName.csproj"
    }
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

$archivePath = $null
$extractedRepository = $null

try
{
    if ($Template -eq 'domain' -and [string]::IsNullOrWhiteSpace($DomainName))
    {
        throw 'DomainName is required when Template is ''domain''.'
    }

    $projectName = if ($Template -eq 'common') { 'Domain.Common' } else { "Domain.$DomainName" }

    if ([string]::IsNullOrWhiteSpace($LocalRepositoryRoot))
    {
        $archivePath = Get-RepositoryArchive -RepositoryName $Repository -RepositoryRef $Ref
        $extractedRepository = Expand-RepositoryArchive -ArchivePath $archivePath
        $repositoryRoot = $extractedRepository.RepositoryRoot
    }
    else
    {
        $resolvedRepositoryRoot = Resolve-Path -LiteralPath $LocalRepositoryRoot -ErrorAction Stop
        $repositoryRoot = $resolvedRepositoryRoot.Path
    }

    $templateRoot = if ($Template -eq 'common')
    {
        Join-Path $repositoryRoot 'src\Domain.Common'
    }
    else
    {
        Join-Path $repositoryRoot 'src\Domain.XXX'
    }

    if (-not (Test-Path -LiteralPath $templateRoot))
    {
        throw "Template path '$templateRoot' was not found in the downloaded repository."
    }

    New-Item -ItemType Directory -Path $DestinationRoot -Force | Out-Null

    $destinationPath = Join-Path $DestinationRoot $projectName
    Copy-TemplateProject -SourcePath $templateRoot -DestinationPath $destinationPath

    if ($Template -eq 'domain')
    {
        Replace-PlaceholderText -ProjectPath $destinationPath -ProjectName $projectName

        $projectFilePath = Join-Path $destinationPath "$projectName.csproj"
        $domainCommonProjectPath = Get-DomainCommonProjectPath -SearchRoot (Get-Location).Path -GeneratedProjectPath $destinationPath
        Set-DomainCommonReference -ProjectFilePath $projectFilePath -DomainCommonProjectPath $domainCommonProjectPath
    }

    Write-Host "Scaffolded $projectName to $destinationPath"
}
finally
{
    if ($null -ne $archivePath -and (Test-Path -LiteralPath $archivePath))
    {
        Remove-Item -LiteralPath $archivePath -Force
    }

    if ($null -ne $extractedRepository -and (Test-Path -LiteralPath $extractedRepository.ExtractPath))
    {
        Remove-Item -LiteralPath $extractedRepository.ExtractPath -Recurse -Force
    }
}
