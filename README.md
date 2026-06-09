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

The skill drives `scripts\New-DomainTemplate.ps1`, which downloads the public repository template, scaffolds the requested project, defaults the target path to `.\Domain`, and adds a `Domain.Common` project reference for dedicated domains when one already exists in the working tree.
