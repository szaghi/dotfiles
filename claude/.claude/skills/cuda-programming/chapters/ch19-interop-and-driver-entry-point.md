# Chapter 19: API Interoperability & Driver Entry Point Access

## Core Idea
Two distinct mechanisms for cooperation. **Graphics/API interoperability** lets CUDA share GPU buffers/images with other APIs without copying — either *graphics interop* (register-then-map an OpenGL/Direct3D resource into the CUDA address space) or the more flexible *external resource interop* (import OS-native handles — file descriptors on Linux, NT handles on Windows — for Vulkan, Direct3D 11/12, and NVSCI memory + semaphore objects). **Driver Entry Point Access** retrieves a *function pointer* to any CUDA driver API by name and version (`cuGetProcAddress` / `cudaGetDriverEntryPointByVersion`), the GPU analogue of `dlsym`/`GetProcAddress`, enabling new-feature access on an old toolkit with a new driver, and per-thread-default-stream variant selection.

## Frameworks Introduced

- **Graphics interop (register → map)**: `cudaGraphicsGLRegisterBuffer`/`...GLRegisterImage` (OpenGL), `cudaGraphicsD3D11RegisterResource` (D3D11). Map with `cudaGraphicsMapResources`, get the pointer/array via `cudaGraphicsResourceGetMappedPointer` / `cudaGraphicsSubResourceGetMappedArray`, use in a kernel, `cudaGraphicsUnmapResources`, then `cudaGraphicsUnregisterResource`.
  - When to use: in-place CUDA processing of a VBO/texture the renderer also touches.
- **External memory interop**: `cudaImportExternalMemory` → `cudaExternalMemoryGetMappedBuffer` / `...GetMappedMipmappedArray` → free with `cudaFree`/`cudaFreeMipmappedArray` → `cudaDestroyExternalMemory`.
- **External semaphore interop**: `cudaImportExternalSemaphore` → `cudaSignalExternalSemaphoresAsync` / `cudaWaitExternalSemaphoresAsync` → `cudaDestroyExternalSemaphore`. Orders execution between CUDA and Vulkan/D3D/NVSCI.
- **Driver Entry Point Access** (CUDA 11.3+): `cuGetProcAddress(name, &pfn, cudaVersion, flags, &driverStatus)` and the runtime `cudaGetDriverEntryPointByVersion`, using per-API typedefs from `cudaTypedefs.h` (`PFN_cuFoo_v<version>`).

## Key Concepts
- **Register once, map many**: registration is costly — do it once per resource per CUDA context. Map/unmap freely. Accessing a mapped resource via the other API (or another context) is undefined.
- **Device matching by UUID**: imported Vulkan objects must be used on the CUDA device whose `cudaDeviceProp::uuid` matches the Vulkan `deviceUUID`. The Vulkan device group must contain exactly one physical device.
- **Handle ownership differs by type**: Linux FDs — CUDA *takes ownership* on import (using the FD after is UB). Windows NT handles — CUDA does *not* own; the app must close them, after the underlying resource is freed. D3DKMT (KMT) handles hold no reference.
- **Binary vs timeline semaphores**: binary = 1-bit signaled/not; timeline = 64-bit counter for ordered sync with one object.
- **Versioned driver symbols**: `_v*` suffix encodes ABI changes. The `cudaVersion` passed to `cuGetProcAddress` must *exactly match the typedef version* — not `CUDA_VERSION`, not `cuDriverGetVersion()`'s result — or you may get a different-ABI symbol and UB.
- **Per-thread default stream variants**: `_ptsz`/`_ptds`-suffixed symbols; select via `--default-stream per-thread`, `CUDA_API_PER_THREAD_DEFAULT_STREAM`, or the `CU_GET_PROC_ADDRESS_PER_THREAD_DEFAULT_STREAM`/`cudaEnablePerThreadDefaultStream` flags.

## Mental Models
- Graphics interop = **lending the renderer's buffer to CUDA for a moment** (map), editing it in place, then handing it back (unmap) — no copy, but never touch it from both sides while mapped.
- External interop = **a shared safe-deposit box keyed by an OS handle**: both APIs hold a key; semaphores are the protocol for "I'm done, your turn" so neither reads mid-write.
- `cuGetProcAddress` = **calling the driver's phone book by name and a specific edition number**: ask for the wrong edition and you may dial a number whose call signature changed under you.

## Anti-patterns
- **Accessing a resource from OpenGL/D3D/another context while CUDA has it mapped** → undefined results.
- **Registering a bindless OpenGL texture** (after `glGetTextureHandle`/`glGetImageHandle`) → fails; register for interop *before* requesting the handle.
- **Reusing a Linux FD after a successful CUDA import** → UB (CUDA owns it). Conversely, forgetting to close a Windows NT handle → leak.
- **Mismatched import/export mappings** (offset/size/format/mip-levels not matching the exporting API) → undefined behavior.
- **Issuing a wait before its corresponding signal** on an external semaphore → illegal.
- **Passing `CUDA_VERSION` or `cuDriverGetVersion()` to `cuGetProcAddress` instead of the literal typedef version** → may silently return a newer `_v3` symbol called through a `_v2` typedef → UB.
- **Calling `cuGetProcAddress` without first checking `cuDriverGetVersion()` is sufficient** → error or unexpected symbol.
- **Destroying an `NvSciSyncObj`/`NvSciBufObj` while still imported into CUDA** → UB (ownership stays with the app, but lifetime must outlive CUDA use).

