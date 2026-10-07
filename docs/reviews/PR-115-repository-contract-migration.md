# Character repository contract migration

PR 115 replaces the internal completion-based `Character` repository API with an async/throwing `CharacterDocument` API. This is a breaking source contract for repository implementations, mocks, use cases, and callers; it is not limited to adding currency types.

Callers now await `fetchAll()`, `fetch(withID:)`, and `save(_:)`. The contract also supports `fetchCollection()`, `duplicate(_:)`, and `delete(withID:)`. `fetchCollection()` returns readable documents and metadata for unreadable records together. `fetchAll()` remains strict: it throws if the collection contains an unreadable record. The default collection implementation lets a repository that only implements strict fetching return a readable-only collection; the SwiftData implementation provides unreadable metadata.

Repository implementations must adopt the async methods and `CharacterDocument` values. UI callers remain on the main actor and await the repository; the protocol does not require main-actor isolation. Local SwiftData operations run on a serial model actor whose context is created on a dedicated background queue. Raw SwiftData models and contexts do not cross that boundary.

The local `CharacterRecord` model persists encoded documents. Existing supported documents keep their IDs, equipment selections, and schema; moving the repository to a background context does not change their payload shape or require a new document schema. Decoding retains support for ISO-8601 and legacy numeric dates. Unsupported schemas/rulesets, invalid currency signs, and overflowing currency totals are surfaced as unreadable records; their payloads remain stored until explicit deletion. Validation does not silently normalize persisted denomination counts.

There is no compatibility adapter for the earlier completion API and no automatic importer for historical `Character`/Firebase payloads with a different structure. A consumer of that earlier API must migrate its calls, mocks, and document mapping explicitly. This repository remains offline-first; no network contract, remote data migration, backend implementation, or provider credentials are introduced.

The bundled equipment catalogs use schema version 2 for explicit exclusive alternatives and required bundles. That catalog representation change is separate from the persisted character-document schema.
