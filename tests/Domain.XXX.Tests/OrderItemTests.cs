using Domain.XXX.Tests.Support;
using FluentAssertions;
using NUnit.Framework;

namespace Domain.XXX.Tests;

[TestFixture]
public class OrderItemTests
{
    [Test]
    public void Should_SetProperties_When_OrderItemIsCreated()
    {
        // Given
        var id = Guid.NewGuid();

        // When
        var orderItem = new ExampleOrderItem(id, "SKU-123", 2);

        // Then
        orderItem.Id.Should().Be(id);
        orderItem.Sku.Should().Be("SKU-123");
        orderItem.Quantity.Should().Be(2);
    }

    [Test]
    public void Should_ThrowArgumentOutOfRangeException_When_QuantityIsNotPositive()
    {
        // Given / When
        Action act = () => _ = new ExampleOrderItem(Guid.NewGuid(), "SKU-123", 0);

        // Then
        act.Should().Throw<ArgumentOutOfRangeException>();
    }
}
