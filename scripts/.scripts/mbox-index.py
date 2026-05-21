#!/usr/bin/env python3
"""Index Google Takeout MBOX archives into a searchable SQLite FTS5 database.

Parses one or more .mbox files (decoding MIME / transfer-encodings correctly),
extracts attachments to a date/sender file tree, and builds a full-text index
over headers and body text. Stdlib only — no third-party dependencies.

Schema
------
messages : one row per email (metadata + decoded plain-text body)
attach   : one row per extracted attachment, FK to messages
fts      : FTS5 virtual table over (subject, sender, recipients, body)

Usage
-----
    mbox-index.py build  ARCHIVE_DIR  [--db mail.db] [--attach-dir attachments]
    mbox-index.py search "QUERY"      [--db mail.db] [--limit N]
    mbox-index.py show   ID           [--db mail.db] [--chars N | --full]
    mbox-index.py get    ID           [--db mail.db] [--to DIR]

QUERY uses FTS5 match syntax for the text part, plus optional filters:
    from:substr  to:substr  subject:substr  larger:5M  before:YYYY-MM-DD  after:YYYY-MM-DD
Example:
    mbox-index.py search "invoice AND from:acme larger:5M after:2020-01-01"
"""

from __future__ import annotations

import argparse
import email
import email.policy
import hashlib
import mailbox
import re
import shutil
import sqlite3
import sys
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
from pathlib import Path

SIZE_RE = re.compile(r"\blarger:(\d+)([KMG]?)\b", re.IGNORECASE)
FROM_RE = re.compile(r"\bfrom:(\S+)")
TO_RE = re.compile(r"\bto:(\S+)")
SUBJ_RE = re.compile(r"\bsubject:(\S+)")
BEFORE_RE = re.compile(r"\bbefore:(\d{4}-\d{2}-\d{2})")
AFTER_RE = re.compile(r"\bafter:(\d{4}-\d{2}-\d{2})")
HAS_ATTACH_RE = re.compile(r"\bhas:attachment\b", re.IGNORECASE)
_SIZE_MULT = {"": 1, "K": 1024, "M": 1024**2, "G": 1024**3}


def _decode(part: email.message.Message) -> str:
    """Decode a text part to str, tolerating bad charsets."""
    payload = part.get_payload(decode=True)
    if payload is None:
        return ""
    charset = part.get_content_charset() or "utf-8"
    try:
        return payload.decode(charset, errors="replace")
    except (LookupError, ValueError):
        return payload.decode("utf-8", errors="replace")


def _safe_name(name: str) -> str:
    """Make a filesystem-safe component."""
    name = re.sub(r"[^\w.\-@]+", "_", name).strip("_")
    return name[:120] or "unnamed"


def _parse_date(msg: email.message.Message) -> datetime | None:
    raw = msg.get("Date")
    if not raw:
        return None
    try:
        dt = parsedate_to_datetime(raw)
    except (TypeError, ValueError):
        return None
    if dt is None:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def init_db(con: sqlite3.Connection) -> None:
    con.executescript(
        """
        CREATE TABLE IF NOT EXISTS messages (
            id         INTEGER PRIMARY KEY,
            msgid      TEXT,
            date_utc   TEXT,
            year       INTEGER,
            sender     TEXT,
            recipients TEXT,
            subject    TEXT,
            body       TEXT,
            size_bytes INTEGER,
            n_attach   INTEGER DEFAULT 0,
            mbox       TEXT
        );
        CREATE TABLE IF NOT EXISTS attach (
            id        INTEGER PRIMARY KEY,
            msg_id    INTEGER REFERENCES messages(id),
            filename  TEXT,
            mime      TEXT,
            size_bytes INTEGER,
            path      TEXT
        );
        CREATE VIRTUAL TABLE IF NOT EXISTS fts USING fts5(
            subject, sender, recipients, body,
            content='messages', content_rowid='id'
        );
        CREATE INDEX IF NOT EXISTS ix_msg_date ON messages(date_utc);
        CREATE INDEX IF NOT EXISTS ix_msg_size ON messages(size_bytes);
        CREATE INDEX IF NOT EXISTS ix_att_msg  ON attach(msg_id);
        """
    )


