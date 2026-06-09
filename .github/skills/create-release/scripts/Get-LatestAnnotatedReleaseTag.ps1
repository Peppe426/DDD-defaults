param(
    [string]$RepositoryPath = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..')).Path
)

$resolvedRepositoryPath = (Resolve-Path $RepositoryPath).Path
$tagPattern = '^v\d+\.\d+\.\d+$'

$tagOutput = & git -C $resolvedRepositoryPath for-each-ref `
    --sort=-creatordate `
    --format='%(refname:short)|%(objecttype)' `
    refs/tags

foreach ($line in $tagOutput) {
    if (-not $line) {
        continue
    }

    $parts = $line -split '\|', 2
    if ($parts.Count -ne 2) {
        continue
    }

    $tagName = $parts[0]
    $objectType = $parts[1]

    if ($objectType -eq 'tag' -and $tagName -match $tagPattern) {
        $tagName
        exit 0
    }
}

throw "No annotated release tags matching vX.Y.Z were found in '$resolvedRepositoryPath'."
