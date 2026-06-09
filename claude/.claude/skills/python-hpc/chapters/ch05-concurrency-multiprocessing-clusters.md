# Chapter 5: Concurrency — async, multiprocessing & Clusters

## Core Idea
The right concurrency model depends on what blocks you. **I/O-bound** work (network, disk) wants `asyncio`/threads — many waits overlapped on one core. **CPU-bound** work wants **`multiprocessing`** — separate processes that each have their own GIL and run on separate cores. Scaling past one machine adds a job queue / cluster.

## Frameworks Introduced

- **The GIL decision tree** (the first question):
  - **CPU-bound** → the GIL blocks thread parallelism → use **`multiprocessing`** (or `nogil`/Numba from Ch 4).
  - **I/O-bound** → threads/async overlap waits cheaply → use **`asyncio`** (or threads).

- **`asyncio` / async-await** (cooperative concurrency for I/O):
  - `async def` coroutines `await` on I/O; a single **event loop** interleaves thousands of in-flight operations on one thread. Great for high-concurrency network/disk work. `asyncio.gather` runs coroutines concurrently. Cooperative — a blocking call stalls the whole loop, so use async libraries throughout.

- **`multiprocessing`** (true parallelism for CPU work):
  - **`Pool`** maps a function over inputs across worker processes (`pool.map`, `imap`, `imap_unordered`, `starmap`); each process has its own interpreter and GIL.
  - **`Queue`** / **`Pipe`** pass work and results between processes; **`Lock`**/`Semaphore` coordinate shared resources.
  - **Shared memory** (`multiprocessing.shared_memory`, shared `Array`) avoids pickling/copying large NumPy data between processes — pass a handle, not a copy.
  - **Joblib** wraps this with a simpler `Parallel(n_jobs=-1)(delayed(f)(x) for x in xs)` API and smart NumPy memmap handling.

- **Clusters & job queues** (scale past one node): distribute tasks across machines with a broker/queue. Key discipline: make tasks **idempotent** and **chunked**, handle worker failure, and avoid the coordinator becoming a bottleneck.

- **`mpi4py`** (true distributed-memory MPI from Python): the SPMD model — launch with `mpirun -np N python script.py`, each process is a **rank** in `MPI.COMM_WORLD`. The HPC-standard way to scale Python across cluster nodes (vs `multiprocessing`, which is single-node).
  - **The two-API rule (the central mpi4py idiom)**: methods come in two forms.
    - **lowercase** (`comm.send`, `comm.recv`, `comm.bcast`, `comm.gather`) — send **arbitrary Python objects**, serialized with **pickle**. Convenient but **slow** (pack/unpack overhead).
    - **Uppercase** (`comm.Send`, `comm.Recv`, `comm.Bcast`, `comm.Gather`) — send **NumPy buffers** directly (no pickle), near C-speed.
    - **Rule: uppercase NumPy methods in performance-critical paths, lowercase for convenience/setup.**
  - Same operations as C MPI: point-to-point (`Send`/`Recv`/`Isend`/`Irecv`), collectives (`Bcast`/`Scatter`/`Gather`/`Allreduce`), communicators. Object-oriented (methods on `Comm`, keyword/default arguments).

## Key Concepts
- **Process startup & pickling cost**: spawning processes and pickling args/results has overhead — **chunk** work so each task does enough to amortize it ("a less naive pool" batches inputs).
- **Sharing NumPy between processes**: pickling a large array per task is the classic multiprocessing performance trap; use shared memory or memmap so workers reference the same buffer.
- **Cooperative vs preemptive**: `asyncio` is cooperative (one blocking call freezes the loop); processes are preemptive (the OS schedules them).
- **Idempotency at scale**: distributed tasks can be retried after failure — they must produce the same result if run twice.

## Mental Models
- **First ask: CPU-bound or I/O-bound?** It picks the entire model — processes for CPU, async/threads for I/O. Getting this wrong (threads for CPU work) yields zero speedup because of the GIL.
- **Chunk multiprocessing work** — many tiny tasks drown in startup/pickling overhead; batch inputs so each worker call does real work.
- **Never pickle big arrays per task** — put them in shared memory and pass a handle; this is the single most common multiprocessing slowdown.
- **Use `asyncio` only with async-aware libraries** — one synchronous blocking call stalls every coroutine on the loop.
- **Reach for Joblib for embarrassingly parallel CPU loops** — it handles chunking, memmap, and backends so you don't hand-roll a Pool.

