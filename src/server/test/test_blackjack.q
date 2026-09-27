system "l src/server/bin/blackjack.q";
.bjk.loadLibs[];

.tst.desc["blackjack entry-script guard"]{
  should["only fires for its own script, not when loaded as a dependency"]{
    guard::{[zf] (not null zf) and "blackjack.q"~last "/" vs string zf};
    (guard[`]) musteq 0b;
    (guard[`$"src/server/bin/blackjack.q"]) musteq 1b;
    (guard[`$"test/run.q"]) musteq 0b;
    (guard[`$"/abs/path/src/server/bin/blackjack.q"]) musteq 1b;
    };
 };

.tst.desc[".bjk.shuffle pitboss-notify guard"]{
  should["behaves as intended AND semantics"]{
    guard::{[shufflecnt;pit] (shufflecnt>1)&not null pit};
    threw:@[{guard[1;0Ni];0b};();{1b}];
    threw musteq 0b;
    (guard[1;0Ni]) musteq 0b;
    (guard[1;5i]) musteq 0b;
    (guard[2;5i]) musteq 1b;
    (guard[2;0Ni]) musteq 0b;
    };
 };

.tst.desc[".bjk.start player-table upsert"]{
  should["succeeds for exactly one connected player"]{
    .bjk.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!();
    .bjk.cp:enlist[5i]!enlist`alice;
    threw:@[{`.bjk.tab upsert ([]player:1+til count .bjk.cp;name:value .bjk.cp;handle:key .bjk.cp);0b};();{1b}];
    threw musteq 0b;
    (count .bjk.tab) musteq 1;
    };
  should["succeeds for two connected players"]{
    .bjk.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!();
    .bjk.cp:(5i;6i)!`alice`bob;
    threw:@[{`.bjk.tab upsert ([]player:1+til count .bjk.cp;name:value .bjk.cp;handle:key .bjk.cp);0b};();{1b}];
    threw musteq 0b;
    (count .bjk.tab) musteq 2;
    (asc exec name from .bjk.tab) musteq `alice`bob;
    };
 };

.tst.desc[".bjk.tab keeps a typed bet column"]{
  should["select ... where null bet doesn't throw before anyone has staked this round"]{
    .bjk.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    `.bjk.tab upsert ([]player:1 2f;name:`alice`bob;handle:10 11i);
    threw:@[{select from .bjk.tab where null bet;0b};();{1b}];
    threw musteq 0b;
    (count select from .bjk.tab where null bet) musteq 2;
    };
 };

.tst.desc["hist[]"]{
  should["returns .bjk.hist and .bjk.res concatenated"]{
    .bjk.hist:([]round:1 2);
    .bjk.res:([]round:enlist 3);
    (exec round from hist[]) musteq 1 2 3;
    };
 };

.tst.desc[".bjk.dealer1 dealer-and-player-both-bust branch"]{
  should["zeroes only the current player's return, leaving other players untouched"]{
    .bjk.tab:([]player:1 2f;name:`p1`p2;handle:10 11i;cnt:25 24i;return:250f,0n);
    DCount:24;  / dealer also busted (>21) in this scenario
    p:2f;
    ucnt:first exec cnt from .bjk.tab where player=p;
    if[DCount>21;
      $[ucnt<=21;
        [1];
        [update return:0f from `.bjk.tab where player=p]]];
    (exec first return from .bjk.tab where player=2) musteq 0f;
    (exec first return from .bjk.tab where player=1) musteq 250f;
    };
 };

.tst.desc["regConn"]{
  should["adds a plain connection to cp when isDA is false"]{
    .bjk.cp:()!(); .bjk.pit:0Ni;
    `.bjk.isPit mock {0b};
    .bjk.regConn[42i];
    (count .bjk.cp) musteq 1;
    .bjk.pit musteq 0Ni;
    };
  should["routes a pitboss connection to .bjk.pit instead of cp"]{
    .bjk.cp:()!(); .bjk.pit:0Ni;
    `.bjk.isPit mock {1b};
    .bjk.regConn[42i];
    .bjk.pit musteq 42i;
    (count .bjk.cp) musteq 0;
    };
 };

.tst.desc[".z.po"]{
  should["registers the connection and starts the table for a plain client"]{
    .bjk.cp:()!(); .bjk.pit:0Ni;
    regConnCalls::0; startCalls::0;
    `.bjk.regConn mock {regConnCalls::regConnCalls+1};
    `.bjk.isPit mock {0b};
    `.bjk.start mock {startCalls::startCalls+1};
    .z.po[];
    regConnCalls musteq 1;
    startCalls musteq 1;
    };
  should["skips .bjk.start for a pitboss connection"]{
    startCalls::0;
    `.bjk.regConn mock {};
    `.bjk.isPit mock {1b};
    `.bjk.start mock {startCalls::startCalls+1};
    .z.po[];
    startCalls musteq 0;
    };
 };

.tst.desc["leave removes the disconnecting handle from cp"]{
  should["drops only the disconnecting handle's key, leaving other connected players untouched"]{
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!();
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(); .bjk.hist:.bjk.res;
    .bjk.hd:1b;
    .bjk.leave[5i];
    .bjk.cp musteq enlist[6i]!enlist`bob;
    };
 };

.tst.desc[".bjk.leave mid-hand"]{
  should["passes the turn to the next player's hand when the leaver held it"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    excFuncCalls::();
    `.bjk.excFunc mock {[x;y;z] excFuncCalls,:enlist(x;z)};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(); .bjk.hist:.bjk.res;
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.hd:0b;
    .bjk.tab:update out:00b,wait:00b,turn:10b from ([]round:1 1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10;return:0n 0n;profit:0n 0n;split:00b;double:00b;insurance:0f);
    .bjk.leave[5i];
    (exec handle from .bjk.tab) musteq enlist 6i;
    (exec first turn from .bjk.tab) musteq 1b;
    excFuncCalls mustmatch enlist(`.plr.play;6i);
    };
  should["runs the dealer when the leaver was the last player still to act"]{
    `.bjk.pubMsg mock {[x;y]};
    dealerCalls::0;
    `.bjk.dealer mock {dealerCalls+::1};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(); .bjk.hist:.bjk.res;
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.hd:0b;
    .bjk.tab:update out:00b,wait:10b,turn:01b from ([]round:1 1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10;return:0n 0n;profit:0n 0n;split:00b;double:00b;insurance:0f);
    .bjk.leave[6i];
    dealerCalls musteq 1;
    };
  should["leaves the turn with its holder when someone else leaves"]{
    `.bjk.pubMsg mock {[x;y]};
    nextTurnCalls::0;
    `.bjk.nextTurn mock {nextTurnCalls+::1};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(); .bjk.hist:.bjk.res;
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.hd:0b;
    .bjk.tab:update out:00b,wait:00b,turn:10b from ([]round:1 1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10;return:0n 0n;profit:0n 0n;split:00b;double:00b;insurance:0f);
    .bjk.leave[6i];
    (exec handle from .bjk.tab where turn) musteq enlist 5i;
    nextTurnCalls musteq 0;
    };
  should["removes every split hand belonging to the leaver"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.nextTurn mock {};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(); .bjk.hist:.bjk.res;
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.hd:0b;
    .bjk.tab:([]round:1 1 1;player:1 2.01 2.02;name:`alice`bob`bob;handle:5 6 6i;cards:(`8`8;`9`3;`9`4);cnt:16 12 13i;dealer:3#`5;dealerCnt:5 5 5i;bet:10 10 10;return:3#0n;profit:3#0n;split:011b;double:000b;insurance:0f);
    .bjk.tab:update out:000b,wait:000b,turn:100b from .bjk.tab;
    .bjk.leave[6i];
    (exec handle from .bjk.tab) musteq enlist 5i;
    };
 };

.tst.desc[".bjk.leave between hands"]{
  should["deals when the leaver was the only seated player yet to bet"]{
    `.bjk.pubMsg mock {[x;y]};
    dealCalls::0;
    `.bjk.deal mock {dealCalls+::1};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(); .bjk.hist:.bjk.res;
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.hd:1b;
    .bjk.stake:([name:enlist`alice;handle:enlist 5i]bet:enlist 10);
    .bjk.tab:update bet:10 0N from ([]round:1 1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10;return:0n 0n;profit:0n 0n;split:00b;double:00b;insurance:0f);
    .bjk.leave[6i];
    dealCalls musteq 1;
    };
  should["doesn't deal while another remaining player still hasn't bet"]{
    `.bjk.pubMsg mock {[x;y]};
    dealCalls::0;
    `.bjk.deal mock {dealCalls+::1};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(); .bjk.hist:.bjk.res;
    .bjk.cp:(5i;6i;7i)!`alice`bob`carol;
    .bjk.hd:1b;
    .bjk.stake:([name:enlist`alice;handle:enlist 5i]bet:enlist 10);
    .bjk.tab:([]round:1 1 1;player:1 2 3f;name:`alice`bob`carol;handle:5 6 7i;cards:3#enlist();cnt:3#0Ni;dealer:3#`;dealerCnt:3#0Ni;bet:10 0N 0N;return:3#0n;profit:3#0n;split:000b;double:000b;insurance:0f);
    .bjk.leave[6i];
    dealCalls musteq 0;
    };
  should["drops the leaver's pending bet"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.deal mock {};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(); .bjk.hist:.bjk.res;
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.hd:1b;
    .bjk.stake:([name:`alice`bob;handle:5 6i]bet:10 20);
    .bjk.tab:([]round:1 1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10;return:0n 0n;profit:0n 0n;split:00b;double:00b;insurance:0f);
    .bjk.leave[6i];
    (exec handle from .bjk.stake) musteq enlist 5i;
    };
 };

.tst.desc[".bjk.start"]{
  should["keeps bets already placed when a player joins mid-betting, and only prompts players yet to bet"]{
    `.bjk.sendMsg mock {[x;y]};
    excFuncCalls::();
    `.bjk.excFunc mock {[x;y;z] excFuncCalls,:enlist(x;z)};
    .bjk.hd:1b;
    .bjk.cp:(5i;6i;7i)!`alice`bob`carol;
    .bjk.stake:([name:enlist`alice;handle:enlist 5i]bet:enlist 10);
    .bjk.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bjk.start[];
    (exec bet from .bjk.tab where handle=5i) musteq enlist 10;
    (exec handle from .bjk.tab where null bet) musteq 6 7i;
    excFuncCalls mustmatch ((`.plr.stake;6i);(`.plr.stake;7i));
    };
  should["prompts every player when nobody has bet yet"]{
    `.bjk.sendMsg mock {[x;y]};
    excFuncCalls::();
    `.bjk.excFunc mock {[x;y;z] excFuncCalls,:enlist(x;z)};
    .bjk.hd:1b;
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.stake:([name:();handle:()]bet:());
    .bjk.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bjk.start[];
    excFuncCalls mustmatch ((`.plr.stake;5i);(`.plr.stake;6i));
    };
 };

.tst.desc[".z.pc"]{
  should["resets .bjk.pit to null for the pitboss handle, without calling leave"]{
    .bjk.pit:7i;
    leaveCalls::0;
    `.bjk.leave mock {leaveCalls::leaveCalls+1};
    .z.pc[7i];
    .bjk.pit musteq 0Ni;
    leaveCalls musteq 0;
    };
  should["calls leave for a non-pitboss disconnect, leaving .bjk.pit untouched"]{
    .bjk.pit:7i;
    leaveArg::0Ni;
    `.bjk.leave mock {leaveArg::x};
    .z.pc[3i];
    .bjk.pit musteq 7i;
    leaveArg musteq 3i;
    };
 };

.tst.desc[".bjk.leave winnings message"]{
  should["reports net winnings across every shoe this session, ignoring other players"]{
    msgs::();
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.lg mock {[x] msgs,:enlist raze x};
    `.bjk.pubMsg mock {[x;y]};
    .bjk.hd:1b;
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.joined:(5 6i)!0 0;
    .bjk.hist:([]round:1 1;handle:5 6i;profit:10 50f);
    .bjk.res:([]round:2 3 3;handle:5 5 6i;profit:-5 15 -50f);
    .bjk.tab:([]round:0#0;player:0#0f;name:0#`;handle:0#0i;bet:0#0);
    .bjk.leave[5i];
    (any msgs like "*net winnings this session $20.00") musteq 1b;
    };
  should["shows a net loss with a leading minus sign"]{
    msgs::();
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.lg mock {[x] msgs,:enlist raze x};
    `.bjk.pubMsg mock {[x;y]};
    .bjk.hd:1b;
    .bjk.cp:enlist[5i]!enlist`alice;
    .bjk.joined:enlist[5i]!enlist 0;
    .bjk.hist:([]round:0#0;handle:0#0i;profit:0#0f);
    .bjk.res:([]round:1 2;handle:5 5i;profit:-10 -2.5);
    .bjk.tab:([]round:0#0;player:0#0f;name:0#`;handle:0#0i;bet:0#0);
    .bjk.leave[5i];
    (any msgs like "*net winnings this session -$12.50") musteq 1b;
    };
  should["ignores results from an earlier connection that had the same handle"]{
    msgs::();
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.lg mock {[x] msgs,:enlist raze x};
    `.bjk.pubMsg mock {[x;y]};
    .bjk.hd:1b;
    .bjk.cp:enlist[5i]!enlist`alice;
    .bjk.joined:enlist[5i]!enlist 2;  / this session joined after round 2
    .bjk.hist:([]round:1 2;handle:5 5i;profit:100 100f);
    .bjk.res:([]round:enlist 3;handle:enlist 5i;profit:enlist 10f);
    .bjk.tab:([]round:0#0;player:0#0f;name:0#`;handle:0#0i;bet:0#0);
    .bjk.leave[5i];
    (any msgs like "*net winnings this session $10.00") musteq 1b;
    };
  should["reports zero for a player who never finished a hand"]{
    msgs::();
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.lg mock {[x] msgs,:enlist raze x};
    `.bjk.pubMsg mock {[x;y]};
    .bjk.hd:1b;
    .bjk.cp:enlist[5i]!enlist`alice;
    .bjk.joined:enlist[5i]!enlist 0;
    .bjk.hist:.bjk.res:([]round:0#0;handle:0#0i;profit:0#0f);
    .bjk.tab:([]round:0#0;player:0#0f;name:0#`;handle:0#0i;bet:0#0);
    .bjk.leave[5i];
    (any msgs like "*net winnings this session $0.00") musteq 1b;
    };
  should["forgets the session's join round"]{
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.pubMsg mock {[x;y]};
    .bjk.hd:1b;
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.joined:(5 6i)!0 3;
    .bjk.hist:.bjk.res:([]round:0#0;handle:0#0i;profit:0#0f);
    .bjk.tab:([]round:0#0;player:0#0f;name:0#`;handle:0#0i;bet:0#0);
    .bjk.leave[5i];
    .bjk.joined musteq enlist[6i]!enlist 3;
    };
 };

.tst.desc["regConn join round"]{
  should["records the current round against a plain connection's handle"]{
    .bjk.cp:()!(); .bjk.pit:0Ni; .bjk.joined:(`int$())!`long$();
    `.bjk.isPit mock {0b};
    .bjk.rnd:7;
    .bjk.regConn[42i];
    .bjk.joined[42i] musteq 7;
    };
  should["doesn't record a pitboss connection"]{
    .bjk.cp:()!(); .bjk.pit:0Ni; .bjk.joined:(`int$())!`long$();
    `.bjk.isPit mock {1b};
    .bjk.regConn[42i];
    (count .bjk.joined) musteq 0;
    };
 };

.tst.desc[".z.ts"]{
  should["drives the betting clock"]{
    timerCalls::0;
    `.bjk.betTimer mock {timerCalls+::1};
    .z.ts[.z.p];
    timerCalls musteq 1;
    };
 };

.tst.desc[".bjk.leave records a mid-hand leaver's hands"]{
  should["records an unfinished hand as a loss of its bet"]{
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.nextTurn mock {};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();()); .bjk.hist:0#.bjk.res;
    .bjk.hd:0b;
    .bjk.cp:(5i;6i)!`alice`bob; .bjk.joined:(5 6i)!0 0;
    .bjk.tab:([]round:3 3;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`K`6;`9`7);cnt:16 16i;dealer:`9`9;dealerCnt:9 9i;bet:10 10;return:(();());profit:0n 0n;split:00b;double:00b;insurance:0f);
    .bjk.tab:update out:00b,wait:00b,turn:01b from .bjk.tab;
    .bjk.leave[5i];
    (exec handle from .bjk.res) musteq enlist 5i;
    (exec return from .bjk.res) musteq enlist 0f;
    (exec profit from .bjk.res) musteq enlist -10f;
    (exec round from .bjk.res) musteq enlist 3;
    (exec first dealer from .bjk.res) mustmatch enlist`9;
    };
  should["keeps the result of a hand that was already settled, like a paid blackjack"]{
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.nextTurn mock {};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();()); .bjk.hist:0#.bjk.res;
    .bjk.hd:0b;
    .bjk.cp:(5i;6i)!`alice`bob; .bjk.joined:(5 6i)!0 0;
    .bjk.tab:([]round:3 3;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`A`K;`9`7);cnt:21 16i;dealer:`9`9;dealerCnt:9 9i;bet:10 10;return:(25f;());profit:0n 0n;split:00b;double:00b;insurance:0f);
    .bjk.tab:update out:10b,wait:00b,turn:01b from .bjk.tab;
    .bjk.leave[5i];
    (exec profit from .bjk.res) musteq enlist 15f;
    };
  should["records every split hand, forfeiting a doubled stake in full"]{
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.nextTurn mock {};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();()); .bjk.hist:0#.bjk.res;
    .bjk.hd:0b;
    .bjk.cp:(5i;6i)!`alice`bob; .bjk.joined:(5 6i)!0 0;
    .bjk.tab:([]round:3 3 3;player:1.01 1.02 2;name:`alice`alice`bob;handle:5 5 6i;cards:(`8`3`K;`8`K`5;`9`7);cnt:21 23 16i;dealer:`9`9`9;dealerCnt:9 9 9i;bet:20 10 10;return:(();0f;());profit:3#0n;split:110b;double:100b;insurance:0f);
    .bjk.tab:update out:010b,wait:100b,turn:001b from .bjk.tab;
    .bjk.leave[5i];
    (exec player from .bjk.res) musteq 1 1;
    (exec profit from .bjk.res) musteq -20 -10f;
    };
  should["counts the forfeited hand in the leaver's session winnings"]{
    msgs::();
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.lg mock {[x] msgs,:enlist raze x};
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.nextTurn mock {};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();()); .bjk.hist:0#.bjk.res;
    .bjk.res:([]round:enlist 1;player:enlist 1;name:enlist`alice;handle:enlist 5i;cards:enlist`K`9;cnt:enlist 19i;dealer:enlist`K`8;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 25f;profit:enlist 15f;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.hd:0b;
    .bjk.cp:(5i;6i)!`alice`bob; .bjk.joined:(5 6i)!0 0;
    .bjk.tab:([]round:2 2;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`K`6;`9`7);cnt:16 16i;dealer:`9`9;dealerCnt:9 9i;bet:10 10;return:(();());profit:0n 0n;split:00b;double:00b;insurance:0f);
    .bjk.tab:update out:00b,wait:00b,turn:01b from .bjk.tab;
    .bjk.leave[5i];
    (any msgs like "*net winnings this session $5.00") musteq 1b;
    };
  should["records nothing for a player who leaves between hands"]{
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.deal mock {};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();()); .bjk.hist:0#.bjk.res;
    .bjk.hd:1b;
    .bjk.cp:(5i;6i)!`alice`bob; .bjk.joined:(5 6i)!0 0;
    .bjk.stake:([name:enlist`alice;handle:enlist 5i]bet:enlist 10);
    .bjk.tab:([]round:0N 0N;player:1 2f;name:`alice`bob;handle:5 6i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:10 0N;return:(();());profit:0n 0n;split:00b;double:00b;insurance:0f);
    .bjk.leave[5i];
    (count .bjk.res) musteq 0;
    };
 };

.tst.desc[".bjk.start stake trigger"]{
  should["pushes each unbet player their own state with .plr.stake"]{
    `.bjk.sendMsg mock {[x;y]};
    sent::();
    `.bjk.excFunc mock {[x;y;z] sent,:enlist(x;y;z)};
    .bjk.hd:1b;
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.stake:([name:();handle:()]bet:());
    .bjk.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bjk.start[];
    (sent[;0]) mustmatch `.plr.stake`.plr.stake;
    ({x[1]`me} each sent) musteq 5 6i;
    ({x[1]`tab} each sent) mustmatch 2#enlist .bjk.tab;
    };
 };

.tst.desc[".bjk.leave during insurance"]{
  should["closes insurance when the last player yet to answer leaves"]{
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.pubMsg mock {[x;y]};
    closeCalls::0;
    `.bjk.closeInsurance mock {closeCalls+::1};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();()); .bjk.hist:0#.bjk.res;
    .bjk.hd:0b; .bjk.insuring:1b;
    .bjk.cp:(5i;6i)!`alice`bob; .bjk.joined:(5 6i)!0 0;
    .bjk.tab:([]round:1 1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`9`7;`10`8);cnt:16 18i;dealer:2#`A;dealerCnt:11 11i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:5 0n);
    .bjk.tab:update out:00b,wait:00b,turn:00b from .bjk.tab;
    .bjk.leave[6i];
    closeCalls musteq 1;
    .bjk.insuring:0b;
    };
  should["records a leaver's insurance as lost along with their bet"]{
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.closeInsurance mock {};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();()); .bjk.hist:0#.bjk.res;
    .bjk.hd:0b; .bjk.insuring:1b;
    .bjk.cp:(5i;6i)!`alice`bob; .bjk.joined:(5 6i)!0 0;
    .bjk.tab:([]round:1 1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`9`7;`10`8);cnt:16 18i;dealer:2#`A;dealerCnt:11 11i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:5 0n);
    .bjk.tab:update out:00b,wait:00b,turn:00b from .bjk.tab;
    .bjk.leave[5i];
    (exec profit from .bjk.res) musteq enlist -15f;
    .bjk.insuring:0b;
    };
 };

.tst.desc[".z.ts insurance"]{
  should["drives the insurance window as well as the betting clock"]{
    betCalls::0; insCalls::0;
    `.bjk.betTimer mock {betCalls+::1};
    `.bjk.insureTimer mock {insCalls+::1};
    .z.ts[.z.p];
    (betCalls,insCalls) musteq 1 1;
    };
 };

.tst.desc[".bjk.start mid-hand"]{
  should["tells the connection that just arrived to wait for the hand to finish"]{
    sent::();
    `.bjk.sendMsg mock {[x;y] sent,:enlist(x;y)};
    .bjk.hd:0b;
    .bjk.start[];
    sent mustmatch enlist("Please wait until the hand is over";.z.w);
    .bjk.hd:1b;
    };
 };
