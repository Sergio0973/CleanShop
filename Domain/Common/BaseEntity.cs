using System;

namespace Domain;

public abstract class BaseEntity<TId>
{
    public TId Id { get; protected set; } = default!;
    public DateTime CreatedAt { get; protected set; } = DateTime.UtcNow;
    protected BaseEntity() {}
}