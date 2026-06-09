# Chapter 9 (Ch 4): Environment Variables

## Core Idea
The three standard environment variables that set initial ICV values at program startup — device selection and profiling-library injection. Read after initial ICV assignment but before any OpenACC construct/API call. (A short, reference chapter.)

## Reference Tables
| Variable | Controls | ICV | Example |
|---|---|---|---|
| `ACC_DEVICE_TYPE` | default device type | `acc-current-device-type-var` | `export ACC_DEVICE_TYPE=NVIDIA` |
| `ACC_DEVICE_NUM` | default device number (of that type) | `acc-current-device-num-var` | `export ACC_DEVICE_NUM=1` |
| `ACC_PROFLIB` | profiling/tools library to load | — | `export ACC_PROFLIB=/path/libaccprof.so` |

## Key Concepts
- **Precedence**: env var sets the *initial* ICV value; a later API call (`acc_set_device_type`) or `set` directive overrides it for the calling thread. So env = default, API/directive = override.
- **`ACC_DEVICE_TYPE`** values are implementation-defined names (e.g. `NVIDIA`, `HOST`, `MULTICORE`, `RADEON`) — see the implementer recommendations (Appendix A).
- **`ACC_PROFLIB`** loads a tools-interface library implementing the profiling/error-callback hooks (ch10) — the injection point for profilers and custom error handlers.
- **`ACC_DEVICE_NUM`** selects which device of the chosen type (0-based or 1-based per implementation; verify).

## Worked Example
```bash
# Run on the second NVIDIA GPU, with a custom profiling library attached
export ACC_DEVICE_TYPE=NVIDIA
export ACC_DEVICE_NUM=1
export ACC_PROFLIB=/opt/tools/libaccprof.so
./my_openacc_app
```
Equivalent runtime override (takes precedence over the env vars above):
```c
acc_set_device_type(acc_device_nvidia);
acc_set_device_num(1, acc_device_nvidia);
```
- **Demonstrates**: env-var configuration for device selection + profiler injection, and the API override that supersedes it.

## Anti-patterns
- **Hardcoding device selection in source for a multi-GPU/cluster run**: prefer `ACC_DEVICE_NUM` (often set per-rank from the MPI local rank) so one binary maps cleanly onto GPUs.
- **Assuming `ACC_DEVICE_TYPE` names are portable**: they're implementation-defined — don't hardcode a vendor name in portable launch scripts without a fallback.
- **Forgetting `ACC_PROFLIB`** when a profiler "sees nothing": the tools library must be on this path to hook in.

## Key Takeaways
1. `ACC_DEVICE_TYPE` + `ACC_DEVICE_NUM` set the default device; `ACC_PROFLIB` injects the profiling/error-callback library.
2. Env vars set *initial* ICVs; API calls and `set` directives override per thread.
3. In MPI+OpenACC, map ranks to GPUs via `ACC_DEVICE_NUM` (commonly from the node-local rank).

## Connects To
- **Ch 2**: ICVs these variables initialize.
- **Ch 8**: `acc_set_device_*` API overrides.
- **Ch 10**: `ACC_PROFLIB` loads the profiling/error-callback implementation.
