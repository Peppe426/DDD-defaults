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

This skill is designed to work from **any** solution or folder. It downloads the current `New-DomainTemplate.ps1` script from `Peppe426/DDD-defaults` and uses that script to scaffold from the **latest GitHub release** assets instead of assuming this repository is checked out locally.

## Workflow

1. Ask whether to create:
   - `Domain.Common`
   - a dedicated domain project
2. If the user chooses a dedicated domain project, ask for the domain name and use the format `Domain.<Name>`.
3. Ask the user to confirm the target path. Default to:

   ```powershell
   .\Domain
   ```

4. Download the scaffolding script to a temporary file:

   ```powershell
   $repository = 'Peppe426/DDD-defaults'
   $headers = @{
      Accept = 'application/vnd.github+json'
      'User-Agent' = 'DDD-defaults-scaffolder'
   }
   $scriptPath = Join-Path $env:TEMP ("New-DomainTemplate-{0}.ps1" -f ([Guid]::NewGuid().ToString('N')))
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$repository/main/scripts/New-DomainTemplate.ps1" -Headers $headers -OutFile $scriptPath
   ```

5. Run the downloaded scaffolding script:

   - For `Domain.Common`:

     ```powershell
    & $scriptPath -Template common -DestinationRoot "<target-path>" -Repository $repository
     ```

   - For a dedicated domain:

     ```powershell
    & $scriptPath -Template domain -DomainName "<name>" -DestinationRoot "<target-path>" -Repository $repository
     ```

6. Clean up the temporary script:

   ```powershell
   Remove-Item -LiteralPath $scriptPath -Force
   ```

7. Report the generated project path back to the user.

## Behavior

- The script downloads the template source from the latest public GitHub release of `Peppe426/DDD-defaults`.
- Dedicated domain projects are scaffolded from `src\Domain.XXX`.
- Dedicated domain projects use the DDD folder structure:
  - `Aggregates`
  - `Entities`
  - `ValueObjects`
  - `Events`
- If a `Domain.Common.csproj` already exists under the current working tree, the generated dedicated domain project adds a `ProjectReference` to it.
- The skill must not assume the user is currently inside the `DDD-defaults` repository.
