# Chapter 8: Portable Accelerator Programming with OpenCL

## Core Idea
OpenCL is the vendor-neutral counterpart to CUDA: the same data-parallel execution model (an **NDRange** of **work-items** in **work-groups**) expressed through a portable runtime API that targets GPUs, CPUs, FPGAs, and DSPs from one codebase. Portability comes from **querying** the platform at runtime and **compiling kernels at runtime** for whatever device is present — the cost is substantial host-side boilerplate.

## Frameworks Introduced

### The four OpenCL models
1. **Platform model** — a host plus one or more **compute devices**, each with **compute units** subdivided into **processing elements**. A vendor's runtime is a *platform*; query devices within it.
2. **Execution model** — kernels run over an **NDRange** index space of **work-items**, grouped into **work-groups**. Maps directly onto CUDA (below).
3. **Memory model** — global / constant / local / private spaces (below).
4. **Programming model** — data-parallel (the common case) and task-parallel.

### The CUDA ↔ OpenCL mapping (it is mechanical)
| Concept | CUDA | OpenCL |
|---|---|---|
| parallel unit | thread | work-item |
| group | block | work-group |
| index space | grid | NDRange |
| per-item index | `threadIdx` | `get_local_id(dim)` |
| global index | `blockIdx*blockDim+threadIdx` | `get_global_id(dim)` |
| fast scratchpad | `__shared__` | `__local` |
| registers | (automatic) | `__private` |
| read-only cached | `__constant__` | `__constant` |
| group barrier | `__syncthreads()` | `barrier(CLK_LOCAL_MEM_FENCE)` |
| stream | stream | command queue / events |

The **optimizations are identical** — coalescing global access, `__local`-memory tiling, occupancy, minimizing host↔device transfer. Only the API and the runtime-compile step differ.

### The host program skeleton (the boilerplate, in order)
```c
// 1. Discover platform and device
cl_platform_id plat; clGetPlatformIDs(1, &plat, NULL);
cl_device_id   dev;  clGetDeviceIDs(plat, CL_DEVICE_TYPE_GPU, 1, &dev, NULL);

// 2. Context + command queue
cl_context ctx = clCreateContext(NULL, 1, &dev, NULL, NULL, &err);
cl_command_queue q = clCreateCommandQueueWithProperties(ctx, dev, NULL, &err);

// 3. Build the program FROM SOURCE at runtime
const char* src = "...kernel source...";
cl_program prog = clCreateProgramWithSource(ctx, 1, &src, NULL, &err);
clBuildProgram(prog, 1, &dev, "-cl-fast-relaxed-math", NULL, NULL);   // JIT compile
cl_kernel k = clCreateKernel(prog, "saxpy", &err);

// 4. Device buffers + upload
cl_mem dX = clCreateBuffer(ctx, CL_MEM_READ_ONLY,  n*sizeof(float), NULL, &err);
cl_mem dY = clCreateBuffer(ctx, CL_MEM_READ_WRITE, n*sizeof(float), NULL, &err);
clEnqueueWriteBuffer(q, dX, CL_TRUE, 0, n*sizeof(float), hX, 0, NULL, NULL);

// 5. Set args + launch over an NDRange
clSetKernelArg(k, 0, sizeof(int),   &n);
clSetKernelArg(k, 1, sizeof(float), &a);
clSetKernelArg(k, 2, sizeof(cl_mem),&dX);
clSetKernelArg(k, 3, sizeof(cl_mem),&dY);
size_t global = ((n + 255)/256)*256, local = 256;     // global multiple of local
clEnqueueNDRangeKernel(q, k, 1, NULL, &global, &local, 0, NULL, NULL);  // async!

// 6. Read back + sync
clEnqueueReadBuffer(q, dY, CL_TRUE, 0, n*sizeof(float), hY, 0, NULL, NULL);
clFinish(q);
```

### The kernel (OpenCL C, compiled at runtime)
```c
__kernel void saxpy(int n, float a, __global const float* x, __global float* y) {
    int i = get_global_id(0);
    if (i < n) y[i] = a*x[i] + y[i];        // coalesced, same as CUDA
}
```

## Key Concepts

### The memory model
| Space | Qualifier | Host access | Device scope | ≈ CUDA |
|---|---|---|---|---|
| Global | `__global` | R/W | all work-items | global |
| Constant | `__constant` | R/W | all (read-only) | constant |
| Local | `__local` | — | work-group scratchpad | shared |
| Private | `__private` | — | per work-item | registers |

