using System;

namespace Domain.ValueObjects.Products;

public class Money
{
    public decimal Amount {get;}
    public string Currency {get;}

    public Money(decimal amount, string currency)
    {
        if (amount < 0)throw new ArgumentException(nameof(amount));
        if (string.IsNullOrWhiteSpace(currency) || currency.Length is < 3 or > 3)
            throw new ArgumentException("Currency must bee ISO-4217 (3 chars).",
            nameof(currency));
        Amount = decimal.Round(amount, 2);
        Currency = currency.ToUpperInvariant();
    }

    public static Money Zero(String currency) => new Money(0, currency);

    public Money add(Money other)
    {
        if (Currency != other.Currency) throw new InvalidOperationException("Currencies mismatch.");
        return new Money(Amount + other.Amount, Currency);
    }

    public Money  Multiply(int qty)
    {
        if (qty < 0) throw new ArgumentOutOfRangeException(nameof(qty));
        return new Money(Amount * qty, Currency);
    }

    public override string ToString() => $" {Currency} {Amount:F2}";
}