def build(args: argparse.Namespace) -> int:
    archive = Path(args.archive_dir).expanduser()
    if not archive.exists():
        print(f"Path does not exist: {archive}\n"
              "  Did you download and unzip the Takeout export? "
              "(see Phase 0 in mbox-index.md)", file=sys.stderr)
        return 1
    if not archive.is_dir():
        print(f"Not a directory: {archive}\n"
              "  Point build at the unzipped Takeout folder, not the .zip.",
              file=sys.stderr)
        return 1
    mboxes = sorted(archive.rglob("*.mbox"))
    if not mboxes:
        print(f"No .mbox files found under {archive}\n"
              "  The directory exists but contains no .mbox. Unzip the Takeout "
              "export here first (yields Takeout/Mail/*.mbox).", file=sys.stderr)
        return 1
    attach_root = Path(args.attach_dir).expanduser()
    attach_root.mkdir(parents=True, exist_ok=True)

    con = sqlite3.connect(args.db)
    init_db(con)

    n_msg = n_att = 0
    seen: set[str] = set()  # de-dupe by Message-ID across label exports
    for mb_path in mboxes:
        print(f"-> {mb_path.name}", file=sys.stderr)
        mb = mailbox.mbox(str(mb_path), factory=None)
        for key in mb.keys():
            try:
                raw = mb.get_bytes(key)
                msg = email.message_from_bytes(raw, policy=email.policy.default)
            except Exception as e:  # noqa: BLE001 - archive data is untrusted/messy
                print(f"   skip (parse error): {e}", file=sys.stderr)
                continue

            msgid = (msg.get("Message-ID") or "").strip()
            if msgid and msgid in seen:
                continue
            if msgid:
                seen.add(msgid)

            dt = _parse_date(msg)
            year = dt.year if dt else 0
            body_parts: list[str] = []
            atts: list[tuple[str, str, int, str]] = []

            for part in msg.walk():
                if part.is_multipart():
                    continue
                disp = (part.get_content_disposition() or "").lower()
                ctype = part.get_content_type()
                fname = part.get_filename()
                if disp == "attachment" or fname:
                    payload = part.get_payload(decode=True) or b""
                    fname = _safe_name(fname or f"part.{ctype.replace('/', '_')}")
                    sender_dir = _safe_name((msg.get("From") or "unknown").split("<")[-1].rstrip(">"))
                    digest = hashlib.sha1(payload).hexdigest()[:8]  # noqa: S324 - dedup id, not security
                    dest_dir = attach_root / str(year or "unknown") / sender_dir
                    dest_dir.mkdir(parents=True, exist_ok=True)
                    dest = dest_dir / f"{digest}_{fname}"
                    if not dest.exists():
                        dest.write_bytes(payload)
                    atts.append((fname, ctype, len(payload), str(dest)))
                elif ctype == "text/plain":
                    body_parts.append(_decode(part))
                elif ctype == "text/html" and not body_parts:
                    html = _decode(part)
                    body_parts.append(re.sub(r"<[^>]+>", " ", html))

            body = "\n".join(body_parts)
            cur = con.execute(
                """INSERT INTO messages
                   (msgid,date_utc,year,sender,recipients,subject,body,size_bytes,n_attach,mbox)
                   VALUES (?,?,?,?,?,?,?,?,?,?)""",
                (
                    msgid,
                    dt.isoformat() if dt else None,
                    year,
                    str(msg.get("From") or ""),
                    str(msg.get("To") or ""),
                    str(msg.get("Subject") or ""),
                    body,
                    len(raw),
                    len(atts),
                    mb_path.name,
                ),
            )
            mid = cur.lastrowid
            con.execute(
                "INSERT INTO fts(rowid,subject,sender,recipients,body) VALUES (?,?,?,?,?)",
                (mid, str(msg.get("Subject") or ""), str(msg.get("From") or ""),
                 str(msg.get("To") or ""), body),
            )
            for fname, ctype, size, path in atts:
                con.execute(
                    "INSERT INTO attach(msg_id,filename,mime,size_bytes,path) VALUES (?,?,?,?,?)",
                    (mid, fname, ctype, size, path),
                )
            n_msg += 1
            n_att += len(atts)
            if n_msg % 500 == 0:
                con.commit()
                print(f"   {n_msg} messages, {n_att} attachments...", file=sys.stderr)

    con.commit()
    con.execute("INSERT INTO fts(fts) VALUES('optimize')")
    con.commit()
    con.close()
    print(f"Done: {n_msg} messages, {n_att} attachments -> {args.db}", file=sys.stderr)
    return 0


def search(args: argparse.Namespace) -> int:
    q = args.query
    filters: list[str] = []
    params: list[object] = []

    def pop(rx: re.Pattern) -> str | None:
        nonlocal q
        m = rx.search(q)
        if not m:
            return None
        q = rx.sub("", q, count=1)
        return m.group(1)

    if HAS_ATTACH_RE.search(q):
        q = HAS_ATTACH_RE.sub("", q, count=1)
        filters.append("m.n_attach > 0")
    if (m := SIZE_RE.search(q)):
        q = SIZE_RE.sub("", q, count=1)
        filters.append("m.size_bytes >= ?")
        params.append(int(m.group(1)) * _SIZE_MULT[m.group(2).upper()])
    if (v := pop(FROM_RE)):
        filters.append("m.sender LIKE ?")
        params.append(f"%{v}%")
    if (v := pop(TO_RE)):
        filters.append("m.recipients LIKE ?")
        params.append(f"%{v}%")
    if (v := pop(SUBJ_RE)):
        filters.append("m.subject LIKE ?")
        params.append(f"%{v}%")
    if (v := pop(BEFORE_RE)):
        filters.append("m.date_utc < ?")
        params.append(v)
    if (v := pop(AFTER_RE)):
        filters.append("m.date_utc >= ?")
        params.append(v)

    text = q.strip()
    con = sqlite3.connect(args.db)
    con.row_factory = sqlite3.Row

    if text:
        base = ("SELECT m.* FROM fts JOIN messages m ON m.id = fts.rowid "
                "WHERE fts MATCH ?")
        sql_params: list[object] = [text, *params]
    else:
        base = "SELECT m.* FROM messages m WHERE 1=1"
        sql_params = list(params)
    if filters:
        base += " AND " + " AND ".join(filters)
    base += " ORDER BY m.date_utc DESC LIMIT ?"
    sql_params.append(args.limit)

    rows = con.execute(base, sql_params).fetchall()
    for r in rows:
        date = (r["date_utc"] or "????-??-??")[:10]
        sender = (r["sender"] or "")[:30]
        subj = (r["subject"] or "")[:50]
        tag = f"  [{r['n_attach']} attach, {r['size_bytes']/1e6:.1f}MB]" if r["n_attach"] else ""
        print(f"{r['id']:>6}  {date}  {sender:<30}  {subj}{tag}")
    print(f"\n{len(rows)} result(s)  —  read one with: show <id>", file=sys.stderr)
    con.close()
    return 0