## Code Examples
```python
# CPU-bound: processes (each has its own GIL)
from multiprocessing import Pool
with Pool() as pool:
    results = pool.map(cpu_heavy, chunks, chunksize=64)   # chunk to amortize overhead

# Share a big NumPy array without copying per task
from multiprocessing import shared_memory
shm = shared_memory.SharedMemory(create=True, size=arr.nbytes)
view = np.ndarray(arr.shape, arr.dtype, buffer=shm.buf)   # workers attach by name

# I/O-bound: async overlaps thousands of waits on one thread
import asyncio
async def fetch_all(urls):
    return await asyncio.gather(*(fetch(u) for u in urls))

# Joblib: embarrassingly parallel in one line
from joblib import Parallel, delayed
out = Parallel(n_jobs=-1)(delayed(work)(x) for x in items)

# mpi4py: distributed across cluster nodes — run with `mpirun -np N python script.py`
from mpi4py import MPI
import numpy as np
comm = MPI.COMM_WORLD
rank, size = comm.Get_rank(), comm.Get_size()

# UPPERCASE: NumPy buffers, no pickle — use in performance-critical paths
buf = np.empty(n, dtype="float64")
if rank == 0: buf[:] = produce()
comm.Bcast(buf, root=0)                       # fast: direct buffer transfer

# lowercase: arbitrary Python objects via pickle — convenient, slower
config = comm.bcast(config if rank == 0 else None, root=0)

local = compute(buf)                          # each rank works on its share
total = comm.allreduce(local, op=MPI.SUM)     # collective reduction across ranks
```
- **What it demonstrates**: process pool with chunking, shared-memory array passing, async gather, Joblib, and mpi4py's uppercase (NumPy, fast) vs lowercase (pickle, convenient) APIs.

## Reference Tables

| Workload | Model | Why |
|---|---|---|
| CPU-bound | `multiprocessing` / Joblib | own GIL per process |
| I/O-bound, high concurrency | `asyncio` | overlap waits on one thread |
| I/O-bound, simple | threads | GIL released during I/O |
| beyond one machine | cluster / job queue | distribute + retry |
| HPC multi-node (SPMD) | `mpi4py` | true distributed MPI |

| mpi4py API | Sends | Speed |
|---|---|---|
| lowercase (`send`/`bcast`) | arbitrary objects (pickle) | slow — setup/convenience |
| **Uppercase** (`Send`/`Bcast`) | NumPy buffers (no pickle) | **fast — hot paths** |

| Multiprocessing trap | Fix |
|---|---|
| tiny tasks | `chunksize` / batch |
| pickling big arrays | shared memory / memmap |
| coordinator bottleneck | decentralize / chunk |

## Key Takeaways
1. CPU-bound → `multiprocessing` (own GIL per process); I/O-bound → `asyncio`/threads. This choice is the whole game.
2. Chunk multiprocessing work to amortize process-startup and pickling overhead.
3. Share large NumPy arrays via shared memory/memmap — never pickle them per task.
4. `asyncio` is cooperative — one blocking call stalls the loop; use async libraries throughout.
5. Joblib simplifies embarrassingly parallel CPU loops; at cluster scale make tasks idempotent and chunked.
6. `mpi4py` brings true distributed-memory MPI to Python (SPMD, ranks over `COMM_WORLD`) for multi-node HPC — use **uppercase** NumPy-buffer methods (`Bcast`/`Send`) in hot paths, lowercase pickle-based methods (`bcast`/`send`) only for convenience/setup.

## Connects To
- **Ch 04 (GIL)**: why threads don't parallelize CPU-bound Python; `nogil`/Numba alternatives.
- **Ch 06 (Dask)**: Dask scales DataFrame/array work across cores and clusters.
- **Ch 09 (Multi-GPU)**: Dask-CUDA distributes GPU work the same way.
- **mpi-5.0 skill**: the authoritative MPI reference (semantics, all routines) behind mpi4py.
- **hpc-cluster-tooling skill**: running mpi4py jobs via SLURM (`srun`/`mpirun`) on a cluster.
