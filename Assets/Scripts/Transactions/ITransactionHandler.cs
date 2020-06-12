public interface ITransactionHandler<T> where T : ITransactable
{
    // Attempts a transaction, returning the portion that was actually executed (or null if none was possible).
    Transaction<T>? AttemptTransaction(Transaction<T> proposed);
}