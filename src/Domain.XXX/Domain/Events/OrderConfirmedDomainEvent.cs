using Domain.Common.Common;

namespace Domain.XXX.Domain.Events;

public sealed record OrderConfirmedDomainEvent(Guid OrderId) : DomainEventBase;
