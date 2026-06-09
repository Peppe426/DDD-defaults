using Domain.XXX.Tests.Support;
using FluentAssertions;
using NUnit.Framework;

namespace Domain.XXX.Tests;

[TestFixture]
public class CustomerEmailTests
{
    [Test]
    public void Should_BeEqual_When_EmailsDifferOnlyByCase()
    {
        // Given
        var email1 = new ExampleCustomerEmail("customer@example.com");
        var email2 = new ExampleCustomerEmail("CUSTOMER@example.com");

        // When / Then
        email1.Should().Be(email2);
    }

    [Test]
    public void Should_ThrowArgumentException_When_EmailDoesNotContainAtSign()
    {
        // Given / When
        Action act = () => _ = new ExampleCustomerEmail("customer.example.com");

        // Then
        act.Should().Throw<ArgumentException>();
    }
}
