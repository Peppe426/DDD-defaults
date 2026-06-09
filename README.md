# DDD-defaults
DDD Tempaltes, follows Domain-Driven Design default

## Templates

- `src\Domain.Common` is the shared common/core template.
- `src\Domain.XXX` is the dedicated domain template placeholder.
- Both templates are published as a real `dotnet new` template pack, not as copied source-folder archives.

`Domain.XXX` is intended to model a pure domain project. It scaffolds clean DDD folders with no sample `Order`-style domain artifacts:

- `Aggregates`
- `Entities`
- `ValueObjects`
- `Events`

## Copilot skill

Use the repository skill at `.github\skills\create-domain-template\SKILL.md` to scaffold either:

- `Domain.Common`
- `Domain.<Name>`

The skill drives the released `scripts\New-DomainTemplate.ps1` asset, resolves a matching `Peppe426.DDDDefaults.Templates.<version>.nupkg` from the same GitHub release, installs that package with `dotnet new`, defaults the target path to `.\Domain`, and rewrites the dedicated domain `ProjectReference` so it points at a local `Domain.Common` project when one already exists in the working tree.

### Use the templates manually

Install the template pack from a GitHub release asset:

```powershell
dotnet new install .\Peppe426.DDDDefaults.Templates.<version>.nupkg
```

Then scaffold either template directly:

```powershell
dotnet new ddd-domain-common -n Domain.Common -o .\Domain\Domain.Common
dotnet new ddd-domain-project -n Domain.Sales -o .\Domain\Domain.Sales
```

GitHub releases publish the template pack and the scaffolding script as release assets. They do **not** publish a zip of the full solution or repository.

### Install the skill into your own solution

If you want to use the skill from another repository or solution, copy this file into that repo:

```text
<your-solution>\.github\skills\create-domain-template\SKILL.md
```

You can do that by either:

1. Downloading `https://raw.githubusercontent.com/Peppe426/DDD-defaults/main/.github/skills/create-domain-template/SKILL.md`
2. Saving it as `.github\skills\create-domain-template\SKILL.md` in your solution

Once the file is in place, ask Copilot to use the `create-domain-template` skill. The skill will fetch the latest released template pack from this repository, so your solution does not need a local checkout of `DDD-defaults`.
