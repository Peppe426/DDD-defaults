# DDD-defaults
DDD Tempaltes, follows Domain-Driven Design default

## Templates

- `src\Domain.Common` is the shared common/core template.
- `src\Domain.XXX` is the dedicated domain template placeholder.

`Domain.XXX` is intended to model a pure domain project. It scaffolds clean DDD folders with no sample `Order`-style domain artifacts:

- `Aggregates`
- `Entities`
- `ValueObjects`
- `Events`

## Copilot skill

Use the repository skill at `.github\skills\create-domain-template\SKILL.md` to scaffold either:

- `Domain.Common`
- `Domain.<Name>`

The skill drives `scripts\New-DomainTemplate.ps1`, resolves the latest GitHub release of `Peppe426/DDD-defaults`, scaffolds the requested project from the published template assets, defaults the target path to `.\Domain`, and adds a `Domain.Common` project reference for dedicated domains when one already exists in the working tree.

### Install the skill into your own solution

If you want to use the skill from another repository or solution, copy this file into that repo:

```text
<your-solution>\.github\skills\create-domain-template\SKILL.md
```

You can do that by either:

1. Downloading `https://raw.githubusercontent.com/Peppe426/DDD-defaults/main/.github/skills/create-domain-template/SKILL.md`
2. Saving it as `.github\skills\create-domain-template\SKILL.md` in your solution

Once the file is in place, ask Copilot to use the `create-domain-template` skill. The skill will fetch the latest released templates from this repository, so your solution does not need a local checkout of `DDD-defaults`.
