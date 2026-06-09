using Domain.Common;
using FluentAssertions;
using NUnit.Framework;

namespace Domain.Common.Tests;

[TestFixture]
public class ValueObjectTests
{
    private sealed class Money : ValueObject
    {
        public decimal Amount { get; }
        public string Currency { get; }

        public Money(decimal amount, string currency)
        {
            Amount = amount;
            Currency = currency;
        }

        protected override IEnumerable<object?> GetEqualityComponents()
        {
            yield return Amount;
            yield return Currency;
        }
    }

    [Test]
    public void Should_BeEqual_When_AllComponentsAreTheSame()
    {
        // Given
        var money1 = new Money(100m, "USD");
        var money2 = new Money(100m, "USD");

        // When / Then
        money1.Should().Be(money2);
    }

    [Test]
    public void Should_NotBeEqual_When_ComponentsDiffer()
    {
        // Given
        var money1 = new Money(100m, "USD");
        var money2 = new Money(200m, "USD");

        // When / Then
        money1.Should().NotBe(money2);
    }

    [Test]
    public void Should_HaveSameHashCode_When_ComponentsAreTheSame()
    {
        // Given
        var money1 = new Money(50m, "EUR");
        var money2 = new Money(50m, "EUR");

        // When / Then
        money1.GetHashCode().Should().Be(money2.GetHashCode());
    }

    [Test]
    public void Should_SupportEqualityOperator_When_ObjectsHaveSameComponents()
    {
        // Given
        var money1 = new Money(10m, "GBP");
        var money2 = new Money(10m, "GBP");

        // When / Then
        (money1 == money2).Should().BeTrue();
    }

    [Test]
    public void Should_SupportInequalityOperator_When_ObjectsHaveDifferentComponents()
    {
        // Given
        var money1 = new Money(10m, "GBP");
        var money2 = new Money(10m, "USD");

        // When / Then
        (money1 != money2).Should().BeTrue();
    }
}
