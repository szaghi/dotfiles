import csv
import io

from .model import Transaction


def parse_csv(text: str) -> list[Transaction]:
    """Parse CSV with header date,account,amount,memo into transactions."""
    rows = csv.DictReader(io.StringIO(text))
    out = []
    for row in rows:
        out.append(
            Transaction(
                date=row["date"].strip(),
                account=row["account"].strip(),
                amt=float(row["amount"]),
                memo=(row.get("memo") or "").strip(),
            )
        )
    return out
