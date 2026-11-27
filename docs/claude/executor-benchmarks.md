---
title: Executor benchmarks
next:
  text: Cookbook
  link: /guide/cookbook
---

# Executor benchmarks

Measurements behind the executor choices on [Executors](/claude/executors): engine speed on adam's two GPUs,
executor quality on the `bench-delegate` suite, and one real task, a paper ingested into the llm-wiki.

## Engine comparison (2026-11-26)

Same weights on every engine for the Qwen3-Coder rows: unsloth Qwen3-Coder-30B-A3B-Instruct Q4_K_M (18.56 GB,
MoE, 3B active), Qwen's recommended sampling (temperature 0.7, top-p 0.8, top-k 20, repeat penalty 1.05), 32k context,
2 × RTX 4070. Two tasks through `delegate` with a check, warm server, three runs each: **T1** fix a one-line bug,
**T2** implement a function from its docstring until a 5-case unittest passes, test file unchanged. Times are pi's
wall clock (`executor.elapsed_s`), medians.

| Engine, model | Cold load | GPU share | T1 | T2 |
|---|---|---|---|---|
| Ollama 0.34, qwen3.8:27b dense (former default) | 31 s | 89% | 3/3, 14.7 s | 3/3, 137.9 s |
| Ollama 0.34, Qwen3-Coder-30B-A3B | 32 s | 94% | 3/3, 5.1 s | 3/3, 24.6 s |
| llama.cpp b8645, same GGUF | 18 s | 100% | 2/3, 5.6 s | 3/3, 23.5 s |
| ik_llama.cpp b4433, same GGUF | 8 s (file in page cache) | 100% | 3/3, 3.3 s | 3/3, 17.3 s |
| llama.cpp master 09c1410, Inkling-2-Mini UD-Q4_K_XL | 41 s | partial (auto-fit) | 3/3, 73.0 s | 3/3, 223.4 s |

- On these two easy tasks the MoE coder model is 3-6x faster than the dense 27B at the same pass rate, which made
  it the default for a day; the harder tasks of the next section reversed that.
- llama.cpp's failure: Qwen3-Coder wrote its tool call as plain text (no opening `<tool_call>`), llama.cpp did
  not parse it, pi ended after one turn with no change, and the check reported `check_failed`. Ollama's own
  Qwen3-Coder parser handled all six runs.
- One ik_llama T1 run took 49.5 s: the model's first command was `find /home/stefano -name calc.py`, a scan of
  the whole home directory, before it edited the file in its clone. The preamble's "work only inside the current
  directory" is advice, not enforcement: see *not a sandbox* above.
- Inkling-2-Mini (unsloth UD-Q4_K_XL, 17.6 GB; arch `inkling2_loop`: 128-expert MoE, blocks 6-18 looped 3
  times) needs llama.cpp newer than b8645: it ran on a master build (`~/llama.cpp-master`, gcc-14 + CUDA 13.1),
  which has since replaced the b8645 build as adam's `LLAMACPP_BIN` (Qwen3-Coder on it: T1 3/3 5.0 s, T2 3/3
  23.1 s, 70-74 tokens/s); ik_llama and Ollama 0.34 do not know the architecture. Correct on
  every run, with its own sampling defaults (temperature 1.0, top-k 0), but slow on 2 × RTX 4070: 11-16 tokens/s
  generated against 66-90 for Qwen3-Coder on the same probe, because 17.6 GB of weights plus the 32k cache do not
  fit, so the fitter keeps some tensors on the CPU (`--fit-target 256,256`: 15-16 tokens/s), and it writes 2-3x
  more tokens per task. Not a delegate executor on this hardware.
- n = 3 per cell: enough to rank the dense model against the MoE one, not to separate the three engines on
  speed. Cold loads are not comparable: Ollama reads its own copy of the blob, the llama.cpp-family servers read
  the GGUF in `~/models`, which earlier loads had left in the page cache.

## Executor quality (2026-11-26)

`claude/.claude/skills/delegate/bench/bench-delegate` runs `delegate` on a fixed suite and reports pass rate and
time per task. T1 and T2 are the two tasks above; H1-H3 are harder, multi-module tasks on a small `ledger` package:
exact Decimal money with half-up rounding across parser and report (H1), monthly grouping in the library and the CLI
(H2), and renaming a dataclass field behind a deprecation shim for read, write and keyword (H3). Hidden tests decide;
the executor never sees them (they ship compressed, because an executor once ran `find /home/stefano`).
`bench-delegate --validate` proves each task fails untouched and passes with a reference fix.

