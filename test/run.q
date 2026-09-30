/ Bootstraps vendored qutil + qspec and hands off to the qspec test runner.
/ Usage: q test/run.q <test file/dir>... -q
/ q-crypto's copy of this file resolves the repo root from a QCHOME env var
/ (set once in bin/env.sh); this repo has no such convention yet, so the root
/ is derived from this script's own path instead.
/ `system "cd ..."` would be intercepted as q's own \cd, not a shell command,
/ so this shells out to realpath/dirname instead (neither collides with a
/ built-in q system command).
root:first system "dirname $(dirname $(realpath ",(1_string hsym .z.f),"))";

/ blackjack.q and player.q both define root-scope stake/hit/
/ stick/double/split/shuffle/buildDeck/hist with different meanings; a single
/ spec.q run loads every given test path's dependencies into one process, so
/ passing both src/server/test and src/client/test together would let
/ whichever bin file loads second silently clobber the other's. Each given
/ path therefore gets its own q subprocess instead.
/ A parent q process can't reliably read a q child's real exit code back
/ through system() - confirmed empirically that a child script's `exit 1`
/ does not surface the way a plain failed shell command does (system()
/ signals 'os for `sh -c "...; exit 1"` but not for `sh -c "q child.q"`
/ where child.q itself calls exit 1). Pass/fail is relayed through a result
/ file instead: the QSINO_TEST_RESULT env var tells a worker sub-invocation
/ where to write PASS/FAIL once spec.q finishes (forced into --noquit mode
/ so it returns control here instead of exiting on its own), and the
/ dispatch branch below reads that file back rather than trusting system()'s
/ own success/failure signal.
args:.z.x;
paths:args where not args like "-*";
flags:args where args like "-*";

if[1<count paths;
  ok:1b;
  {[root;flags;p]
    f:"/tmp/qsino_test_result_",(string .z.p),"_",ssr[p;"/";"_"],".tmp";
    / a worker that errors uncaught (as opposed to a clean exit) does make
    / system() signal 'os here, unlike a clean exit - trap it too, since the
    / result file (checked next either way) is the real source of truth. A
    / nested q child's own console output isn't reliably visible through
    / system() in this environment, so the worker relays a short summary
    / through the same file instead of relying on that passthrough.
    @[system;"QSINO_TEST_RESULT='",f,"' q ",root,"/test/run.q ",p," ",(" " sv flags)," --noquit";{}];
    lns:@[read0;hsym `$f;{enlist "FAIL"}];
    if[not "PASS"~first lns;ok::0b];
    -1 p,":";
    -1 each 1_lns;
    @[hdel;hsym `$f;{}];
    }[root;flags] each paths;
  exit `int$not ok;
  ];

/ worker mode: relay the real result to the file named by QSINO_TEST_RESULT
/ instead of letting spec.q exit on its own
resultFile:getenv `QSINO_TEST_RESULT;
if[count resultFile;.z.x,:enlist "--noquit"];

vendor:hsym `$root,"/vendor";
.utl.QPATH:(vendor;hsym`$root,"/src");
system "l ",(1_string vendor),"/qutil/bootstrap.q";
system "l ",(1_string vendor),"/app/spec.q";

if[count resultFile;
  (hsym `$resultFile) 0: ($[.tst.app.passed;"PASS";"FAIL"];
    "For ",string[count .tst.app.specs]," specifications, ",string[.tst.app.expectationsRan]," expectations were run.";
    string[.tst.app.expectationsPassed]," passed, ",string[.tst.app.expectationsFailed]," failed.  ",string[.tst.app.expectationsErrored]," errors.");
  exit `int$not .tst.app.passed;
  ];
