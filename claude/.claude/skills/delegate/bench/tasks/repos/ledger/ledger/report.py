from .model import Transaction


def totals_by_account(txs: list[Transaction]) -> dict[str, float]:
    """Sum of amounts per account."""
    totals: dict[str, float] = {}
    for tx in txs:
        totals[tx.account] = totals.get(tx.account, 0.0) + tx.amt
    return totals


def format_line(account: str, total: float) -> str:
    return f"{account}: {total:.2f}"


def format_report(totals: dict[str, float]) -> str:
    """One line per account, sorted by account name."""
    return "\n".join(format_line(a, totals[a]) for a in sorted(totals))
