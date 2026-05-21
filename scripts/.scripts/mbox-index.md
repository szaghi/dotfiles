# mbox-index

Index Google Takeout **MBOX** archives into a searchable **SQLite FTS5** database,
extract attachments to a date/sender file tree, and query the result long after the
mail has been deleted from the cloud.

- **No dependencies** — Python 3 stdlib only (`mailbox`, `email`, `sqlite3` with FTS5).
- **One `.db` file** — portable, openable in any SQLite GUI.
- **Attachments on disk** — de-duplicated by content hash, directly browsable.

Script: `~/.scripts/mbox-index.py`

---

## Why not just `grep` the mbox?

| What you'd expect | What actually happens | How `mbox-index` handles it |
| --- | --- | --- |
| `grep invoice file.mbox` finds the email | Bodies are base64 / quoted-printable — `grep` sees `aW52b2ljZQ==`, no match | Decodes every MIME part before indexing |
| Match "from a sender" | Headers and body are one flat stream | Separate `sender` / `body` columns, queryable independently |
| Filter by size or date | mbox has no structure, just byte offsets | `larger:` / `before:` / `after:` filters on indexed columns |
| One hit per email | Takeout exports per-label — a 3-label message appears 3× | De-duplicated by `Message-ID` |

---

## Commands at a glance

| Command | Effect |
| --- | --- |
| `mbox-index.py build DIR` | Parse every `.mbox` under `DIR`, build `mail.db`, extract attachments to `./attachments` |
| `mbox-index.py build DIR --db PATH --attach-dir PATH` | Same, with custom output locations |
| `mbox-index.py search "QUERY"` | Query `mail.db`, newest first, 50 results |
| `mbox-index.py search "QUERY" --db PATH --limit N` | Query a specific DB, cap results at `N` |

All paths are flags — nothing is hardcoded. Defaults (`mail.db`, `attachments`) are
relative to your **current working directory**, not the script or the archive.

---

## Build options

| Flag | Default | Meaning |
| --- | --- | --- |
| `archive_dir` (positional) | — | Directory holding `.mbox` files; searched **recursively** |
| `--db` | `mail.db` (in cwd) | Output SQLite database path |
| `--attach-dir` | `attachments` (in cwd) | Root of the extracted-attachment tree |

## Search options

| Flag | Default | Meaning |
| --- | --- | --- |
| `query` (positional) | — | FTS5 text + filter tokens (see below) |
| `--db` | `mail.db` (in cwd) | Database to query — must match what `build` wrote |
| `--limit` | `50` | Maximum rows returned |

> `search` does **not** remember where `build` put the DB. If you used a custom
> `--db` to build, pass the same `--db` to search.

---

## Query syntax

A query is **free-text** (matched by FTS5 over subject/sender/recipients/body) plus any
of these **filter tokens**, which are stripped out and applied as structured conditions:

| Token | Matches | Example |
| --- | --- | --- |
| *(bare words)* | Full-text in subject/sender/body | `invoice`, `invoice AND receipt` |
| `from:SUBSTR` | Sender contains substring | `from:acme.com` |
| `to:SUBSTR` | Recipient contains substring | `to:me@gmail.com` |
| `subject:SUBSTR` | Subject contains substring | `subject:order` |
| `has:attachment` | Message has ≥ 1 attachment | `has:attachment larger:5M` |
| `larger:N[K\|M\|G]` | Raw message ≥ size | `larger:5M`, `larger:500K` |
| `before:YYYY-MM-DD` | Dated before | `before:2021-01-01` |
| `after:YYYY-MM-DD` | Dated on/after | `after:2020-01-01` |

FTS5 boolean operators (`AND`, `OR`, `NOT`, quoted `"phrases"`, `prefix*`) work in the
text part. Filters combine with **AND**.

---

## Worked examples

| Goal | Command |
| --- | --- |
| First-time index of a Takeout export | `python3 ~/.scripts/mbox-index.py build ~/mail-archive/Takeout/Mail` |
| Index to a NAS, keep nothing in `$HOME` | `python3 ~/.scripts/mbox-index.py build /mnt/nas/gmail --db /mnt/nas/gmail/mail.db --attach-dir /mnt/nas/gmail/attachments` |
| Find your quota hogs (biggest first) | `python3 ~/.scripts/mbox-index.py search "larger:25M"` |
| Big old attachments worth purging | `python3 ~/.scripts/mbox-index.py search "has:attachment larger:5M before:2022-01-01"` |
| Everything from one sender | `python3 ~/.scripts/mbox-index.py search "from:linkedin"` |
| Full-text + sender + size + date | `python3 ~/.scripts/mbox-index.py search "invoice AND from:acme larger:5M after:2020-01-01"` |
| Query a NAS-hosted DB, top 10 only | `python3 ~/.scripts/mbox-index.py search "receipt" --db /mnt/nas/gmail/mail.db --limit 10` |

### Sample session

```
$ python3 ~/.scripts/mbox-index.py build ~/mail-archive/Takeout/Mail \
          --db ~/mail-archive/mail.db --attach-dir ~/mail-archive/attachments
-> All mail Including Spam and Trash.mbox
   500 messages, 87 attachments...
   1000 messages, 161 attachments...
Done: 1438 messages, 233 attachments -> ~/mail-archive/mail.db

$ python3 ~/.scripts/mbox-index.py search "invoice AND from:acme larger:5M" \
          --db ~/mail-archive/mail.db
2021-03-12  Acme Billing <billing@acme.   Invoice 4471  [2 attach, 6.1MB]
2020-11-02  Acme Billing <billing@acme.   Invoice 3902  [1 attach, 5.4MB]

2 result(s)
```

Output columns: **date** · **sender** (truncated) · **subject** (truncated) ·
**`[N attach, size]`** when the message carries attachments.

---

## Output layout

```
~/mail-archive/
├── mail.db                         # searchable index (metadata + decoded body text)
└── attachments/
    └── 2021/
        └── billing@acme.com/
            └── 866566a9_invoice4471.pdf   # <8-char content-hash>_<original name>
```

| Table | One row per | Key columns |
| --- | --- | --- |
| `messages` | email | `date_utc`, `sender`, `recipients`, `subject`, `body`, `size_bytes`, `n_attach` |
| `attach` | extracted attachment | `msg_id` → `messages.id`, `filename`, `mime`, `size_bytes`, `path` |
| `fts` | email (FTS5 mirror) | `subject`, `sender`, `recipients`, `body` |

The `.db` opens in **DB Browser for SQLite** if you'd rather click than type.

---

## Custom DB path via env var (optional)

To avoid repeating `--db /long/path` on every search, the script can fall back to an
env var (one-line change, not yet applied):

```python
b.add_argument("--db", default=os.environ.get("MBOX_DB", "mail.db"))
s.add_argument("--db", default=os.environ.get("MBOX_DB", "mail.db"))
```

```bash
export MBOX_DB=~/mail-archive/mail.db   # in ~/.bash/exports
python3 ~/.scripts/mbox-index.py search "larger:25M"   # picks up MBOX_DB
```

---

## Caveats

- **HTML fallback is regex tag-stripping**, not a renderer. Heavily-styled mail indexes
  as noisy-but-searchable text — fine for finding, not pretty for reading.
- **Body text is stored inline** in the DB. For a 40 GB mailbox the `.db` may be a few
  GB (attachments live on disk, not in the DB, so still far smaller than the mbox).
- **Defaults are cwd-relative.** Run `build` from `~` → `~/mail.db`; from `/tmp` →
  `/tmp/mail.db`. Pass `--db` explicitly to land it next to the archive.
