# 0004 — The Index is a SQLite database, used through GRDB

Date: 27/10/2026. Status: accepted (chosen by the user).

## Context

Milestone 3 needs full-text Search, Tags and a fast reopen of a 10,000-Note Vault. `ARCHITECTURE.md` left the Index store open: SQLite with FTS5, or SwiftData. The options put to the user were SQLite with FTS5 through a small Opal wrapper, SQLite through GRDB, or an Index held only in memory.

## Decision

The Index is one SQLite database per Vault, read and written through GRDB 7 (Swift package, `from: "7.10.0"`). Full-text search uses SQLite's FTS5, which the system SQLite on macOS includes. The database lives in `~/Library/Application Support/Opal/Indexes/<vault-id>/` inside the app container. Tests and acceptance runs pass `-OpalIndexFolder` so they never touch it.

## Consequences

- GRDB is Opal's first third-party dependency. It is used only in Data (`GRDBIndexStore`) behind the `IndexStoring` protocol, so Services and Presentation never import it.
- The Index is derived: it stores a schema version, and any mismatch, corruption or missing file means delete and rebuild. Nothing is stored only in the Index.
- SwiftData was not chosen: it has no full-text search, and its store is harder to delete and rebuild safely.
