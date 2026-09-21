system "l src/client/bin/masterClient.q";

.tst.desc["masterClient allow-list matches the players in lib/"]{
  should["every player strategy in lib/ is listed, spelled correctly, in masterClient.q's pt"]{
    onDisk:asc `$-2 _/: string (key `:src/client/lib) except `playerCore.q;  / strip ".q"
    (asc pt) mustmatch onDisk;
    };
 };

.tst.desc[".mc.dispatch"]{
  / a real IPC handle applied to (`func;arg) sends that single list as one sync
  / request, which the remote destructures as func[arg] - a unary mock of `h`
  / that does the same destructuring stands in for the real handle here
  should["forwards the given function name and argument to h as a single sync request"]{
    req::();
    `h mock {[fx] req::fx};
    .mc.dispatch[`stake;10];
    req mustmatch (`stake;10);
    };
  should["passes through whatever argument it's given, including no argument"]{
    req::();
    `h mock {[fx] req::fx};
    .mc.dispatch[`hit;::];
    req mustmatch (`hit;::);
    };
 };
