# Chapter 11: JAX — JIT, Autodiff & Automatic Vectorization

## Core Idea
JAX is NumPy with three composable function transformations: **`jit`** (compile to fused XLA kernels), **`grad`** (automatic differentiation), and **`vmap`** (automatic vectorization). The catch and the power are the same: transformations require **pure functions** on immutable arrays, which is exactly what lets the compiler optimize aggressively and target CPU/GPU/TPU from one source.

## Frameworks Introduced

- **`jax.numpy` (`jnp`)**: a NumPy-compatible API over immutable arrays. Looks like NumPy; arrays can't be mutated in place (`x.at[i].set(v)` returns a new array). Runs on CPU, GPU, or TPU transparently.

- **The three transformations** (composable):
  - **`jax.jit`** — traces a function once and compiles it to a fused **XLA** kernel; subsequent calls run the optimized kernel. Fusion eliminates intermediate arrays and launch overhead — often the biggest single speedup. Requires the function be pure and shapes static.
  - **`jax.grad`** — returns a function computing the exact gradient via reverse-mode **automatic differentiation**; composes (`grad(grad(f))` for second derivatives), and `value_and_grad` returns both. The foundation for optimization and ML.
  - **`jax.vmap`** — vectorizes a function written for a single example to operate over a batch axis, with no manual broadcasting — and `pmap` does the same across devices (Ch 9).

- **Functional discipline**: transformations require **pure functions** (no side effects, no in-place mutation, deterministic). Randomness is explicit via PRNG keys (`jax.random.PRNGKey`, split per use) so it's reproducible and traceable.

## Key Concepts
- **Tracing & static shapes**: `jit` traces with abstract values; control flow that depends on array *values* (not shapes) needs `jax.lax.cond`/`scan`/`while_loop` rather than Python `if`/`for` over data. Recompiles when input shapes change.
- **Why purity buys speed**: no side effects means XLA can reorder, fuse, and eliminate operations freely — the same property that makes `grad`/`vmap` well-defined.
- **`pytrees`**: nested dicts/lists/tuples of arrays that transformations map over transparently — how model parameters are passed around.
- **Composition**: `jit(grad(vmap(f)))` — the transformations stack, e.g. a compiled, batched gradient.

## Mental Models
- **Write pure functions on immutable arrays and let the transformations compose** — `jit` for speed, `grad` for derivatives, `vmap` for batching; their composability is the whole design.
- **`jit` is usually the first and biggest win** — kernel fusion removes temporaries and launch overhead; wrap the hot computation and feed it static shapes.
- **`vmap` instead of writing batched code by hand** — author the math for one example, then map over the batch axis; cleaner and as fast.
- **Use `grad` for any optimization problem** — exact gradients, no finite differences; compose for higher-order derivatives.
- **Make randomness explicit** — thread PRNG keys; never rely on hidden global RNG state inside transformed functions.

## Code Examples
```python
import jax, jax.numpy as jnp
from jax import jit, grad, vmap

# Pure function on immutable arrays
def loss(w, x, y):
    pred = x @ w
    return jnp.mean((pred - y) ** 2)

# Compose: compiled gradient of the loss
grad_loss = jit(grad(loss))             # fused XLA kernel computing dL/dw
g = grad_loss(w, X, Y)

# vmap: write for one example, map over a batch
def predict_one(w, x): return jnp.dot(w, x)
batched = vmap(predict_one, in_axes=(None, 0))   # broadcast w, map over rows of X
preds = batched(w, X)

# Explicit randomness
key = jax.random.PRNGKey(0)
key, sub = jax.random.split(key)
noise = jax.random.normal(sub, (n,))
```
- **What it demonstrates**: a pure loss, a composed `jit(grad(...))`, `vmap` batching, and explicit PRNG keys.

## Reference Tables

| Transformation | Does | Requires |
|---|---|---|
| `jit` | compile to fused XLA kernel | pure fn, static shapes |
| `grad` | reverse-mode autodiff | differentiable pure fn |
| `vmap` | auto-vectorize over batch axis | — |
| `pmap` | parallelize across devices | — |

| JAX rule | Reason |
|---|---|
| immutable arrays (`.at[].set`) | enables fusion + autodiff |
| pure functions | transformations well-defined |
| explicit PRNG keys | reproducible, traceable |
| `lax.cond`/`scan` for value-dependent control | jit traces shapes, not values |

## Key Takeaways
1. JAX = NumPy + composable transformations: `jit` (compile/fuse), `grad` (autodiff), `vmap` (auto-batch), `pmap` (multi-device).
2. Transformations require pure functions on immutable arrays — the same purity that enables aggressive XLA optimization.
3. `jit` is usually the biggest single win (fusion removes temporaries and launch overhead); feed it static shapes.
4. `vmap` lets you write single-example math and batch it automatically; `grad` gives exact gradients for optimization.
5. Make randomness explicit with PRNG keys; use `lax.cond`/`scan` for value-dependent control flow inside `jit`.

## Connects To
- **Ch 03 (NumPy)**: the array API JAX mirrors (immutably).
- **Ch 09 (Multi-GPU)**: `pmap` for device parallelism.
- **Ch 10 (CuPy)**: an alternative GPU array model (without autodiff/JIT).
- **Ch 13 (Applications)**: JAX for optimization, PINNs, and ML training.
