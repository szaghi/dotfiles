# Chapter 1: Introduction to MPI

## Core Idea
MPI is a **message-passing library interface specification** (not a language, not an implementation) for the distributed-memory parallel model: data moves between process address spaces via **cooperative** operations. Its reason to exist is **portability + performance** across vendors.

## Frameworks Introduced
- **The message-passing model**: each process has a private address space; communication is explicit, cooperative (a send pairs with a receive). Extensions beyond classical message-passing: **collectives**, **remote-memory access (RMA / one-sided)**, **dynamic process creation**, **parallel I/O**.
- **Specification vs implementation**: MPI is a *standard*; Open MPI, MPICH, MVAPICH, Intel MPI, Cray MPICH are implementations. Code to the standard, tune per implementation.
- **Design goals**: portable, efficient (avoid memory copies, allow compute/communication overlap, offload to hardware), flexible; a thread-safe, language-bound (C + Fortran) library API.

## Key Concepts
- **MPI process**: the unit of execution with its own address space (historically "rank in MPI_COMM_WORLD"; MPI 5.0 generalizes via **Sessions**, ch11).
- **rank**: an integer ID of a process within a communicator's group (0-based).
- **communicator**: the scope (group + context) within which communication happens (ch7).
- **SPMD**: the dominant usage — one program, many processes, branching on `rank`.
- **scalability**: the design favors operations vendors can hardware-accelerate (RDMA, collective offload).

## Mental Models
- **"Cooperative" is the defining property**: unlike shared memory, classical MPI communication requires *both* sides to act (send ↔ recv). The exceptions — RMA (ch12) and I/O (ch14) — are exactly the "one-sided" extensions.
- **Portability is the contract; performance is the implementation's job**: write standard MPI, then tune the implementation's runtime/transport (UCX, libfabric, etc.) — don't hardcode implementation behavior.

## Key Takeaways
1. MPI = a *specification* for cooperative message passing in distributed memory; many implementations exist.
2. Beyond send/recv: collectives, one-sided RMA, dynamic processes, parallel I/O.
3. The unit is the **MPI process** (with `rank` within a **communicator**); SPMD is the norm.
4. Design priorities: portability, overlap of communication and computation, hardware offload.
5. Code to the standard; tune per implementation — never rely on implementation-specific behavior for correctness.

## Connects To
- **Ch 2**: the precise semantic terms (blocking/nonblocking, local/nonlocal, collective).
- **Ch 3**: point-to-point send/recv — the core cooperative primitive.
- **Ch 7**: communicators — the scope of communication.
- **Ch 11**: Sessions — MPI 5.0's generalized initialization beyond MPI_COMM_WORLD.
- **CLAUDE-gpu.md**: MPI is the inter-node layer of the HPC stack (MPI + OpenMP/OpenACC + GPU).
