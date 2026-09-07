# Loading troubleshooting

Find your error message below. The cause is almost always one of six things.

---

## The fix that avoids all of them

```bash
pip install psycopg2-binary
python postgres/load_to_postgres.py --password YOUR_PASSWORD
```

This connects to PostgreSQL directly and streams every file over the database
connection. No psql, no import wizard, no file permissions, no working directory.
It creates the database if needed, loads all 27 tables in dependency order, adds
the keys and indexes, then validates the result against the source warehouse.

Run it with `--dry-run` first to confirm it can see the files:

```bash
python postgres/load_to_postgres.py --dry-run
```

If anything fails mid-load it rolls back, so you never end up half-loaded.

---

## Error reference

### 1. `syntax error at or near "\"` — or — `\copy: invalid command`

**You are running `\copy` in pgAdmin's Query Tool.** `\copy` is a *psql client*
command, not SQL. pgAdmin's Query Tool only speaks SQL, so it cannot run it.

**Fix:** use `load_to_postgres.py`, or open the psql terminal instead
(pgAdmin: right-click the server → *PSQL Tool*).

---

### 2. `could not open file ".../fct_traffic_observation.csv" for reading: No such file or directory`

**You used `COPY` instead of `\copy`.** Plain `COPY` runs *on the server* and looks
for the file on the server's own filesystem. Even on localhost that is a different
path context, and on a remote server the file simply is not there.

**Fix:** `\copy` (backslash) reads the file on *your* machine and streams it over the
connection. Or use the Python loader, which does the same thing.

---

### 3. `must be superuser or a member of pg_read_server_files to COPY from a file`

Same root cause as #2 — server-side `COPY` needs elevated rights that your login
does not have, and should not need.

**Fix:** `\copy`, or the Python loader.

---

### 4. `\copy: could not open file "powerbi/exports/dim_site.csv": No such file or directory`

**Relative path, wrong working directory.** `\copy` resolves paths from wherever psql
was launched, not from where the `.sql` file lives.

**Fix — option A**, tell psql where to look before running the script:

```
\cd 'C:/Users/Collins/.../its_analytics_platform'
\i postgres/02_load_data.sql
```

Note the **forward slashes**, even on Windows. Backslashes are escape characters here;
`C:\Users` will be read as `C:` followed by a tab.

**Fix — option B**, launch psql from the right folder:

```powershell
cd C:\Users\Collins\...\its_analytics_platform
psql -U postgres -d its_analytics -f postgres/02_load_data.sql
```

**Fix — option C**, use the Python loader, which takes `--data-dir` and defaults to
the correct absolute path.

---

### 5. `relation "marts.fct_traffic_observation" does not exist`

Either `01_create_schema.sql` has not been run, or **you are connected to the wrong
database**. Creating tables in `postgres` and then loading into `its_analytics` is an
easy slip.

**Fix:** confirm where you are, then create the tables:

```sql
SELECT current_database();          -- should return its_analytics
\i postgres/01_create_schema.sql
```

---

### 6. `invalid input syntax for type integer: ""`

**The `NULL ''` option was omitted.** The exports use an empty field for NULL, which is
correct CSV, but PostgreSQL defaults to treating an unquoted empty string as the empty
*string* rather than NULL — which is not a valid integer.

**Fix:** every `\copy` must carry the full option set:

```sql
\copy marts.dim_site FROM 'powerbi/exports/dim_site.csv' WITH (FORMAT csv, HEADER true, NULL '');
```

The generated `02_load_data.sql` already includes this on every line. If you are typing
the command by hand, this is the part people drop.

---

### 7. `extra data after last expected column` — or — `missing data for column`

The file and the table do not line up. Two usual causes:

- **Wrong pairing** — loading `agg_network_daily.csv` into `agg_site_hour_profile`.
- **The table was created by the pgAdmin import wizard** rather than by
  `01_create_schema.sql`, so the column order differs.

**Fix:** drop and recreate from the DDL, which is generated from the source warehouse
and therefore matches the CSV column order exactly:

```sql
DROP SCHEMA marts CASCADE;
DROP SCHEMA report CASCADE;
\i postgres/01_create_schema.sql
```

---

### 8. `'psql' is not recognized as an internal or external command` (Windows)

psql is installed but not on your `PATH`.

**Fix:** call it by full path, adjusting the version number:

```powershell
& "C:\Program Files\PostgreSQL\17\bin\psql.exe" -U postgres -d its_analytics -f postgres/01_create_schema.sql
```

Or add `C:\Program Files\PostgreSQL\17\bin` to your PATH and reopen the terminal.

---

### 9. `password authentication failed for user "postgres"`

**Fix:** pass the password explicitly rather than relying on a prompt:

```powershell
$env:PGPASSWORD="yourpassword"; psql -U postgres -d its_analytics -f postgres/01_create_schema.sql
```

Or with the Python loader: `--password yourpassword`.

---

### 10. `invalid byte sequence for encoding "WIN1252"`

Your client encoding is not UTF-8, and the exports contain UTF-8 characters.

**Fix:** set the encoding before loading:

```sql
SET client_encoding = 'UTF8';
```

---

## Using the pgAdmin import wizard instead

It works, but it is 27 manual imports and it is easy to get wrong. If you go this route:

1. Run `01_create_schema.sql` **first** — let the DDL create the tables. Do not let the
   wizard create them, or the column order will not match.
2. Right-click the table → *Import/Export Data…* → **Import**
3. Filename: the matching CSV in `powerbi/exports/`
4. Format `csv`, Encoding `UTF8`
5. **Options tab:** Header **Yes**, Delimiter `,`, Quote `"`, **NULL string: leave empty**
6. Load `dim_*` tables before `fct_*` tables if you have already applied the foreign keys

Step 5 is the one that catches people — if NULL string is not empty you get error #6.

---

## Still stuck?

Run this and send the output — it identifies the failure precisely:

```bash
python postgres/load_to_postgres.py --dry-run
```

then

```sql
SELECT current_database(), current_user, version();
SELECT table_schema, table_name FROM information_schema.tables
WHERE table_schema IN ('marts','report') ORDER BY 1,2;
```
