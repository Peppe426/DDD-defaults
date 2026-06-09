using Domain.Common.Common;
using Domain.XXX.Domain.Events;

namespace Domain.XXX.Domain.Aggregates;

public sealed class Order : AggregateRoot
{
    public Guid Id { get; } = Guid.NewGuid();

    public void Confirm()
    {
        RaiseEvent(new OrderConfirmedDomainEvent(Id));
    }
}
