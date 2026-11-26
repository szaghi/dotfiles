Bug report for the `ledger` package (CSV transactions -> per-account report). Users see wrong totals:

1. Floating-point drift: amounts and totals are floats, so sums such as 0.1 + 0.2, or a long series of small
   amounts, come out slightly wrong and the report can show a wrong cent.
2. Rounding: when an amount has more than two decimals, the report must round half-up with ties away from
   zero: 1.005 -> 1.01, -0.125 -> -0.13. It does not.

Fix the package so money is exact:
- parse amounts as `decimal.Decimal` (`Transaction.amt` holds a Decimal);
- `totals_by_account` returns `dict[str, Decimal]` with exact sums;
- the report shows exactly two decimals with half-up rounding (ties away from zero).
The report format must not change otherwise (`account: 12.50`, one line per account, sorted by account).
The existing tests in tests/ must keep passing; do not modify them.
