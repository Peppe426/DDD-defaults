using Domain.Common.Common;
using FluentAssertions;
using NUnit.Framework;

namespace Domain.Common.Tests;

[TestFixture]
public class AggregateRootTests
{
    private sealed class TestAggregate : AggregateRoot
    {
        public void TriggerEvent(IDomainEvent domainEvent) => RaiseEvent(domainEvent);
    }

    private sealed record TestDomainEvent : DomainEventBase;

    [Test]
    public void Should_CollectEvent_When_EventIsRaised()
    {
        // Given
        var aggregate = new TestAggregate();
        var domainEvent = new TestDomainEvent();

        // When
        aggregate.TriggerEvent(domainEvent);

        // Then
        aggregate.DomainEvents.Should().ContainSingle()
            .Which.Should().Be(domainEvent);
    }

    [Test]
    public void Should_CollectMultipleEvents_When_MultipleEventsAreRaised()
    {
        // Given
        var aggregate = new TestAggregate();

        // When
        aggregate.TriggerEvent(new TestDomainEvent());
        aggregate.TriggerEvent(new TestDomainEvent());
        aggregate.TriggerEvent(new TestDomainEvent());

        // Then
        aggregate.DomainEvents.Should().HaveCount(3);
    }

    [Test]
    public void Should_BeEmpty_When_EventsAreClearedAfterRaising()
    {
        // Given
        var aggregate = new TestAggregate();
        aggregate.TriggerEvent(new TestDomainEvent());

        // When
        aggregate.ClearEvents();

        // Then
        aggregate.DomainEvents.Should().BeEmpty();
    }

    [Test]
    public void Should_BeEmpty_When_NoEventsHaveBeenRaised()
    {
        // Given / When
        var aggregate = new TestAggregate();

        // Then
        aggregate.DomainEvents.Should().BeEmpty();
    }

    [Test]
    public void Should_ThrowArgumentNullException_When_NullEventIsRaised()
    {
        // Given
        var aggregate = new TestAggregate();

        // When
        Action act = () => aggregate.TriggerEvent(null!);

        // Then
        act.Should().Throw<ArgumentNullException>();
    }
}
