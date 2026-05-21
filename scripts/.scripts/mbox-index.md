# mbox-index

Index Google Takeout **MBOX** archives into a searchable **SQLite FTS5** database,
extract attachments to a date/sender file tree, and query the result long after the
mail has been deleted from the cloud.

- **No dependencies** — Python 3 stdlib only (`mailbox`, `email`, `sqlite3` with FTS5).
- **One `.db` file** — portable, openable in any SQLite GUI.
- **Attachments on disk** — de-duplicated by content hash, directly browsable.

Script: `~/.scripts/mbox-index.py`

**End-to-end:** Phase 0 *(get the mbox — manual, in the browser)* → `build` *(index it)* → `search` *(query it forever after)*.

---

## Phase 0 — Get the mbox from Google Takeout

The script indexes `.mbox` files; it does **not** download your mail. Getting the mbox is
a manual, browser-only step — Google has no bulk-export API for consumer Gmail, so nothing
here can be scripted. Do this first.

| Step | Action |
| --- | --- |
| 1. Request | At [takeout.google.com](https://takeout.google.com): **Deselect all** → select **Mail** only → "All Mail data included" (take everything, or pick labels) → file type **MBOX** → delivery **download link by email**, **.zip**, max size **50 GB** → **Create export**. |
| 2. Wait | Google packages it and **emails a download link** — minutes to hours depending on mailbox size. |
| 3. Download + unzip | Save `takeout-*.zip`, then extract. Unzipping yields `Takeout/Mail/*.mbox` — that `.mbox` is the input to `build`. |

```bash
mkdir -p /mnt/d/gmail-backup
mv ~/Downloads/takeout-*.zip /mnt/d/gmail-backup/   # or wherever it landed
cd /mnt/d/gmail-backup
unzip -o takeout-*.zip                              # -> Takeout/Mail/*.mbox
find /mnt/d/gmail-backup -iname '*.mbox'            # confirm before building
```

> If `build` reports **"No .mbox files found"**, Phase 0 is incomplete: the zip isn't
> downloaded, isn't unzipped, or the path is wrong. The script needs the **extracted**
> `.mbox`, never the `.zip`.

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

## Phase 4 — Reclaim quota: delete from Gmail cloud

The archive only earns its keep once you delete the cloud copy. This step is **manual,
in the Gmail web UI** — and irreversible — so verify the local archive *first*.

### 1. Verify the archive before deleting anything

| Check | Command | Pass condition |
| --- | --- | --- |
| Messages indexed | `python3 -c "import sqlite3;print(sqlite3.connect('mail.db').execute('SELECT count(*) FROM messages').fetchone()[0])"` | In the same ballpark as Gmail's message count for the same scope |
| Attachments on disk | `find attachments -type f \| wc -l` | Matches the `attach` row count (same one-liner, `FROM attach`) |
| Content is readable | `python3 ~/.scripts/mbox-index.py search "larger:10M"` | Returns your known big messages, not empty |

> Uses Python's bundled `sqlite3` module — no separate `sqlite3` CLI needed. (If you
> prefer the CLI: `sudo apt install sqlite3`, then `sqlite3 mail.db 'SELECT count(*) FROM messages;'`.)

If any check fails, **stop** — re-run the Takeout export. Once deleted from the cloud,
a botched archive cannot be re-fetched.

### 2. Delete by size in the Gmail UI (where the quota actually is)

Gmail has **labels, not folders**: one underlying message can carry many labels, and the
quota counts the *message*, not each label-view. Consequences that bite:

- **Archiving frees nothing** — the message still exists, just hidden from Inbox.
- Removing a label leaves the message in **All Mail**, still counting against quota.
- Space drops **only** after the message leaves All Mail *and* Trash is emptied.

Target by **size**, not age — large attachments are the hogs. In the Gmail search bar:

| Query | Finds |
| --- | --- |
| `larger:25M` | the worst offenders first |
| `larger:10M` | everything over 10 MB |
| `has:attachment larger:5M older_than:2y` | big + old + has attachment |
| `larger:10M in:anywhere` | includes Spam & Trash too |

Cross-reference each query against the same filter in your local DB before deleting, e.g.
`mbox-index.py search "larger:25M"` — confirm the archive holds what you're about to remove.

Per batch: run the query → click the **select-all checkbox** → click the banner
*"Select all conversations that match this search"* (grabs the whole result set, not just
the visible page) → **Delete**.

### 3. Empty Trash — the step that frees the quota

Nothing changes until you do this. Gmail Trash holds **30 days** and still counts.

1. Left sidebar → **Trash** → **Empty Trash now**.
2. Also **Spam** → Empty — spam counts too.
3. Quota at [one.google.com/storage](https://one.google.com/storage) updates with a lag of
   minutes to a few hours. Don't panic if it's slow.

> **Order is non-negotiable:** verify archive → delete in UI → empty Trash. Deleting before
> verifying, or expecting space back before emptying Trash, are the two ways this goes wrong.

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
