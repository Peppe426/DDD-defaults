using Domain.XXX.Tests.Support;
using FluentAssertions;
using NUnit.Framework;

namespace Domain.XXX.Tests;

[TestFixture]
public class OrderTests
{
    [Test]
    public void Should_AddOrderItem_When_OrderIsNotConfirmed()
    {
        // Given
        var order = new ExampleOrder(new ExampleCustomerEmail("customer@example.com"));
        var item = new ExampleOrderItem(Guid.NewGuid(), "SKU-123", 1);

        // When
        order.AddItem(item);

        // Then
        order.Items.Should().ContainSingle().Which.Should().Be(item);
    }

    [Test]
    public void Should_RaiseOrderConfirmedDomainEvent_When_OrderIsConfirmed()
    {
        // Given
        var order = new ExampleOrder(new ExampleCustomerEmail("customer@example.com"));

        // When
        order.Confirm();

        // Then
        order.DomainEvents.Should()
            .ContainSingle(e => e is ExampleOrderConfirmedDomainEvent);
    }

    [Test]
    public void Should_PreventChanges_When_OrderHasBeenConfirmed()
    {
        // Given
        var order = new ExampleOrder(new ExampleCustomerEmail("customer@example.com"));
        order.Confirm();

        // When
        Action act = () => order.AddItem(new ExampleOrderItem(Guid.NewGuid(), "SKU-123", 1));

        // Then
        act.Should().Throw<InvalidOperationException>();
    }

    [Test]
    public void Should_HaveOccurredOnSet_When_OrderIsConfirmed()
    {
        // Given
        var order = new ExampleOrder(new ExampleCustomerEmail("customer@example.com"));

        // When
        order.Confirm();

        // Then
        var domainEvent = (ExampleOrderConfirmedDomainEvent)order.DomainEvents.Single();
        domainEvent.OccurredOn.Should().BeCloseTo(DateTime.UtcNow, precision: TimeSpan.FromSeconds(5));
    }
}
