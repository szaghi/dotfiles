Refactor for the `ledger` package (CSV transactions -> per-account report): rename the dataclass field
`Transaction.amt` to `Transaction.amount`, across the whole package, without breaking existing callers.

Requirements:
- `Transaction` stays a dataclass; its fields are date, account, amount, memo (memo defaults to "").
  Positional construction `Transaction(date, account, amount[, memo])` works as before, and equality and repr
  use the new field name.
- Backward compatibility, each emitting `DeprecationWarning`: reading `tx.amt`, assigning `tx.amt = x`
  (which sets `amount`), and the keyword `Transaction(..., amt=x)`. Passing both `amount` and `amt` raises
  `TypeError`. Using the new name emits no warning.
- No module other than `ledger/model.py` may use the old name: parser, report and cli use `amount`, and
  the package itself must not trigger the DeprecationWarning.
The existing tests in tests/ must keep passing; do not modify them.
