# Chapter 2 (§2.1–2.4): Directive format, conditional compilation, ICVs, device-specific clauses

## Core Idea
The mechanics shared by all OpenACC directives: how to spell them in C/C++ vs Fortran, the `_OPENACC` version macro, the internal control variables (ICVs), and the `device_type` mechanism for per-device tuning in one directive.

## Frameworks Introduced
- **Directive format** (§2.1):
  - C/C++: `#pragma acc directive-name [clause-list]` (or `_Pragma("acc ...")`). First token after `acc`; **case-sensitive**; subject to macro replacement.
  - Fortran free-form: `!$acc directive-name [clause-list]`; sentinel `!$acc` is one word; continuation with trailing `&`, continued lines re-start with the sentinel. Fixed-form sentinels: `!$acc`/`c$acc`/`*$acc`.
- **Conditional compilation** (§2.2): the `_OPENACC` macro = `yyyymm` of the supported version (this spec = **202506**). Defined only when OpenACC is enabled — guard host fallbacks with `#ifdef _OPENACC`.
- **Internal Control Variables** (§2.3): implementation-maintained state, set by env vars / API / clauses, read by API:
  - `acc-current-device-type-var` — which device *type*.
  - `acc-current-device-num-var` — which device of that type.
  - `acc-default-async-var` — the queue used when `async` has no argument.
  - One ICV copy per (non-compute-generated) host thread; compute-generated threads inherit the local thread's values.
- **Device-specific clauses** (§2.4): `device_type(list | *)` (abbrev **`dtype`**) partitions a directive's clauses. Clauses *before* any `device_type` are **defaults**; clauses *after* one apply only to those device types. The most *specific* matching architecture name wins; `*` is least specific. A directive with ≥1 device-specific clause is **device-dependent**.

## Reference Tables
### ICV modify / retrieve (§2.3.1)
| ICV | Modify | Retrieve |
|---|---|---|
| `acc-current-device-type-var` | `acc_set_device_type`, `set device_type`, `init device_type`, `ACC_DEVICE_TYPE` | `acc_get_device_type` |
| `acc-current-device-num-var` | `acc_set_device_num`, `set device_num`, `init device_num`, `ACC_DEVICE_NUM` | `acc_get_device_num` |
| `acc-default-async-var` | `acc_set_default_async`, `set default_async` | `acc_get_default_async` |

## Worked Example
Per-device tuning with `device_type` (from the spec):
```c
// worker is foo-specific; gang is a default applying to ALL device types
#pragma acc loop gang device_type(foo) worker
// tune launch geometry per architecture in one directive:
#pragma acc parallel loop device_type(nvidia) num_gangs(1024) \
                          device_type(*) num_gangs(256)
```
Host-fallback guard:
```c
#ifdef _OPENACC
  #pragma acc parallel loop
#endif
  for (int i = 0; i < n; ++i) a[i] = b[i] + c[i];
```
- **Demonstrates**: `device_type` partitioning (defaults before it, device-specific after), `dtype` semantics, and `_OPENACC` conditional compilation.

## Anti-patterns
- **Mixing free/fixed Fortran sentinel rules**: continuation differs; follow the source form's rules.
- **Assuming `_OPENACC` is always defined**: it's only defined when OpenACC is enabled — that's the point of the guard, but don't rely on it in non-OpenACC builds.
- **Forgetting clause order in `device_type`**: clauses *before* the first `device_type` are global defaults; a clause placed after one silently becomes device-specific.
- **Relying on ICV initial values**: they're implementation-defined until env vars are read.

## Key Takeaways
1. C/C++ `#pragma acc ...` (case-sensitive); Fortran `!$acc ...` (sentinel is one word, `&` continuation).
2. `_OPENACC` = `202506` for v3.4; use `#ifdef _OPENACC` for host fallbacks.
3. Three ICVs: current device type, device num, default async queue — set via env/API/clauses.
4. `device_type(...)` (`dtype`) tunes one directive per architecture: defaults before it, device-specific after; most-specific name wins, `*` is the catch-all.

## Connects To
- **Ch 3–7**: every construct uses this directive syntax and may carry `device_type`.
- **Ch 9**: environment variables (`ACC_DEVICE_TYPE`, `ACC_DEVICE_NUM`) set the ICVs.
- **Ch 8**: runtime library — `acc_set_device_*`/`acc_get_device_*` manipulate ICVs.
