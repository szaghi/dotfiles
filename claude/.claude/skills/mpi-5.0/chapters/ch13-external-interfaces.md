# Chapter 13: External Interfaces

## Core Idea
Hooks for **extending MPI and integrating it with other software**: generalized (user-defined nonblocking) requests, decoding derived datatypes, the detailed threads/progress contract, and associating MPI with external state. The chapter library and tool authors rely on.

## Frameworks Introduced
- **Generalized requests**: `MPI_Grequest_start`/`MPI_Grequest_complete` — create an MPI **request** backed by a *user-defined* nonblocking operation (with query/free/cancel callbacks), so non-MPI async work (e.g. a custom I/O or accelerator transfer) can be waited on with `MPI_Wait`/`MPI_Test` alongside MPI requests.
- **Datatype decoding**: `MPI_Type_get_envelope` + `MPI_Type_get_contents` — reflectively inspect how a derived datatype was constructed (for tools, libraries, serialization layers).
- **Threads + MPI contract** (detail beyond ch2): the progress rule (MPI must make progress on outstanding operations), matching/ordering guarantees under `MPI_THREAD_MULTIPLE`, and which calls are thread-safe.
- **Associating state**: attaching/retrieving information for interoperability with external runtimes.

## Key Concepts
- **Generalized requests unify async waiting**: if your code mixes MPI nonblocking ops with other async work, wrap the latter as a generalized request so a single `MPI_Waitall` covers both — cleaner than polling two systems.
- **`MPI_THREAD_MULTIPLE` semantics**: concurrent MPI calls from multiple threads are allowed but you still must not have two threads complete the *same* request, and collective ordering is per-communicator — the implementation serializes internally, which has a cost.
- **Datatype reflection** is mostly for tooling/libraries (e.g. a checkpoint library that must understand user types) — rarely needed in application code.
- **Progress**: an implementation must eventually complete posted operations even without explicit MPI calls, but in practice progress often happens *inside* MPI calls — long compute gaps can stall communication on some implementations (a reason to call `MPI_Test` periodically).

## Anti-patterns
- **Polling external async state separately from MPI**: wrap it as a generalized request and `MPI_Wait` uniformly.
- **Two threads completing the same request under `MPI_THREAD_MULTIPLE`**: erroneous — partition requests across threads.
- **Assuming background progress on every implementation**: some make progress only inside MPI calls; sprinkle `MPI_Test` during long compute if communication seems stalled.
- **Hand-parsing derived types**: use `MPI_Type_get_envelope`/`_contents` reflection.

## Key Takeaways
1. **Generalized requests** let user-defined async ops be completed via `MPI_Wait`/`MPI_Test` — unify MPI + non-MPI async.
2. `MPI_Type_get_envelope`/`_contents` reflectively decode derived datatypes (tooling/serialization).
3. Under `MPI_THREAD_MULTIPLE`, concurrent calls are allowed but not on the same request; internal serialization costs.
4. Progress is guaranteed eventually but often happens inside MPI calls — `MPI_Test` during long compute gaps if needed.
5. This chapter is mostly for library/tool authors, not everyday application code.

## Connects To
- **Ch 2**: the threads model and request semantics this elaborates.
- **Ch 3/6**: nonblocking requests that generalized requests join.
- **Ch 5**: derived-datatype construction that decoding reverses.
- **Ch 15**: tool support builds on these external-interface hooks.
