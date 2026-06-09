# Chapter 8 (Ch 3): Runtime Library

## Core Idea
The runtime API — `acc_*` routines (C header `openacc.h`, Fortran module `openacc`) for device control, data management, async query, and memory ops. The imperative counterpart to the declarative directives, for cases where directives don't fit (libraries, dynamic logic, interop).

## Frameworks Introduced
- **Device control**: `acc_get_num_devices(type)`, `acc_set_device_type`/`acc_get_device_type`, `acc_set_device_num`/`acc_get_device_num`, `acc_init`/`acc_init_device`/`acc_shutdown`, `acc_get_property`/`acc_get_property_string` (memory size, name, driver).
- **Data management** (directive equivalents): `acc_copyin`/`acc_copyout`/`acc_create`/`acc_delete` (+ `_async`, `_finalize` variants), `acc_attach`/`acc_detach`, `acc_update_device`/`acc_update_self`, `acc_is_present`, `acc_deviceptr`/`acc_hostptr`, `acc_map_data`/`acc_unmap_data`.
- **Raw memory**: `acc_malloc`/`acc_free`, `acc_memcpy_to_device`/`acc_memcpy_from_device`/`acc_memcpy_device` (+ `_async`).
- **Async query/sync**: `acc_async_test`/`acc_async_test_all` (nonblocking poll), `acc_wait`/`acc_wait_all`/`acc_wait_async` (the API form of the `wait` directive), special handles `acc_async_sync`/`acc_async_noval`/`acc_async_default`.
- **Introspection**: `acc_on_device(devicetype)` — at compile/runtime, test whether code is executing on a given device type (for host/device code paths).

## Key Concepts
- **`acc_on_device(acc_device_not_host)`**: the canonical way to branch host-vs-device inside a `routine`.
- **`_finalize` variants** (`acc_copyout_finalize`, `acc_delete_finalize`): force the reference counter to zero (immediate free) regardless of nesting — the API analog of `exit data ... finalize`.
- **`acc_present_or_*`** (`acc_pcopyin`, `acc_pcreate`): copy/create only if not already present (idempotent staging).
- **device kinds**: `acc_device_none/host/not_host/default/current` plus vendor-specific values select targets.
- **error codes** (`acc_error_*`): `not_present`, `out_of_memory`, `present`, `invalid_async`, `device_unavailable`, etc. — surfaced via the error callback (ch10).

## Reference Tables
### Directive ↔ API correspondence
| Directive | API routine |
|---|---|
| `enter data copyin` | `acc_copyin` |
| `exit data copyout` | `acc_copyout` (`_finalize`) |
| `enter data create` | `acc_create` |
| `exit data delete` | `acc_delete` (`_finalize`) |
| `update device` | `acc_update_device` |
| `update self` | `acc_update_self` |
| `present(v)` test | `acc_is_present` |
| `attach`/`detach` | `acc_attach`/`acc_detach` |
| `wait` | `acc_wait`/`acc_wait_all` |
| `host_data use_device` | `acc_deviceptr` |

## Worked Example
```c
#include <openacc.h>
// pick device explicitly, query memory, stage data imperatively (e.g. in a library)
acc_set_device_num(0, acc_device_nvidia);
size_t freemem = acc_get_property(0, acc_device_nvidia, acc_property_free_memory);

double *a = malloc(n*sizeof(double));
acc_copyin(a, n*sizeof(double));            // == enter data copyin(a[0:n])
#pragma acc parallel loop present(a[0:n])
for (int i = 0; i < n; ++i) a[i] *= 2.0;
acc_copyout(a, n*sizeof(double));           // == exit data copyout(a[0:n])

// host/device branch inside a routine
#pragma acc routine seq
double f(double x) { return acc_on_device(acc_device_not_host) ? fast(x) : ref(x); }
```
- **Demonstrates**: explicit device selection + memory query, imperative `acc_copyin`/`acc_copyout` matching the data directives, and `acc_on_device` for dual code paths.

## Anti-patterns
- **Mixing API data management and directive data clauses on the same var carelessly**: both touch the same reference counters — coherent, but reason about counts or you'll free too early/late.
- **`acc_malloc`/`acc_memcpy_*` when directives suffice**: raw memory bypasses the present table — only for interop or custom allocators.
- **Hardcoding device numbers in portable code**: query `acc_get_num_devices` first.
- **Ignoring `acc_async_test` return**: a nonblocking poll that you must loop on, not assume complete.

## Key Takeaways
1. Every data directive has an `acc_*` API twin (`acc_copyin` ↔ `enter data copyin`, etc.) — they share the same reference-counter model.
2. `acc_on_device(acc_device_not_host)` is the host/device branch primitive inside routines.
3. `_finalize` variants force immediate free; `acc_present_or_*` make staging idempotent.
4. Use the API for libraries / dynamic logic / interop; prefer directives for static, lexically-scoped cases.
5. `acc_get_property` exposes device memory/name/driver for capacity-aware code.

## Connects To
- **Ch 2**: ICVs — `acc_set/get_device_*`, `acc_set/get_default_async`.
- **Ch 4**: data clauses — the directive forms of `acc_copyin`/`acc_create`/etc.
- **Ch 7**: async — `acc_wait`/`acc_async_test` mirror `wait`.
- **Ch 10**: profiling/errors — `acc_error_*` codes flow to the callback.
