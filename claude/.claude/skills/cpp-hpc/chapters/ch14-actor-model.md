# Chapter 14: The Actor Model of Concurrent Computing

## Core Idea
The actor model is a different lens on parallelism: instead of threads sharing memory (and racing), the program is composed of **actors** — independent units that hold private state and communicate *only* by asynchronous **messages**. No shared mutable state means no data races by construction, and the model naturally supports distribution and fault tolerance.

## Frameworks Introduced

- **The actor** (the universal primitive of concurrency): an actor has private state, a **mailbox** (message queue), and behavior. On receiving a message it can: update its state, send messages to other actors, and spawn new actors. Actors process messages **one at a time**, so an actor's internal state is never concurrently accessed — serialization without locks.

- **Asynchronous message passing**: actors communicate by sending immutable messages to each other's mailboxes (`send`/`spawn`). Sending is non-blocking; the sender doesn't wait. There is **no shared state** — the only way actors interact is messages.

- **Task-based concurrency**: the actor model is a task-based approach — decompose the program into many small actors, expose maximal concurrency, and let the runtime schedule them across cores/nodes. C++ implementations include the **C++ Actor Framework (CAF)**.

- **Fault tolerance & supervision**: because actors are isolated, a failing actor can be restarted by a **supervisor** without corrupting others (the "let it crash" philosophy). This isolation is what makes the model scale to distributed, long-running systems.

## Key Concepts
- **No shared mutable state ⇒ no data races**: the model eliminates the entire class of locking/race bugs by construction — the contrast with the shared-memory threading of earlier chapters.
- **Location transparency**: an actor address works whether the target is on the same core or a remote node — the same message-passing code distributes across a cluster (conceptually like MPI, but dynamic and task-oriented).
- **One-message-at-a-time**: an actor's behavior is effectively single-threaded over its own state, so you reason about it sequentially even in a massively concurrent system.
- **Mailbox backpressure**: unbounded mailboxes can grow without limit under load; production systems bound them and handle overflow.

## Mental Models
- **Model the problem as isolated actors exchanging messages, not threads sharing data** — this trades lock-based correctness reasoning for message-protocol reasoning, and removes data races entirely.
- **"Let it crash" with supervision** — isolated actors mean a failure is contained and recoverable by restart, rather than corrupting global state.
- **Use it for irregular, dynamic, distributed task parallelism** — the actor model shines where work is unpredictable and the topology changes (vs the static, regular decomposition that suits MPI/OpenMP).
- **Reason about each actor sequentially** — one-message-at-a-time processing means an actor's state logic is single-threaded, even amid system-wide concurrency.

## Reference Tables

| Concept | Meaning |
|---|---|
| actor | private-state unit; processes messages serially |
| mailbox | per-actor message queue |
| send / spawn | async message / create a new actor |
| supervisor | restarts failed actors (fault tolerance) |
| location transparency | same code for local or remote actors |

| vs shared-memory threads | Actor model |
|---|---|
| shared mutable state + locks | private state + messages |
| data races possible | no data races by construction |
| static thread pool | dynamic actor spawning |
| crash corrupts shared state | isolated failure + supervision |

## Key Takeaways
1. Actors hold private state and communicate only by asynchronous messages — no shared mutable state, so no data races by construction.
2. Each actor processes messages one at a time, so its state logic is effectively sequential even amid massive concurrency.
3. The model is task-based and dynamic — well suited to irregular, evolving, distributed workloads (CAF is a C++ implementation).
4. Isolation enables fault tolerance: supervisors restart failed actors without corrupting others ("let it crash").
5. Location transparency lets the same message-passing code run on one node or distribute across a cluster.

## Connects To
- **Ch 04 (Parallel patterns)**: the shared-memory threading model the actor model contrasts with (no locks/races).
- **Ch 06 (MPI)**: another message-passing model, but static/SPMD vs the actor model's dynamic task-based concurrency.
- **Ch 02 (Modern C++)**: actor frameworks (CAF) are built on modern C++ idioms.