```bash
bench=~/.claude/skills/delegate/bench/bench-delegate
$bench --validate
$bench --label qwen38 -- --model llamacpp/llama --thinking off --timeout 1800
```

Three runs per task; hard-task medians:

| Executor | All | Hard (H1-H3) | Hard: time, turns, output tokens | Generation |
|---|---|---|---|---|
| Ollama Qwen3-Coder-30B-A3B Q4_K_M (former default) | 8/15 | 2/9 | 71 s, 29, 4,084 | 66-90 tok/s |
| llama.cpp Qwen3.8-27B UD-Q4_K_XL, thinking off | **15/15** | **9/9** | 83 s, 8, 1,980 | 25 tok/s |
| Ollama, same GGUF and sampling, thinking off (**default**) | **15/15** | **9/9** | 114 s, 8, 2,659 | ~23 tok/s |
| same + harness-hub `Qwen3.8-27B-pi-adapted` LoRA (F16) | 13/15 | 8/9 | 58 s, 5, 1,254 | 23-24 tok/s |
| OpenCode Go `deepseek-v4.1-flash`, thinking off | - | **9/9** | **15 s, 5, 1,495** | cloud |
| OpenCode Go `qwen3.7-plus`, thinking off | - | 9/9 | 63 s, 14, 2,753 | cloud |
| OpenCode Go `kimi-k2.7-code`, thinking off | - | 7/9 | 48 s, 11, 3,443 | cloud |
| opencode harness, OpenCode Go `deepseek-v4.1-flash` (2026-11-27) | - | **9/9** | 33 s, 6, 1,689 | cloud |
| opencode harness, Zen `nemotron-3.5-super-vl-free` (2026-11-27)* | - | 3/3 H1, then quota | 37 s, 8, 2,131 (H1) | cloud, free |

- The dense Qwen3.8-27B is the better executor on anything beyond a one-liner: Qwen3-Coder fails 7 of 9 hard runs
  after 24-38 turns (H2: accepted `2026-1-5` as a date; H3: no `amt=` keyword, both stated in the task), while
  Qwen3.8-27B passes all 9 in 5-11 turns. Despite generating 3x slower its hard-task times are similar; on T1/T2 it
  is slower (12 s and 20 s against 5 s and 19 s).
- On Ollama the same model passed everything too, with its one-liners slightly faster and H3 slower (246, 874 and
  389 s against about 100 s on llama.cpp: the model iterating on its own failing checks, up to 57 turns, at the
  same ~23 tok/s); three runs at temperature 0.8 cannot tell whether that is the engine. It became the default
  because Ollama loads it on demand.
- The pi adapter delivers the efficiency its card claims (about 30% less time and 37% fewer tokens than the base on the
  hard tasks) but not more passes here: the base leaves no headroom on this suite, and the adapter's two failures were a
  run that declared T2 done without running its tests and an H3 run that never exercised the `amt=` requirement.
- All 206 tool calls of the two Qwen3.8 configurations stayed inside their clones (scratch CSVs in `/tmp` aside); none
  touched the hidden tests or reference patches.
- Cloud (OpenCode Go, hard tasks only to spare the plan's allowance, pi 1.6.1): DeepSeek V4.1 Flash passed all 9
  in 12-20 s with 4-6 turns every time, about 5x faster than the local default at the same pass rate. Qwen3.7
  Plus passed all 9 more slowly (10-22 turns). Kimi K2.7 Code repeated Qwen3-Coder's H2 mistake (accepted
  `2026-1-5`) in 2 of 3 runs, and one H3 run took 270 s and 28 turns. All 363 cloud tool calls stayed in their
  clones. The local Qwen3.8-27B stays the default: equally correct here, free, and the code never leaves the
  machine; DeepSeek V4.1 Flash is the opt-in when that is acceptable. With three executors at 9/9 the suite ranks
  them on time and consistency only; separating them on quality needs harder tasks.
- Harness, same model (opencode 2.1.0, `delegate --harness opencode`): DeepSeek V4.1 Flash passed all 9 hard runs
  through opencode too, but took about twice as long as through pi (33 s against 15 s median, 16-66 s, 5-12 turns):
  opencode's ~5.9k-token system prompt and its extra exploratory steps. A first run with the doubled, re-quoted
  prompt (the bug described above) had also passed 9/9 in 28 s: on these tasks the defect cost nothing measurable.
  \*Nemotron ran only with that defective prompt: it passed its three H1 runs (37 s, 8 turns); every later run
  failed in 1.3 s with `provider.quota` 429 "Free usage limit reached", after a day that had also spent about 180k
  input tokens on the paper ingestion below. The free tier is a quota, not a plan: fine for
  an occasional task, not for a bench or a fan-out. `delegate` reports it as `status: error` with that message.
