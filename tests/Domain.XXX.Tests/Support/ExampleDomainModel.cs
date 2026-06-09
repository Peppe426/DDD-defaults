using Domain.Common.Common;

namespace Domain.XXX.Tests.Support;

internal sealed class ExampleOrder : AggregateRoot
{
    private readonly List<ExampleOrderItem> _items = [];

    public Guid Id { get; } = Guid.NewGuid();
    public ExampleCustomerEmail CustomerEmail { get; }
    public IReadOnlyCollection<ExampleOrderItem> Items => _items.AsReadOnly();
    public bool IsConfirmed { get; private set; }

    public ExampleOrder(ExampleCustomerEmail customerEmail)
    {
        ArgumentNullException.ThrowIfNull(customerEmail);
        CustomerEmail = customerEmail;
    }

    public void AddItem(ExampleOrderItem item)
    {
        ArgumentNullException.ThrowIfNull(item);

        if (IsConfirmed)
        {
            throw new InvalidOperationException("Confirmed orders cannot be modified.");
        }

        _items.Add(item);
    }

    public void Confirm()
    {
        if (IsConfirmed)
        {
            return;
        }

        IsConfirmed = true;
        RaiseEvent(new ExampleOrderConfirmedDomainEvent(Id));
    }
}

internal sealed class ExampleOrderItem : Entity<Guid>
{
    public string Sku { get; }
    public int Quantity { get; }

    public ExampleOrderItem(Guid id, string sku, int quantity)
        : base(id)
    {
        if (string.IsNullOrWhiteSpace(sku))
        {
            throw new ArgumentException("SKU cannot be empty.", nameof(sku));
        }

        if (quantity <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(quantity), "Quantity must be greater than zero.");
        }

        Sku = sku;
        Quantity = quantity;
    }
}

internal sealed record ExampleOrderConfirmedDomainEvent(Guid OrderId) : DomainEventBase;

internal sealed class ExampleCustomerEmail : ValueObject
{
    public string Value { get; }

    public ExampleCustomerEmail(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException("Email cannot be empty.", nameof(value));
        }

        if (!value.Contains('@'))
        {
            throw new ArgumentException("Email must contain '@'.", nameof(value));
        }

        Value = value.Trim();
    }

    protected override IEnumerable<object?> GetEqualityComponents()
    {
        yield return Value.ToUpperInvariant();
    }
}
