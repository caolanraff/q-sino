/ Bootstraps vendored qutil + qspec and hands off to the qspec test runner.
/ Usage: q test/run.q <test file/dir>... -q
/ q-crypto's copy of this file resolves the repo root from a QCHOME env var
/ (set once in bin/env.sh); this repo has no such convention yet, so the root
/ is derived from this script's own path instead.
/ `system "cd ..."` would be intercepted as q's own \cd, not a shell command,
/ so this shells out to realpath/dirname instead (neither collides with a
/ built-in q system command).
root:first system "dirname $(dirname $(realpath ",(1_string hsym .z.f),"))";
vendor:hsym `$root,"/vendor";
.utl.QPATH:enlist vendor;
system "l ",(1_string vendor),"/qutil/bootstrap.q";
system "l ",(1_string vendor),"/app/spec.q";
