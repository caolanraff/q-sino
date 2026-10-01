.utl.load`:src/client/bin/player.q;

.tst.desc["player allow-list matches the players in lib/"]{
  should["every player strategy in lib/ is listed, spelled correctly, in player.q's .plr.pt"]{
    onDisk:asc`$-2_/:string key[`:src/client/lib]except`strategy.q;                              / strip ".q"
    asc[.plr.pt] mustmatch onDisk;
  };
 };

.tst.desc[".plr.dispatch"]{
  before{
    .tst.req:();
    `.plr.h mock {[fx].tst.req:fx};
  };
  should["forwards the given function name and argument to .plr.h as a single sync request"]{
    .plr.dispatch[`stake;10];
    .tst.req mustmatch(`stake;10);
  };
  should["passes through whatever argument it's given, including no argument"]{
    .plr.dispatch[`hit;::];
    .tst.req mustmatch(`hit;::);
  };
 };
