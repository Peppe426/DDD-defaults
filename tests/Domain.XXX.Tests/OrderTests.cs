using Domain.XXX.Application.EventHandlers;
using Domain.XXX.Domain.Aggregates;
using Domain.XXX.Domain.Events;
using FluentAssertions;
using NUnit.Framework;

namespace Domain.XXX.Tests;

[TestFixture]
public class OrderTests
{
    [Test]
    public void Should_RaiseOrderConfirmedDomainEvent_When_OrderIsConfirmed()
    {
        // Given
        var order = new Order();

        // When
        order.Confirm();

        // Then
        order.DomainEvents.Should()
            .ContainSingle(e => e is OrderConfirmedDomainEvent);
    }

    [Test]
    public void Should_RaiseEventWithCorrectOrderId_When_OrderIsConfirmed()
    {
        // Given
        var order = new Order();

        // When
        order.Confirm();

        // Then
        var domainEvent = order.DomainEvents.Should()
            .ContainSingle().Which.Should().BeOfType<OrderConfirmedDomainEvent>().Subject;

        domainEvent.OrderId.Should().Be(order.Id);
    }

    [Test]
    public void Should_BeEmpty_When_EventsAreClearedAfterConfirmation()
    {
        // Given
        var order = new Order();
        order.Confirm();

        // When
        order.ClearEvents();

        // Then
        order.DomainEvents.Should().BeEmpty();
    }

    [Test]
    public void Should_HaveOccurredOnSet_When_OrderIsConfirmed()
    {
        // Given
        var before = DateTime.UtcNow;
        var order = new Order();

        // When
        order.Confirm();
        var after = DateTime.UtcNow;

        // Then
        var domainEvent = (OrderConfirmedDomainEvent)order.DomainEvents.Single();
        domainEvent.OccurredOn.Should().BeOnOrAfter(before).And.BeOnOrBefore(after);
    }
}
