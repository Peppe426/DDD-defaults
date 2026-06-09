using Domain.Common;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using NUnit.Framework;

namespace Domain.Common.Tests;

[TestFixture]
public class DomainEventDispatcherTests
{
    private sealed record TestDomainEvent : DomainEventBase;

    private sealed class TrackingHandler : IDomainEventHandler<TestDomainEvent>
    {
        public int CallCount { get; private set; }

        public Task HandleAsync(TestDomainEvent domainEvent)
        {
            CallCount++;
            return Task.CompletedTask;
        }
    }

    [Test]
    public async Task Should_CompleteWithoutError_When_NoHandlersAreRegistered()
    {
        // Given
        var provider = new ServiceCollection().BuildServiceProvider();
        var dispatcher = new DomainEventDispatcher(provider);

        // When
        Func<Task> act = () => dispatcher.DispatchAsync([new TestDomainEvent()]);

        // Then
        await act.Should().NotThrowAsync();
    }

    [Test]
    public async Task Should_InvokeHandler_When_SingleHandlerIsRegistered()
    {
        // Given
        var handler = new TrackingHandler();
        var services = new ServiceCollection();
        services.AddSingleton<IDomainEventHandler<TestDomainEvent>>(handler);
        var dispatcher = new DomainEventDispatcher(services.BuildServiceProvider());

        // When
        await dispatcher.DispatchAsync([new TestDomainEvent()]);

        // Then
        handler.CallCount.Should().Be(1);
    }

    [Test]
    public async Task Should_InvokeAllHandlers_When_MultipleHandlersAreRegistered()
    {
        // Given
        var handler1 = new TrackingHandler();
        var handler2 = new TrackingHandler();
        var services = new ServiceCollection();
        services.AddSingleton<IDomainEventHandler<TestDomainEvent>>(handler1);
        services.AddSingleton<IDomainEventHandler<TestDomainEvent>>(handler2);
        var dispatcher = new DomainEventDispatcher(services.BuildServiceProvider());

        // When
        await dispatcher.DispatchAsync([new TestDomainEvent()]);

        // Then
        handler1.CallCount.Should().Be(1);
        handler2.CallCount.Should().Be(1);
    }

    [Test]
    public async Task Should_DispatchEachEventOnce_When_MultipleEventsAreDispatched()
    {
        // Given
        var handler = new TrackingHandler();
        var services = new ServiceCollection();
        services.AddSingleton<IDomainEventHandler<TestDomainEvent>>(handler);
        var dispatcher = new DomainEventDispatcher(services.BuildServiceProvider());

        // When
        await dispatcher.DispatchAsync([new TestDomainEvent(), new TestDomainEvent(), new TestDomainEvent()]);

        // Then
        handler.CallCount.Should().Be(3);
    }

    [Test]
    public void Should_ThrowArgumentNullException_When_ServiceProviderIsNull()
    {
        // Given / When
        Action act = () => _ = new DomainEventDispatcher(null!);

        // Then
        act.Should().Throw<ArgumentNullException>();
    }
}