## Reference Tables

**Interop import/free pairing**

| Resource | Import | Map | Free mapping | Destroy |
|---|---|---|---|---|
| Graphics (GL/D3D) | `cudaGraphics*RegisterResource/Buffer/Image` | `cudaGraphicsMapResources` + `...GetMappedPointer/Array` | `cudaGraphicsUnmapResources` | `cudaGraphicsUnregisterResource` |
| External memory | `cudaImportExternalMemory` | `cudaExternalMemoryGetMappedBuffer` / `...MipmappedArray` | `cudaFree` / `cudaFreeMipmappedArray` | `cudaDestroyExternalMemory` |
| External semaphore | `cudaImportExternalSemaphore` | signal/wait async | — | `cudaDestroyExternalSemaphore` |

**External handle types** (`cudaExternalMemoryHandleType*`): `OpaqueFd` (Linux, CUDA owns), `OpaqueWin32`/`OpaqueWin32Kmt` (Windows NT/KMT), `NvSciBuf`. Semaphores add `TimelineSemaphoreFd`/`...Win32`, `NvSciSync`.

**`cuGetProcAddress` driver status (`CUdriverProcAddressQueryResult`)**

| Status | Meaning |
|---|---|
| `CU_GET_PROC_ADDRESS_SUCCESS` | symbol found and usable |
| `CU_GET_PROC_ADDRESS_VERSION_NOT_SUFFICIENT` | symbol exists in driver but added *after* the requested `cudaVersion` (upgrade toolkit) |
| `CU_GET_PROC_ADDRESS_SYMBOL_NOT_FOUND` | not in driver (old driver or typo) |

Typedef headers: `cuda.h`→`cudaTypedefs.h`, `cudaGL.h`→`cudaGLTypedefs.h`, `cudaD3D11.h`→`cudaD3D11Typedefs.h`, etc. Flags: `CU_GET_PROC_ADDRESS_DEFAULT`, `..._LEGACY_STREAM`, `..._PER_THREAD_DEFAULT_STREAM`.

**SLI notes**: explicit SLI only (implicit unsupported); an allocation consumes memory on all SLI GPUs (early OOM); register resources per device; identify rendering device via `cudaD3D[9|10|11]GetDevices`/`cudaGLGetDevices` with `...DeviceListCurrentFrame`.

## Worked Example
Accessing a new-toolkit driver API from an older toolkit by retrieving its function pointer at runtime — the canonical Driver Entry Point Access pattern:

```cpp
#include <cudaTypedefs.h>

int cudaVersion;
status = cuDriverGetVersion(&cudaVersion);
if (cudaVersion >= 11020) {                          // cuMemAllocAsync added in 11.2
    PFN_cuMemAllocAsync_v11020 pfn_cuMemAllocAsync;  // typedef from cudaTypedefs.h

    cudaGetDriverEntryPointByVersion("cuMemAllocAsync", &pfn_cuMemAllocAsync,
                                     11020, cudaEnableDefault, &driverStatus);

    if (driverStatus == cudaDriverEntryPointSuccess && pfn_cuMemAllocAsync) {
        pfn_cuMemAllocAsync(...);                     // call through the pointer
    }
}
```
- **What it demonstrates**: gate on `cuDriverGetVersion` first, request the symbol with the *exact* version matching its typedef (`11020`), and check `driverStatus` before dereferencing. The driver-API twin (`cuGetProcAddress("cuFoo", &pfn, 12050, CU_GET_PROC_ADDRESS_DEFAULT, &driverStatus)`) lets you manually `typedef PFN_cuFoo_v12050` to call an API your toolkit's headers don't even declare.

## Key Takeaways
1. Graphics interop is register-once / map-many / unmap-before-other-API-touches; external interop imports OS handles for zero-copy sharing across Vulkan/D3D/NVSCI.
2. Memory and semaphore objects are separate import paths; semaphores (binary or timeline) order CUDA against the other API.
3. Handle ownership is type-specific: Linux FD → CUDA owns; Windows NT → app owns and must close; keep NvSci objects alive past CUDA use.
4. Match imported devices by UUID; match mapping offset/size/format exactly or get UB.
5. Driver Entry Point Access retrieves driver-API function pointers by name + exact version via `cuGetProcAddress`/`cudaGetDriverEntryPointByVersion` — enabling new features on old toolkits with a new driver.
6. Always pass the literal typedef version (not `CUDA_VERSION`), gate on `cuDriverGetVersion`, and branch on `CUdriverProcAddressQueryResult` to distinguish "upgrade toolkit" from "upgrade driver."

## Connects To
- **Ch 16**: NvSci cacheability/compression attributes touch the L2 / compressible-memory controls; `EnableGpuCache`/`EnableGpuCompression`.
- **Ch 17**: external interop and VMM share the OS-handle (FD / NT handle) export/import model.
- **Streams & events chapters**: external semaphores extend stream ordering across API boundaries; per-thread-default-stream variants change synchronization semantics.
- **Ch 20 (compute capabilities)**: device UUID/feature queries used in interop device matching.
- **Vulkan / OpenGL / Direct3D ecosystems**: this chapter is the CUDA-side contract; the other half lives in those APIs' extension specs (`VK_KHR_external_memory`, etc.).
