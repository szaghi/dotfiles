from dataclasses import dataclass


@dataclass
class Transaction:
    date: str  # YYYY-MM-DD
    account: str
    amt: float
    memo: str = ""
