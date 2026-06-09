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
```
- **What it demonstrates**: process pool with chunking, shared-memory array passing, async gather, and Joblib.

## Reference Tables

| Workload | Model | Why |
|---|---|---|
| CPU-bound | `multiprocessing` / Joblib | own GIL per process |
| I/O-bound, high concurrency | `asyncio` | overlap waits on one thread |
| I/O-bound, simple | threads | GIL released during I/O |
| beyond one machine | cluster / job queue | distribute + retry |

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

## Connects To
- **Ch 04 (GIL)**: why threads don't parallelize CPU-bound Python; `nogil`/Numba alternatives.
- **Ch 06 (Dask)**: Dask scales DataFrame/array work across cores and clusters.
- **Ch 09 (Multi-GPU)**: Dask-CUDA distributes GPU work the same way.