- Caveats: n = 3 per task, five Python tasks, a Q4 quant (the adapter was trained on BF16; its card recommends Q8_0,
  which does not fit 24 GB), sampling as the adapter was trained (temperature 0.8, top-p 1.0) for both Qwen3.8 rows.
  The first run of the suite counted an added test file as tampering; the check was fixed and the Qwen3-Coder patches
  rescored before these numbers.

## Real task: a paper into the llm-wiki (2026-11-27)

The bench tasks are small and fully checkable. To see how far that carries, the same ingestion was given to
four executors: He, Liu & Wang (2022), *On the mechanisms of the multiplicity and bifurcation of detonation
waves in 3D rotating detonation engines* (Aerosp. Sci. Technol. 130, 107874; 15 pages, 81 references), into a
freshly scaffolded `rotating-detonation-engine` bundle of `~/llm-wiki`, following that repository's law
(concept pages, notation registry and per-source notation map, complete `bibliography.bib`). One task text
for all; the check was the repository's own `tools/lint_okf.py` and `tools/bundles.py --check` plus "nothing
outside the bundle, the README and the skill's bundle table changed". That check proves the form, not the
content, so the content was scored claim by claim against the paper.

| Executor | Harness | Time | Check | Concept pages, words | Bibliography | Claims wrong | Paper errors flagged |
|---|---|---|---|---|---|---|---|
| Opus 5.5 (the orchestrator, by hand) | Claude Code | - | pass | 7, 4,513 | 81 | 0 of 47 | 20 |
| DeepSeek V4.1 Flash | pi via `delegate` | 364 s, 41 turns | pass | 13, 6,344 | 81 | 13 of 40 | - |
| Qwen3.8-27B local (64k context) | pi via `delegate` | timeout at 5,400 s | fail | 2, 1,982 | 9 | invented content | - |
| Nemotron 3.5 Super VL (Zen, free) | `opencode run` | 1,050 s, 37 steps | pass | 5, 1,015 | 81 | 6 of ~38 | 0 |

- **Opus**: the version committed to `~/llm-wiki` (after an independent review found four defects, since fixed).
- **DeepSeek**: fast and formally clean, but over-split the paper into 13 pages, let the paper's $h$ collide with
  the registry's fill height, and put the cavity on the wrong wall.
- **Local Qwen3.8**: two concept pages and nine references in 90 minutes, with content the paper does not contain.
  A 27B dense model at ~23 tok/s cannot read and write at this volume.
- **Nemotron**: the most accurate of the three executors but the thinnest (about 200 words per page, no page for
  the propulsive-performance result or the injection model). Two outright errors swap timings between cases (C1h3
  "364 μs to its first stable wave" is C2h3's stable-mode time, C1h3 forms its first stable wave at 400 μs; C4h3
  never reaches a stable three-wave mode: it turns periodic, 3 ↔ 2 waves, at 288 μs; 484 μs is C1h3's). Four more
  generalise beyond the text: the C2 mode-lock holds for ψ 44.5-54.7 % only; the matched-flow-rate check is
  reported for C1h5 only; the variance range ignores C4; the 3.0 % velocity error is the coarse mesh's, not the
  medium one's. It added two symbols to the registry while using ψ in a page without registering it, called the
  tables transcribed when they were not, and flagged none of the paper's own errors.
- **The bibliography is the delegable part.** Nemotron's 81 entries match the reviewed Opus list field by field
  (authors, volume, pages; one diacritic aside), DeepSeek's too. Both copied the list as printed, including two
  misprinted years (Sutherland 1893 as 2009, an online-first 2017 for a 2018 issue) that the Opus pass corrected. Extracting a reference list is mechanical and checkable against the PDF; writing concept pages is
  neither: every executor's pages need a claim-by-claim review that costs about as much as writing them.
- Method: the Opus, DeepSeek and local outputs were scored blind (anonymised, independent reviewer agent, its
  claims spot-checked); Nemotron's afterwards, unblinded, by checking each of its claims against the paper text.
  One paper, one run each.
- Nemotron ran through `opencode run --format json "$(cat task.md)"` by hand, a different harness from the pi
  runs, and so received the task with every `"` escaped (see *Never pass the prompt as an argument*); it is now
  reachable as `delegate --harness opencode`, which sends it unchanged. On this evidence it is more accurate than DeepSeek but too thin to
  use without the same full review.