- **Buffer objects** (`clCreateBuffer`) — linear device memory; transfer with `clEnqueueRead/WriteBuffer` or map with `clEnqueueMapBuffer`. `CL_MEM_USE_HOST_PTR`/`CL_MEM_ALLOC_HOST_PTR` enable zero-copy/pinned paths.
- **Image objects** — 2D/3D textures with hardware sampling/interpolation and spatial caching.
- **Pipe objects** (OpenCL 2.0) — FIFO data structures for producer/consumer kernel chains.
- **Local-memory tiling** + `barrier(CLK_LOCAL_MEM_FENCE)` is the exact analogue of CUDA shared-memory tiling, with the same bank-conflict and coalescing concerns.

### Runtime kernel compilation
The kernel source is built for whatever device is found — the mechanism behind cross-vendor portability, but a per-launch *startup cost*. Mitigate by **caching the built binary** (`clGetProgramInfo(CL_PROGRAM_BINARIES)` → store → `clCreateProgramWithBinary`). Build options (`-cl-fast-relaxed-math`, `-D MACRO=val`) tune or specialize the JIT.

### Events and out-of-order queues
Every `clEnqueue*` call can produce a `cl_event` and consume a wait-list, expressing a dependency DAG — the OpenCL analogue of CUDA streams. An out-of-order command queue (`CL_QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE`) lets independent operations overlap; `clWaitForEvents`/`clEnqueueMarker` synchronize. Profile with `CL_QUEUE_PROFILING_ENABLE` + `clGetEventProfilingInfo`.

### Where OpenCL sits among portable models
- **SYCL** — single-source modern C++ over the same model; eliminates most of the host boilerplate above (kernels are C++ lambdas, buffers are RAII). The ergonomic successor when you want portability *and* C++.
- **OpenMP `target` / OpenACC** — directive-based offload; far less code than explicit OpenCL but less control over the device.

## Mental Models
- **The CUDA→OpenCL port is mechanical; the *optimization* is identical.** Thread→work-item, block→work-group, shared→`__local`, `__syncthreads`→`barrier`. Coalescing, local-memory tiling, occupancy, and minimizing transfers carry over unchanged — only the API plumbing and JIT differ.
- **Pay the portability tax deliberately** — OpenCL's boilerplate and runtime compile buy multi-vendor reach (GPU + CPU + FPGA from one binary). If you target only NVIDIA, CUDA is simpler; if you want portability with C++ ergonomics, prefer **SYCL**; if you want minimal code, prefer directive offload (OpenMP `target`).
- **Cache compiled program binaries** — runtime compilation is a startup cost you can amortize across runs.
- **Make `global` a multiple of `local`** and size work-groups by warp/wavefront width (32 NVIDIA, 32/64 AMD) for the same occupancy reasons as CUDA.

## Reference Tables

| Host API stage | Calls |
|---|---|
| discover | `clGetPlatformIDs`, `clGetDeviceIDs` |
| context | `clCreateContext`, `clCreateCommandQueueWithProperties` |
| build | `clCreateProgramWithSource`, `clBuildProgram`, `clCreateKernel` |
| memory | `clCreateBuffer`, `clEnqueueWrite/ReadBuffer`, `clEnqueueMapBuffer` |
| launch | `clSetKernelArg`, `clEnqueueNDRangeKernel` |
| sync | `clFinish`, `clWaitForEvents`, `clEnqueueMarker` |

| Portable model | Code volume | Control | Best for |
|---|---|---|---|
| OpenCL | high | high | multi-vendor, FPGA |
| SYCL | medium | high | portable + C++ ergonomics |
| OpenMP `target` / OpenACC | low | medium | quick offload of existing loops |

## Key Takeaways
1. OpenCL provides one portable data-parallel model across GPUs/CPUs/FPGAs via runtime device discovery and kernel compilation.
2. Its execution and memory models map one-to-one onto CUDA — work-item/work-group/NDRange and global/local/private — and the optimization playbook (coalescing, `__local` tiling, occupancy, fewer transfers) is identical.
3. The host program is a fixed sequence: discover → context+queue → build program → buffers → set args + `clEnqueueNDRangeKernel` → read back + `clFinish`.
4. Cache built binaries to amortize JIT cost; use events/out-of-order queues for overlap (the stream analogue).
5. Choose by need: CUDA for NVIDIA-only simplicity, OpenCL for multi-vendor/FPGA reach, SYCL for portable C++ ergonomics, OpenMP `target`/OpenACC for low-effort directive offload.

## Connects To
- **Ch 07 (CUDA)**: the identical execution/memory model and optimization levers.
- **Ch 01 (Hardware)**: the accelerator throughput model.
- **Ch 09 (OpenMP)**: `target` offload as the directive-based alternative.
- **Ch 12 (Optimization)**: coalescing, local-memory tiling, and benchmark timing apply unchanged.
