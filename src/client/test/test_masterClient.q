system "l src/client/bin/masterClient.q";

.tst.desc["masterClient allow-list matches the players in lib/"]{
  should["every player strategy in lib/ is listed, spelled correctly, in masterClient.q's .mc.pt"]{
    onDisk:asc `$-2 _/: string (key `:src/client/lib) except `playerCore.q;  / strip ".q"
    (asc .mc.pt) mustmatch onDisk;
    };
 };

.tst.desc[".mc.dispatch"]{
  should["forwards the given function name and argument to .mc.h as a single sync request"]{
    req::();
    `.mc.h mock {[fx] req::fx};
    .mc.dispatch[`stake;10];
    req mustmatch (`stake;10);
    };
  should["passes through whatever argument it's given, including no argument"]{
    req::();
    `.mc.h mock {[fx] req::fx};
    .mc.dispatch[`hit;::];
    req mustmatch (`hit;::);
    };
 };
