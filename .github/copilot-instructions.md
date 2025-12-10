<!-- .github/copilot-instructions.md for SQL_Project_Data_Job_Analysis -->
# Quick agent guide — SQL_Project_Data_Job_Analysis

This file captures the concrete, discoverable patterns and developer workflows for this repository so coding agents can be productive immediately.

**Repository shape**
- SQL schema and load scripts: `sql_load/1_create_database.sql`, `sql_load/2_create_tables.sql`, `sql_load/3_modify_tables.sql`
- Example queries / analysis: `sql_course.session.sql`
- Source CSV data: `csv_files/` (contains `company_dim.csv`, `skills_dim.csv`, `job_postings_fact.csv`, `skills_job_dim.csv`)
- Test copy of load scripts: `test.sql/sql_load/*` (mirror of `sql_load/`) — prefer `sql_load/` for primary work.

**Big picture / data flow**
- CSV files in `csv_files/` are the source of truth. They are imported into PostgreSQL tables using psql's `\copy` (or pgAdmin PSQL tool).
- Tables and relationships (see `sql_load/2_create_tables.sql`):
  - `company_dim` — `company_id INT PRIMARY KEY`
  - `skills_dim` — `skill_id INT PRIMARY KEY`
  - `job_postings_fact` — `job_id INT PRIMARY KEY`, `company_id INT` FK -> `company_dim(company_id)`; many descriptive columns like `job_title`, `job_posted_date`, `salary_year_avg` (NUMERIC), boolean flags (e.g. `job_work_from_home`).
  - `skills_job_dim` — composite PK `(job_id, skill_id)`, FKs to `job_postings_fact(job_id)` and `skills_dim(skill_id)`.
- Indexes created in `2_create_tables.sql`: `idx_company_id` on `job_postings_fact(company_id)`, and `idx_skill_id`, `idx_job_id` on `skills_job_dim` for performance.

**Why files are organized this way**
- `1_create_database.sql` creates the `sql_course` database.
- `2_create_tables.sql` defines schema, PKs, FKs, and indexes — apply after creating the database.
- `3_modify_tables.sql` contains CSV load commands and helpful troubleshooting notes (permission issues, encoding). It is expected to be run from psql/pgAdmin because it uses `\COPY` meta-commands.

**Concrete developer workflows (exact commands & order)**
- Typical local setup (Windows):
  1. Create DB:
     - `psql -U postgres -f sql_load/1_create_database.sql`
  2. Create tables (target DB):
     - `psql -U postgres -d sql_course -f sql_load/2_create_tables.sql`
  3. Load CSVs: use the psql interactive prompt or pgAdmin's PSQL tool and run the `\COPY` statements in `sql_load/3_modify_tables.sql`.

  Note: `\COPY` is a psql meta-command and must run inside psql (interactive) or be supplied with `-c` quoting. On Windows PowerShell the quoting can be awkward — using pgAdmin's PSQL tool is the simpler path recommended by the repository's comments.

Example `\copy` (from the repo):
```
\COPY company_dim FROM 'C:\Users\Adeol\Downloads\SQL_Project_Data_Job_Analysis\csv_files\company_dim.csv' DELIMITER ',' CSV HEADER;
\COPY skills_dim FROM 'C:\Users\Adeol\Downloads\SQL_Project_Data_Job_Analysis\csv_files\skills_dim.csv' DELIMITER ',' CSV HEADER;
\COPY job_postings_fact FROM 'C:\Users\Adeol\Downloads\SQL_Project_Data_Job_Analysis\csv_files\job_postings_fact.csv' DELIMITER ',' CSV HEADER;
\COPY skills_job_dim FROM 'C:\Users\Adeol\Downloads\SQL_Project_Data_Job_Analysis\csv_files\skills_job_dim.csv' DELIMITER ',' CSV HEADER;
```

**Project-specific conventions and patterns**
- Schema uses the `public` schema explicitly in `2_create_tables.sql` (e.g. `public.company_dim`). Keep new objects consistent with the `public` schema unless there's a strong reason not to.
- Column naming is snake_case and often prefixed (e.g. `job_` for job-related columns). Follow the same naming when adding fields.
- PKs are `INT`; do not change ID types casually — ingestion and relationships assume `INT` keys.
- `skills_job_dim` uses a composite primary key `(job_id, skill_id)` — treat this as the canonical mapping table for many-to-many relationships between jobs and skills.
- The repo explicitly sets `OWNER to postgres` in `2_create_tables.sql` — be cautious changing ownership in shared environments.

**Troubleshooting notes already in repo (follow these when relevant)**
- If `Permission denied` on `\COPY`, use pgAdmin's PSQL tool (instructions are in `3_modify_tables.sql`) or ensure the psql process has filesystem access to the CSV path.
- If you see `duplicate key value violates unique constraint` for primary keys, drop the `sql_course` DB and re-run the scripts in order (the repo documents that exact flow).

**Where to look for examples**
- Bulk load and troubleshooting: `sql_load/3_modify_tables.sql` (contains executable `\COPY` commands and step-by-step troubleshooting)
- Schema and constraints: `sql_load/2_create_tables.sql`
- Sample queries and analysis patterns: `sql_course.session.sql` (examples of CTEs, timezone handling, salary bucketing, aggregation patterns)

**What the agent should do and avoid**
- Do: follow the ordered workflow (create DB → create tables → load CSVs). Use the `csv_files/` relative paths when referencing data.
- Do: keep naming and types consistent with existing schema (snake_case, `INT` PKs, booleans named with `job_` prefix where appropriate).
- Avoid: changing PK column types or renaming mapping-table keys (`skills_job_dim`) without updating all load scripts and downstream queries.

If any part of these instructions seems incomplete or you'd like the agent to add automation (for example, a PowerShell script to run the full setup), say which part to automate and I'll add it.
