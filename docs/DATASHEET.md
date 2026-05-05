# todo-db — Datasheet

> Reference document for the **simply todo** data layer.
> Intended audience: **todo-backend** and any service requiring direct database access.

---

## Quick Reference

| Item | Value |
|---|---|
| Database Engine | PostgreSQL 15 (Alpine) |
| Host (Internal) | `postgres-db` |
| Port | `5432` |
| Primary Database | `tododb` (Default) |
| Schema Type | Relational / Normalized |
| Auth Mechanism | Username/Password via Environment Variables |
| Extension Required | `pgcrypto` (for UUID generation) |

---

## Connection Strategy

The `todo-backend` service (and future workers) should connect using a standard PostgreSQL connection string. 

**Internal Network URI:**
```text
postgresql://[USER]:[PASSWORD]@postgres-db:5432/tododb
```

**Security Note:** Access is restricted to the internal Docker network `simply-todo-network`. The database does not accept external traffic unless explicitly tunneled or mapped via host ports for debugging.

---

## Data Dictionary

### Table: `tasks`

The core table for the **simply todo** application. Stores all user-generated tasks and their current lifecycle status.

| Column | Data Type | Constraints | Description |
|---|---|---|---|
| `id` | `UUID` | `PRIMARY KEY` | Unique identifier generated via `gen_random_uuid()`. |
| `title` | `VARCHAR(255)` | `NOT NULL` | The main text/heading of the task. |
| `description` | `TEXT` | `NULLABLE` | Long-form notes or details regarding the task. |
| `is_completed` | `BOOLEAN` | `DEFAULT FALSE` | Toggle state of the task completion. |
| `created_at` | `TIMESTAMPTZ` | `DEFAULT NOW()` | Immutable timestamp of task creation. |
| `updated_at` | `TIMESTAMPTZ` | `TRIGGERED` | Timestamp of last modification (handled by DB trigger). |

#### Indexing & Performance
* **Primary Key:** The `id` column is automatically indexed for $O(1)$ lookups.
* **Scaling Note:** If the task list grows beyond $10^5$ rows, an index on `is_completed` or `created_at` may be required for filtered views.

---

## Triggers & Automation

### `update_tasks_modtime`
To ensure data integrity and reduce backend logic overhead, the database handles its own `updated_at` timestamps.

* **Action:** `BEFORE UPDATE`
* **Logic:** Executes `update_modified_column()` function.
* **Effect:** Any `UPDATE` statement targeting a row in the `tasks` table will force the `updated_at` column to the current system time, regardless of what is sent in the SQL payload.

---

## Expected JSON Mapping (Contract)

When the **todo-backend** retrieves a row, the mapping to a JSON object (for the Frontend/Router) should strictly follow this structure:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "title": "Finish simply todo infrastructure",
  "description": "Complete the todo-db repository with all docs.",
  "is_completed": false,
  "created_at": "2026-05-05T12:00:00Z",
  "updated_at": "2026-05-05T12:00:00Z"
}
```

---

## Backup & Persistence

### Local Development
Data is persisted in a named Docker volume: `simply-todo-pgdata`.
To wipe the database completely and restart from the `init.sql` schema:
```bash
docker-compose down -v
```

### Production (Render)
When migrating to Render, the schema defined in `db/init.sql` must be applied to the managed PostgreSQL instance. Render handles the automated backups and encryption at rest.

---

## Known Behaviors

| Behavior | Cause | Integration Note |
|---|---|---|
| `updated_at` changes automatically | Postgres Trigger | Backend should mark this field as "read-only" in Pydantic models. |
| `id` is a UUID string | `pgcrypto` Extension | Backend must handle UUID types, not Integers. |
| Timezone consistency | `TIMESTAMPTZ` type | All timestamps are stored in UTC. Frontend must handle local offset. |
| Connection Refused on boot | Race condition | Backend must implement a "wait-for-it" or healthcheck check. |

---

## Technical Specifications

### PostgreSQL Configuration

| Property | Value |
|---|---|
| Image | `postgres:15-alpine` |
| Default Encoding | `UTF8` |
| Collation | `en_US.utf8` |
| Max Connections | `100` (Default Alpine) |

---

*todo-db — simply todo — Apache 2.0*
