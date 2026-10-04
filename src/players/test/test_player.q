.utl.load`:src/players/bin/player.q;

.tst.desc["player allow-list matches the players in lib/"]{
  should["every player strategy in lib/ is listed, spelled correctly, in player.q's .plr.pt"]{
    onDisk:asc`$-2_/:string key[`:src/players/lib]except`strategy.q;                              / strip ".q"
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

.tst.desc[".plr.goodbye"]{
  before{.plr.state:()!()};
  should["just thanks a player who never bought in"]{
    .plr.goodbye[] mustmatch "Thanks for playing q-sino blackjack!";
    };
  should["says what the player leaves with, and their return"]{
    t:([]handle:7 8i;bet:0N;insurance:0n);
    .plr.state:`tab`me`chips`bought!(t;7i;1020f;1000f);
    .plr.goodbye[] mustmatch "Thanks for playing q-sino blackjack! You leave with $1020.00 in chips, up $20.00";
    .plr.state:`tab`me`chips`bought!(t;7i;950f;1100f);
    .plr.goodbye[] mustmatch "Thanks for playing q-sino blackjack! You leave with $950.00 in chips, down $150.00";
    };
  should["takes off bets still on the table, which leaving mid-hand forfeits"]{
    t:([]handle:7 8i;bet:20 10;insurance:5 0f);
    .plr.state:`tab`me`chips`bought!(t;7i;1000f;1000f);
    .plr.goodbye[] mustmatch "Thanks for playing q-sino blackjack! You leave with $975.00 in chips, down $25.00";
    };
 };

.tst.desc[".plr.stake manual"]{
  should["keeps the state the server pushes"]{
    .utl.load`:src/players/bin/player.q;
    .plr.stake`tab`me`chips`bought!(();7i;1000f;1000f);
    .plr.state[`chips] musteq 1000f;
    };
 };
