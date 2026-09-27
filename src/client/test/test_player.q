system"l src/client/bin/player.q";

.tst.desc["player allow-list matches the players in lib/"]{
  should["every player strategy in lib/ is listed, spelled correctly, in player.q's .plr.pt"]{
    onDisk:asc`$-2_/:string key[`:src/client/lib]except`strategy.q;                              / strip ".q"
    asc[.plr.pt] mustmatch onDisk;
  };
 };

.tst.desc[".plr.dispatch"]{
  should["forwards the given function name and argument to .plr.h as a single sync request"]{
    .tst.req:();
    `.plr.h mock {[fx].tst.req:fx};
    .plr.dispatch[`stake;10];
    .tst.req mustmatch(`stake;10);
  };
  should["passes through whatever argument it's given, including no argument"]{
    .tst.req:();
    `.plr.h mock {[fx].tst.req:fx};
    .plr.dispatch[`hit;::];
    .tst.req mustmatch(`hit;::);
  };
 };
