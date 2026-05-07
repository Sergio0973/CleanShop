using System;

namespace Application.Abstractions;

public interface IUnitOfWork
{
    Task <int> SaveChangesAsync(CancellationToken ct = default);

    Task ExcuteInTransactionAsync(Func<CancellationToken, Task> operation, CancellationToken ct = default);
}
