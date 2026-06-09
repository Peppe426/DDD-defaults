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

## Workflow

1. Ask whether to create:
   - `Domain.Common`
   - a dedicated domain project
2. If the user chooses a dedicated domain project, ask for the domain name and use the format `Domain.<Name>`.
3. Ask the user to confirm the target path. Default to:

   ```powershell
   .\Domain
   ```

4. Run the scaffolding script:

   - For `Domain.Common`:

     ```powershell
     .\scripts\New-DomainTemplate.ps1 -Template common -DestinationRoot "<target-path>"
     ```

   - For a dedicated domain:

     ```powershell
     .\scripts\New-DomainTemplate.ps1 -Template domain -DomainName "<name>" -DestinationRoot "<target-path>"
     ```

5. Report the generated project path back to the user.

## Behavior

- The script downloads the template source from the public `Peppe426/DDD-defaults` repository.
- Dedicated domain projects are scaffolded from `src\Domain.XXX`.
- Dedicated domain projects use the DDD folder structure:
  - `Aggregates`
  - `Entities`
  - `ValueObjects`
  - `Events`
- If a `Domain.Common.csproj` already exists under the current working tree, the generated dedicated domain project adds a `ProjectReference` to it.
