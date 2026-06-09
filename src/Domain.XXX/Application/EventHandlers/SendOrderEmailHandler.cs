using Domain.Common.Common;
using Domain.XXX.Domain.Events;

namespace Domain.XXX.Application.EventHandlers;

public sealed class SendOrderEmailHandler : IDomainEventHandler<OrderConfirmedDomainEvent>
{
    public Task HandleAsync(OrderConfirmedDomainEvent domainEvent)
    {
        ArgumentNullException.ThrowIfNull(domainEvent);

        // In a real implementation this would send an email.
        // The handler stays free of infrastructure concerns at the interface boundary.
        return Task.CompletedTask;
    }
}
