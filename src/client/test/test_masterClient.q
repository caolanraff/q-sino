system"l src/client/bin/masterClient.q";

.tst.desc["masterClient allow-list matches the players in lib/"]{
  should["every player strategy in lib/ is listed, spelled correctly, in masterClient.q's .mc.pt"]{
    onDisk:asc`$-2_/:string key[`:src/client/lib]except`playerCore.q;                              / strip ".q"
    asc[.mc.pt] mustmatch onDisk;
  };
 };

.tst.desc[".mc.dispatch"]{
  should["forwards the given function name and argument to .mc.h as a single sync request"]{
    .tst.req:();
    `.mc.h mock {[fx].tst.req:fx};
    .mc.dispatch[`stake;10];
    .tst.req mustmatch(`stake;10);
  };
  should["passes through whatever argument it's given, including no argument"]{
    .tst.req:();
    `.mc.h mock {[fx].tst.req:fx};
    .mc.dispatch[`hit;::];
    .tst.req mustmatch(`hit;::);
  };
 };
