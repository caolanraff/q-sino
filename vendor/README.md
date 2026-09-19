# vendor

Third-party code vendored into the repo rather than pulled in at build/runtime.
Copied from [q-crypto](../../q-crypto)'s vendoring setup.

- `qspec`, `qutil` --> test framework and its dependency, used by [`test/run.q`](../test/run.q)
- `app` --> qspec runner configuration for this repo's test suite (not itself third-party, but wired directly into the qspec/qutil bootstrap)
- `kdb` --> the q runtime CI runs the test suite with (see [`.github/workflows/test.yml`](../.github/workflows/test.yml)); `licenses/` is gitignored and populated at CI runtime from a repo secret, not committed
