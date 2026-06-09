namespace Domain.Common;

public interface IDomainEvent
{
    DateTime OccurredOn { get; }
}

public abstract record DomainEventBase : IDomainEvent
{
    public DateTime OccurredOn { get; init; } = DateTime.UtcNow;
}