def show(args: argparse.Namespace) -> int:
    con = sqlite3.connect(args.db)
    con.row_factory = sqlite3.Row
    r = con.execute("SELECT * FROM messages WHERE id = ?", (args.id,)).fetchone()
    if r is None:
        print(f"No message with id {args.id} (use `search` to find ids)", file=sys.stderr)
        con.close()
        return 1
    print(f"Id:      {r['id']}")
    print(f"Date:    {r['date_utc'] or '(none)'}")
    print(f"From:    {r['sender']}")
    print(f"To:      {r['recipients']}")
    print(f"Subject: {r['subject']}")
    print(f"Size:    {r['size_bytes']/1e6:.1f}MB   Mbox: {r['mbox']}")
    atts = con.execute(
        "SELECT filename, mime, size_bytes, path FROM attach WHERE msg_id = ?", (args.id,)
    ).fetchall()
    if atts:
        print(f"\nAttachments ({len(atts)}):")
        for a in atts:
            print(f"  {a['size_bytes']/1e6:6.1f}MB  {a['mime']:<24}  {a['filename']}")
            print(f"           -> {a['path']}")
    body = r["body"] or ""
    if args.full or len(body) <= args.chars:
        shown = body
    else:
        shown = body[: args.chars] + f"\n... [{len(body) - args.chars} more chars; --full for all]"
    print("\n" + "-" * 72)
    print(shown)
    con.close()
    return 0


def get(args: argparse.Namespace) -> int:
    con = sqlite3.connect(args.db)
    con.row_factory = sqlite3.Row
    atts = con.execute(
        "SELECT filename, size_bytes, path FROM attach WHERE msg_id = ? ORDER BY id",
        (args.id,),
    ).fetchall()
    con.close()
    if not atts:
        print(f"No attachments for message id {args.id} "
              "(does it exist? `search` lists ids, `show` lists attachments)",
              file=sys.stderr)
        return 1

    dest_dir = Path(args.to).expanduser()
    dest_dir.mkdir(parents=True, exist_ok=True)
    copied = 0
    for a in atts:
        src = Path(a["path"])
        if not src.exists():
            print(f"  MISSING on disk: {src}", file=sys.stderr)
            continue
        out = dest_dir / _safe_name(a["filename"])
        # avoid clobbering when one message has two attachments of the same name
        if out.exists():
            stem, suf = out.stem, out.suffix
            n = 1
            while out.exists():
                out = dest_dir / f"{stem}_{n}{suf}"
                n += 1
        shutil.copy2(src, out)
        print(f"  -> {out}   ({a['size_bytes']/1e6:.1f}MB)")
        copied += 1
    print(f"{copied} attachment(s) copied", file=sys.stderr)
    return 0 if copied else 1


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)

    b = sub.add_parser("build", help="parse mbox(es) and build the index")
    b.add_argument("archive_dir", help="directory containing .mbox files (recursed)")
    b.add_argument("--db", default="mail.db")
    b.add_argument("--attach-dir", default="attachments")
    b.set_defaults(func=build)

    s = sub.add_parser("search", help="query the index")
    s.add_argument("query")
    s.add_argument("--db", default="mail.db")
    s.add_argument("--limit", type=int, default=50)
    s.set_defaults(func=search)

    sh = sub.add_parser("show", help="print one message (headers + body) by id")
    sh.add_argument("id", type=int, help="row id from `search` output")
    sh.add_argument("--db", default="mail.db")
    sh.add_argument("--chars", type=int, default=4000, help="body chars to print (default 4000)")
    sh.add_argument("--full", action="store_true", help="print the entire body, no truncation")
    sh.set_defaults(func=show)

    g = sub.add_parser("get", help="copy a message's attachments out, with original names")
    g.add_argument("id", type=int, help="row id from `search` output")
    g.add_argument("--db", default="mail.db")
    g.add_argument("--to", default=".", help="destination directory (default: cwd)")
    g.set_defaults(func=get)

    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
