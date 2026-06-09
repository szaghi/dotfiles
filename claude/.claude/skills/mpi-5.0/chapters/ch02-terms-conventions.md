# Chapter 2: MPI Terms and Conventions

## Core Idea
The precise vocabulary that every later chapter relies on: the **operation taxonomy** (blocking/nonblocking/persistent × collective/noncollective × local/nonlocal), opaque objects and handles, argument conventions (IN/OUT/INOUT), error handling, and the threading model. Master this before reading any API chapter.

## Frameworks Introduced
- **Operation stages**: an MPI operation has up to four stages — **initialization**, **starting**, **completion**, **freeing**.
  - **Blocking**: all four combined in one call (e.g. `MPI_Send`, `MPI_Recv`).
  - **Nonblocking**: init+start in one call (returns a **request**), completion+freeing in a separate call (`MPI_Wait`/`MPI_Test`) — e.g. `MPI_Isend`/`MPI_Irecv`.
  - **Persistent**: init separated from repeated start (`MPI_Send_init` → `MPI_Start` … `MPI_Request_free`) — amortize setup for a repeated pattern.
- **local vs nonlocal**: a **local** procedure completes without communication with another process; a **nonlocal** one may require another process to make a matching call to complete (e.g. `MPI_Send` is nonlocal — it may wait for a receiver; `MPI_Isend` initiation is local).
- **collective vs noncollective**: a **collective** operation is one call per process across a group/groups, all of which must participate (e.g. `MPI_Bcast`). Available as blocking/nonblocking/persistent. **Noncollective** = everything else.
- **Opaque objects + handles**: MPI objects (communicators, datatypes, requests, groups, windows, files, info) are *opaque*; you hold a **handle** (`MPI_Comm`, `MPI_Datatype`, …). A handle argument is INOUT/OUT when the *referenced object* changes, even though the handle value may not.

## Key Concepts
- **Completion semantics**: completing a send means the *send buffer is reusable*; completing a receive means the *data has arrived*. It does **not** imply the matching operation has completed (unless synchronous mode).
- **Error handling**: by default `MPI_ERRORS_ARE_FATAL` (abort on error); attach `MPI_ERRORS_RETURN` or `MPI_ERRORS_ABORT` to a communicator/window/file to get return codes. Procedures return `MPI_SUCCESS` or an error class.
- **Thread levels** (`MPI_Init_thread`): `MPI_THREAD_SINGLE`, `_FUNNELED` (only the main thread calls MPI), `_SERIALIZED` (one thread at a time), `_MULTIPLE` (any thread, concurrently). Request the minimum you need.
- **Predefined handles/constants**: `MPI_COMM_WORLD`, `MPI_COMM_SELF`, `MPI_COMM_NULL`, `MPI_DATATYPE_NULL`, `MPI_PROC_NULL`, `MPI_ANY_SOURCE`, `MPI_ANY_TAG`, `MPI_STATUS_IGNORE`.
- **Opaque object lifetime**: you must free what you create (`MPI_Comm_free`, `MPI_Type_free`, `MPI_Request_free`) — leaks are real.

## Reference Tables
### Operation taxonomy
| Axis | Values |
|---|---|
| timing | blocking / nonblocking / persistent |
| participation | collective / noncollective |
| locality | local / nonlocal |

### Thread support levels
| Level | Rule |
|---|---|
| `MPI_THREAD_SINGLE` | one thread total |
| `MPI_THREAD_FUNNELED` | only the thread that called Init_thread does MPI |
| `MPI_THREAD_SERIALIZED` | multiple threads, but not concurrently in MPI |
| `MPI_THREAD_MULTIPLE` | any thread, concurrent MPI calls |

## Anti-patterns
- **Reusing a send buffer before completion**: a nonblocking `MPI_Isend` buffer must not be touched until `MPI_Wait`/`MPI_Test` reports completion — classic data-corruption bug.
- **Assuming send completion = receive completion**: only synchronous (`MPI_Ssend`) guarantees the receiver started; standard mode does not.
- **Requesting `MPI_THREAD_MULTIPLE` by default**: it has overhead and not all implementations support it well — request the minimum (often `FUNNELED` for MPI+OpenMP with MPI only on the master thread).
- **Ignoring the default fatal error handler**: set `MPI_ERRORS_RETURN` if you want to handle errors rather than abort.
- **Leaking opaque objects**: free communicators/datatypes/requests you create.

## Key Takeaways
1. Operation taxonomy: blocking/nonblocking/persistent × collective/noncollective × local/nonlocal — every API is classified by these.
2. Completion = *buffer reusable* (send) / *data arrived* (recv), **not** that the peer's matching op finished.
3. Thread levels: request the minimum (`FUNNELED` is the common MPI+OpenMP choice; `MULTIPLE` only if threads call MPI concurrently).
4. Default error handler is fatal-abort; set `MPI_ERRORS_RETURN` to handle codes.
5. MPI objects are opaque handles you must explicitly free.

## Connects To
- **Ch 3**: send/recv modes operationalize blocking/nonblocking/local/nonlocal.
- **Ch 6**: collective operations.
- **Ch 9**: environmental management — error handlers, MPI_Wtime.
- **Ch 13**: external interfaces — generalized requests, thread support detail.
