# vendor

Third-party code vendored into the repo rather than pulled in at build/runtime.

- `qspec`, `qutil` --> test framework and its dependency, used by [`test/run.q`](../test/run.q)
- `app` --> qspec runner configuration for this repo's test suite (not itself third-party, but wired directly into the qspec/qutil bootstrap)
- `qprof` --> line-level q code profiler ([LeslieGoldsmith/qprof](https://github.com/LeslieGoldsmith/qprof)
  @ `4d48be2`), not wired into anything - load it by hand (`system "l vendor/qprof/prof.q"`)
  when you want to profile something. `code.kx.com`'s own built-in profiler (`.Q.prf0`) is
  Linux-only and unusable on macOS, which is why this is vendored instead. Usage:
  `` .prof.prof[`] `` to start profiling everything, run the code you want measured, then
  `` .prof.report[`] `` for a line-by-line report (see `qprof/README.md` upstream, or
  `prof.q`'s own header, for the full API).
