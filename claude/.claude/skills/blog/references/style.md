# Voice — technical dev posts

Written for an HPC/Fortran/Python author who prizes precision and rejects
filler. The prose-reviewer agent enforces most of this via the `stop-slop`
skill; this file is the positive statement of the target voice.

## Register

- **Direct and assertive.** State claims with confidence. Drop "might",
  "could", "perhaps", "it seems", "arguably" unless the uncertainty is real and
  relevant — not hedging for social comfort.
- **Peer-to-peer, not vendor-to-customer.** You are explaining to someone who
  could have done this themselves. No marketing enthusiasm, no "amazing",
  "powerful", "game-changing", "seamless".
- **Conversational but precise.** Contractions are fine. Sloppy terms are not.

## Terminology discipline

Use the right word. Common slips to avoid:
- "parallel" vs "concurrent" — not interchangeable.
- "compiler" vs "linker" — link errors are not compile errors.
- "memory leak" — only if memory is actually not freed.
- "deallocate" (Fortran) vs "nullify" vs "free" (C) — distinct operations.
- kind/precision claims must match the actual `KIND` parameter in the source.

## AI tells to never emit

(The `stop-slop` skill catches these; don't write them in the first place.)
- "It's important/worth noting that…", "In today's world…", "In this article
  we will…", "Let's dive in", "delve", "leverage" (as a verb for "use"),
  "robust", "seamless", "boasts", "in conclusion".
- Listicle padding, parallel-structure tics, em-dash as a verbal crutch.
- Hollow conclusions that restate the post without adding anything.

## Benchmarks and numbers

If you cite a measurement, state the conditions: hardware, compiler + version,
flags, problem size, how many runs. An unconditioned speedup number is noise.
Consumer-GPU FP64 caveats and timing discipline from the global GPU config
apply here too — a benchmark in a blog post is still a benchmark.

## The test

Before publishing, every sentence should survive: *"Is this true, and do we
know it's true?"* If a sentence is filler, cut it. If a claim is unverified,
verify it or qualify it honestly.
