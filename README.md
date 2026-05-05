# todo-db

> **Task management database infrastructure** — the isolated PostgreSQL data vault for the **simply todo** system.

---

## Overview

`todo-db` is the foundational data repository for the **simply todo** project. This repo is solely responsible for provisioning, configuring, and initializing the PostgreSQL database that stores all task data. 

This repo is intentionally scoped to infrastructure only. It has no knowledge of the API endpoints, routing logic, or the frontend user interface. Those concerns live in separate repositories. The boundary is clean by design: **todo-db persists the data, everything else builds on top of it.**

---

## The Open Infrastructure Strategy

`todo-db` is designed as part of the **simply todo** open core foundation. Licensed under Apache 2.0, the database schema and container orchestration are publishable and community-buildable. This ensures that the core data layer remains transparent and portable, while the proprietary business logic and unique product identity live in the upper tiers of the Arcus-inspired architecture.

---

## Where This Fits



```text
simply todo Architecture
│
├── todo-frontend        ← future
│   └── The user interface (port 3000)
│
├── todo-router          ← future
│   └── The API Gateway (port 8000)
│
├── todo-backend         ← future
│   └── Task logic worker (port 8001)
│
└── todo-db              ← YOU ARE HERE
    └── PostgreSQL database vault (port 5432)
        Isolated network, talks only to todo-backend
```

**Port topology:**
```text
User → todo-frontend (:3000) → todo-router (:8000) → todo-backend (:8001) → todo-db (:5432)
```

`todo-db` is completely shielded from public internet traffic. Only the backend worker has the internal credentials and network access required to communicate with it.

---

## Architecture

```text
┌─────────────────────────────────────────────────┐
│              Docker Container                   │
│                                                 │
│  ┌───────────────────────────────────────────┐  │
│  │           todo-db  (port 5432)            │  │
│  │           PostgreSQL 15 Alpine            │  │
│  │                                           │  │
│  │  Boot: Executes /docker-entrypoint.d/     │  │
│  │        Runs init.sql to build schema      │  │
│  │                                           │  │
│  │  Auth: POSTGRES_USER & POSTGRES_PASSWORD  │  │
│  └─────────────────┬─────────────────────────┘  │
└────────────────────┼────────────────────────────┘
                     │ Persistent Mount
                     ▼
        ┌────────────────────────────────────┐
        │        Docker Volume               │
        │        simply-todo-pgdata          │
        └────────────────────────────────────┘
```

### Initialization flow

1. **Docker Compose** pulls the official `postgres:15-alpine` image.
2. The persistent volume `simply-todo-pgdata` is mounted to ensure data survives container restarts.
3. On the **first** boot, PostgreSQL executes `init.sql`, automatically enabling the `pgcrypto` extension and creating the `tasks` table with UUID defaults.
4. An automated trigger is established to manage `updated_at` timestamps natively within the database.
5. The database begins listening on internal port `5432` for connections from the `todo-backend`.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Base image | `postgres:15-alpine` |
| Database Engine | PostgreSQL 15 |
| Extensions | `pgcrypto` (Native UUID generation) |
| Automation | PL/pgSQL Triggers |
| Data Persistence | Docker Volumes |
| Containerization | Docker + Docker Compose |

---

## Prerequisites

- **Docker Desktop** installed
- **DBeaver** or **TablePlus** (optional, for local data inspection)

---

## Project Structure

```text
todo-db/
├── docker/
│   └── Dockerfile              # Custom postgres:15-alpine image
├── db/
│   └── init.sql                # Schema, UUID extensions, and triggers
├── docs/
│   └── DATASHEET.md            # Data dictionary and schema contract
├── docker-compose.yml          # Local orchestration and volumes
├── .env                        # Local secrets — never commit this
├── .env.example                # Template for .env
├── .dockerignore
├── .gitignore
├── LICENSE                     # Apache 2.0
└── README.md
```

---

## Setup

### 1. Clone the repo

```bash
git clone <repo-url>
cd todo-db
```

### 2. Create your `.env` file

```bash
cp .env.example .env
```

Edit `.env` and fill in your local development credentials:

```env
POSTGRES_USER=admin
POSTGRES_PASSWORD=your_secure_password_here
POSTGRES_DB=tododb
```

### 3. Build and Start the Vault

```bash
docker-compose up -d --build
```

The database is ready when you see the following in the Docker logs:

```text
==> [simply todo] init.sql successfully injected...
database system is ready to accept connections
```

### 4. Verification

To verify the schema was created correctly, you can run:

```bash
docker exec -it postgres-db psql -U admin -d tododb -c "\dt"
```

---

## Design Decisions

### Why PostgreSQL 15 Alpine?
PostgreSQL 15 provides native `gen_random_uuid()` support and excellent performance. The Alpine base ensures the image remains under 200MB, minimizing the attack surface and deployment time.

### Why Database-Level Triggers?
By using a PL/pgSQL trigger for `updated_at` timestamps, we ensure data integrity. Regardless of whether a task is updated via the CLI, a future Discord bot, or a manual SQL query, the database remains the source of truth for modification timing.

### Why persistent volumes?
By mapping data to `simply-todo-pgdata`, we decouple the data from the container lifecycle. You can destroy, update, or rebuild the `todo-db` container without losing your task history.

---

## Configuration

| Variable | Default | Description |
|---|---|---|
| `POSTGRES_USER` | — | Master username for the database |
| `POSTGRES_PASSWORD` | — | Secure password for the master user |
| `POSTGRES_DB` | `tododb` | The name of the primary application database |

---

## License

Licensed under the Apache License, Version 2.0 (the "License").
You may not use this file except in compliance with the License.
You may obtain a copy of the License at

    [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

*Copyright © 2026 simply todo. All rights reserved.*

---

## Maintainer

**Founder & Lead Developer**
