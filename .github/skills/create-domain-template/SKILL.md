---
name: create-domain-template
description: Scaffold either Domain.Common or a dedicated Domain.<Name> project from this repository's public templates.
tags:
  - ddd
  - dotnet
  - templates
  - powershell
---

# Create a domain template project

Use this skill when you want to scaffold either the shared `Domain.Common` project or a dedicated `Domain.<Name>` project from this repository.

This skill is designed to work from **any** solution or folder. It resolves a GitHub release from `Peppe426/DDD-defaults`, downloads the `New-DomainTemplate.ps1` asset from that same release, and uses it to install the matching `dotnet new` template package instead of assuming this repository is checked out locally.

The generated output must always be a **standalone C# project** in its own folder, for example:

- `.\Domain\Domain.Common\Domain.Common.csproj`
- `.\Domain\Domain.Sales\Domain.Sales.csproj`

Do **not** copy the template source files into an existing project as loose `.cs` files.

## Workflow

1. Ask whether to create:
   - `Domain.Common`
   - a dedicated domain project
2. If the user chooses a dedicated domain project, ask for the domain name and use the format `Domain.<Name>`.
3. Ask the user to confirm the target path. Default to:

   ```powershell
   .\Domain
   ```

4. Check whether the current directory already contains solution files:

   ```powershell
   $solutions = @(Get-ChildItem -Path (Get-Location) -File | Where-Object { $_.Extension -in @('.sln', '.slnx') })
   ```

   - If exactly one solution is present, use it and add the generated project to that solution.
   - If multiple solutions are present, ask the user which one to use or whether to skip solution integration.
   - If no solution is present, scaffold the project only.

5. Resolve the release to use and download the scaffolding script asset from that exact release:

   ```powershell
   $repository = 'Peppe426/DDD-defaults'
   $headers = @{
      Accept = 'application/vnd.github+json'
      'User-Agent' = 'DDD-defaults-scaffolder'
   }
   $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$repository/releases/latest" -Headers $headers
   $scriptAsset = @($release.assets) | Where-Object { $_.name -eq 'New-DomainTemplate.ps1' } | Select-Object -First 1

   if ($null -eq $scriptAsset) {
      throw "Could not find New-DomainTemplate.ps1 in release $($release.tag_name)."
   }

   $scriptPath = Join-Path $env:TEMP ("New-DomainTemplate-{0}.ps1" -f ([Guid]::NewGuid().ToString('N')))
   Invoke-WebRequest -Uri $scriptAsset.browser_download_url -Headers $headers -OutFile $scriptPath
   ```

6. Run the downloaded scaffolding script:

   - For `Domain.Common`:

     ```powershell
    & $scriptPath -Template common -DestinationRoot "<target-path>" -Repository $repository -ReleaseTag $release.tag_name [-SolutionPath "<solution-path>"]
     ```

   - For a dedicated domain:

     ```powershell
    & $scriptPath -Template domain -DomainName "<name>" -DestinationRoot "<target-path>" -Repository $repository -ReleaseTag $release.tag_name [-SolutionPath "<solution-path>"]
     ```

7. Clean up the temporary script:

   ```powershell
   Remove-Item -LiteralPath $scriptPath -Force
   ```

8. Report the generated project path back to the user and mention the solution file when the project was added to one.

## Behavior

- The script installs a real `dotnet new` template package from the selected public GitHub release of `Peppe426/DDD-defaults`.
- The downloaded script asset and the template package always come from the same release tag.
- Using this skill means creating a **new project folder with a `.csproj`**, not copying template files into an existing project.
- When a solution is supplied or auto-detected in the current directory, the generated project is added to that solution.
- Dedicated domain projects use the DDD folder structure:
  - `Aggregates`
  - `Entities`
  - `ValueObjects`
  - `Events`
- If a `Domain.Common.csproj` already exists under the current working tree, the generated dedicated domain project adds a `ProjectReference` to it.
- The skill must not assume the user is currently inside the `DDD-defaults` repository.
