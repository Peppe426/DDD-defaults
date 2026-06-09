# Copilot Instructions

## Build and test commands

- Restore: `dotnet restore DDD-defaults.slnx`
- Build: `dotnet build DDD-defaults.slnx --configuration Release --no-restore`
- Test all: `dotnet test DDD-defaults.slnx --configuration Release --no-build`
- Test one project: `dotnet test tests\Domain.Common.Tests\Domain.Common.Tests.csproj --configuration Release --no-restore`
- Test one NUnit test: `dotnet test tests\Domain.Common.Tests\Domain.Common.Tests.csproj --configuration Release --no-restore --filter "FullyQualifiedName~Domain.Common.Tests.AggregateRootTests.Should_CollectEvent_When_EventIsRaised"`

## High-level architecture

- This repository is a template source, not an application. `src\Domain.Common` contains the reusable DDD building blocks, and `src\Domain.XXX` is a placeholder template for a dedicated `Domain.<Name>` project.
- `Domain.Common` defines the base model primitives under `Common\`: `Entity<TId>` for identity-based equality, `ValueObject` for component-based equality, `AggregateRoot` for collecting domain events, `IDomainEvent` / `DomainEventBase` for event contracts, and `DomainEventDispatcher` for dispatching events through `IServiceProvider`.
- `Domain.XXX` is intentionally almost empty. It preserves the DDD folder layout (`Aggregates`, `Entities`, `ValueObjects`, `Events`) and references `Domain.Common`, but example domain behavior lives in `tests\Domain.XXX.Tests\Support\ExampleDomainModel.cs` instead of the template project so the generated template stays clean.
- The repository also ships scaffolding automation. `scripts\New-DomainTemplate.ps1` installs either the `src\Domain.Common` or `src\Domain.XXX` template through `dotnet new`, and rewrites the `Domain.Common` project reference when a shared project already exists in the target working tree.
- CI packs the real `dotnet new` templates from `src\Domain.Common` and `src\Domain.XXX` into the `Peppe426.DDDDefaults.Templates` NuGet template package, so release artifacts contain the templates rather than the repository zip.

## Key conventions

- Keep `src\Domain.XXX` free of sample domain artifacts. Use the dedicated test support model to demonstrate aggregate, entity, value object, and domain event usage instead of adding example business classes to the template itself.
- Reusable domain infrastructure belongs in `Domain.Common.Common`. Dedicated domain templates should consume those abstractions via project reference rather than duplicating base classes.
- Domain events are raised inside aggregates with `RaiseEvent(...)`, collected on `AggregateRoot.DomainEvents`, and dispatched through `IDomainEventHandler<TEvent>` implementations resolved from dependency injection by `DomainEventDispatcher`.
- Value objects implement equality exclusively through `GetEqualityComponents()`. Entities rely on `Entity<TId>` identity equality and should keep the identifier non-null.
- Tests use NUnit 4 and FluentAssertions with `Should_[ExpectedBehavior]_When_[Condition]` naming and explicit `// Given`, `// When`, `// Then` comments.
- When changing scaffolding behavior, update both the PowerShell script and any repository guidance that describes it, especially `README.md` and `.github\skills\create-domain-template\SKILL.md`.

## Commit messages

- Use **Conventional Commits** when suggesting or creating commit messages.
- Preferred commit types in this repository are: `feat`, `chore`, `docs`, `test`, and `issue`.
- **Do not suggest `fix` by default.** `fix` is reserved for actual bug fixes only.
- Keep subjects short, imperative, and lowercase where practical (for example: `feat: add redis stream health check`).
- If a scope helps clarity, use the standard Conventional Commits shape: `<type>(<scope>): <subject>`.
- If you are unsure how to phrase a commit, follow the Conventional Commits specification and choose the closest allowed type from the list above.