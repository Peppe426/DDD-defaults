using Domain.XXX.Application.EventHandlers;
using Domain.XXX.Domain.Events;
using FluentAssertions;
using NUnit.Framework;

namespace Domain.XXX.Tests;

[TestFixture]
public class SendOrderEmailHandlerTests
{
    [Test]
    public async Task Should_CompleteSuccessfully_When_ValidEventIsHandled()
    {
        // Given
        var handler = new SendOrderEmailHandler();
        var domainEvent = new OrderConfirmedDomainEvent(Guid.NewGuid());

        // When
        Func<Task> act = () => handler.HandleAsync(domainEvent);

        // Then
        await act.Should().NotThrowAsync();
    }

    [Test]
    public async Task Should_ThrowArgumentNullException_When_NullEventIsHandled()
    {
        // Given
        var handler = new SendOrderEmailHandler();

        // When
        Func<Task> act = () => handler.HandleAsync(null!);

        // Then
        await act.Should().ThrowAsync<ArgumentNullException>();
    }
}
