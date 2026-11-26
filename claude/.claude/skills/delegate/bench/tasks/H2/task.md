Feature request for the `ledger` package (CSV transactions -> per-account report): monthly grouping.

1. In `ledger/report.py` add `totals_by_month(txs)` returning `{month: {account: total}}`, where month is
   the transaction date's `YYYY-MM`. A date that is not `YYYY-MM-DD` must raise `ValueError`.
2. In the CLI (`ledger/cli.py`) add a `--by-month` flag. With it, `ledger FILE --by-month` prints, for each
   month in ascending order, a header line `== YYYY-MM ==` followed by that month's per-account lines in the
   existing format (`account: 12.50`, sorted by account). Months with no transactions are not printed.
   `--by-month` combines with the existing `--account` filter.
3. Without `--by-month` the output must not change.
The existing tests in tests/ must keep passing; do not modify them.
