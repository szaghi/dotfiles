import argparse
import sys

from .parser import parse_csv
from .report import format_report, totals_by_account


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(prog="ledger")
    p.add_argument("file")
    p.add_argument("--account", help="only this account")
    args = p.parse_args(argv)
    with open(args.file) as fh:
        txs = parse_csv(fh.read())
    if args.account:
        txs = [t for t in txs if t.account == args.account]
    print(format_report(totals_by_account(txs)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
