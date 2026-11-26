import unittest

from ledger.parser import parse_csv
from ledger.report import format_report, totals_by_account

CSV = "date,account,amount,memo\n2026-01-03,food,12.50,lunch\n2026-01-04,rent,800,\n2026-02-01,food,7.25,dinner\n"


class Basic(unittest.TestCase):
    def test_parse(self):
        txs = parse_csv(CSV)
        self.assertEqual(len(txs), 3)
        self.assertEqual(txs[0].account, "food")

    def test_report(self):
        self.assertEqual(format_report(totals_by_account(parse_csv(CSV))), "food: 19.75\nrent: 800.00")


if __name__ == "__main__":
    unittest.main()
