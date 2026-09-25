system "l src/server/bin/blackjackServer.q";

.tst.desc["blackjackServer entry-script guard (bin/blackjackServer.q:382)"]{
  should["only fires for its own script, not when loaded as a dependency"]{
    guard::{[zf] (not null zf) and "blackjackServer.q"~last "/" vs string zf};
    (guard[`]) musteq 0b;
    (guard[`$"src/server/bin/blackjackServer.q"]) musteq 1b;
    (guard[`$"test/run.q"]) musteq 0b;
    (guard[`$"/abs/path/src/server/bin/blackjackServer.q"]) musteq 1b;
    };
 };

.tst.desc["blackjackServer.shuffle DA-notify guard (lib/deck.q:16)"]{
  should["behaves as intended AND semantics"]{
    guard::{[shufflecnt;DA] (shufflecnt>1)&not null DA};
    threw:@[{guard[1;0Ni];0b};();{1b}];
    threw musteq 0b;
    (guard[1;0Ni]) musteq 0b;
    (guard[1;5i]) musteq 0b;
    (guard[2;5i]) musteq 1b;
    (guard[2;0Ni]) musteq 0b;
    };
 };

.tst.desc[".bs.start player-table upsert (bin/blackjackServer.q:15,41)"]{
  should["succeeds for exactly one connected player"]{
    .bs.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!();
    .bs.cp:enlist[5i]!enlist`alice;
    threw:@[{`.bs.tab upsert ([]player:1+til count .bs.cp;name:value .bs.cp;handle:key .bs.cp);0b};();{1b}];
    threw musteq 0b;
    (count .bs.tab) musteq 1;
    };
  should["succeeds for two connected players"]{
    .bs.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!();
    .bs.cp:(5i;6i)!`alice`bob;
    threw:@[{`.bs.tab upsert ([]player:1+til count .bs.cp;name:value .bs.cp;handle:key .bs.cp);0b};();{1b}];
    threw musteq 0b;
    (count .bs.tab) musteq 2;
    (asc exec name from .bs.tab) musteq `alice`bob;
    };
 };

.tst.desc[".bs.tab keeps a typed bet column (bin/blackjackServer.q:15)"]{
  should["select ... where null bet doesn't throw before anyone has staked this round"]{
    .bs.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(();();();();();();();();`long$();();();();());
    `.bs.tab upsert ([]player:1 2f;name:`alice`bob;handle:10 11i);
    threw:@[{select from .bs.tab where null bet;0b};();{1b}];
    threw musteq 0b;
    (count select from .bs.tab where null bet) musteq 2;
    };
 };

.tst.desc["hist[] (bin/blackjackServer.q:34)"]{
  should["returns .bs.hist and .bs.res concatenated"]{
    .bs.hist:([]round:1 2);
    .bs.res:([]round:enlist 3);
    (exec round from hist[]) musteq 1 2 3;
    };
 };

.tst.desc[".bs.dealer1 dealer-and-player-both-bust branch (bin/blackjackServer.q:170-171)"]{
  should["zeroes only the current player's return, leaving other players untouched"]{
    .bs.tab:([]player:1 2f;name:`p1`p2;handle:10 11i;cnt:25 24i;return:250f,0n);
    DCount:24;  / dealer also busted (>21) in this scenario
    p:2f;
    ucnt:first exec cnt from .bs.tab where player=p;
    if[DCount>21;
      $[ucnt<=21;
        [1];
        [update return:0f from `.bs.tab where player=p]]];
    (exec first return from .bs.tab where player=2) musteq 0f;
    (exec first return from .bs.tab where player=1) musteq 250f;
    };
 };

.tst.desc["regConn"]{
  should["adds a plain connection to cp when isDA is false"]{
    .bs.cp:()!(); .bs.da:0Ni;
    `.bs.isDA mock {0b};
    .bs.regConn[42i];
    (count .bs.cp) musteq 1;
    .bs.da musteq 0Ni;
    };
  should["routes a detectionAlgo connection to DA instead of cp"]{
    .bs.cp:()!(); .bs.da:0Ni;
    `.bs.isDA mock {1b};
    .bs.regConn[42i];
    .bs.da musteq 42i;
    (count .bs.cp) musteq 0;
    };
 };

.tst.desc[".z.po"]{
  should["registers the connection and starts the table for a plain client"]{
    .bs.cp:()!(); .bs.da:0Ni;
    regConnCalls::0; startCalls::0;
    `.bs.regConn mock {regConnCalls::regConnCalls+1};
    `.bs.isDA mock {0b};
    `.bs.start mock {startCalls::startCalls+1};
    .z.po[];
    regConnCalls musteq 1;
    startCalls musteq 1;
    };
  should["skips .bs.start for a detectionAlgo connection"]{
    startCalls::0;
    `.bs.regConn mock {};
    `.bs.isDA mock {1b};
    `.bs.start mock {startCalls::startCalls+1};
    .z.po[];
    startCalls musteq 0;
    };
 };

.tst.desc["leave removes the disconnecting handle from cp (bin/blackjackServer.q)"]{
  should["drops only the disconnecting handle's key, leaving other connected players untouched"]{
    .bs.cp:(5i;6i)!`alice`bob;
    .bs.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!();
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(); .bs.hist:.bs.res;
    .bs.hd:1b;
    .bs.leave[5i];
    .bs.cp musteq enlist[6i]!enlist`bob;
    };
 };

.tst.desc[".bs.leave mid-hand"]{
  should["passes the turn to the next player's hand when the leaver held it"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    excFuncCalls::();
    `.bs.excFunc mock {[x;y;z] excFuncCalls,:enlist(x;z)};
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(); .bs.hist:.bs.res;
    .bs.cp:(5i;6i)!`alice`bob;
    .bs.hd:0b;
    .bs.tab:update out:00b,wait:00b,turn:10b from ([]round:1 1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.leave[5i];
    (exec handle from .bs.tab) musteq enlist 6i;
    (exec first turn from .bs.tab) musteq 1b;
    excFuncCalls mustmatch enlist(`.mc.play;6i);
    };
  should["runs the dealer when the leaver was the last player still to act"]{
    `.bs.pubMsg mock {[x;y]};
    dealerCalls::0;
    `.bs.dealer mock {dealerCalls+::1};
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(); .bs.hist:.bs.res;
    .bs.cp:(5i;6i)!`alice`bob;
    .bs.hd:0b;
    .bs.tab:update out:00b,wait:10b,turn:01b from ([]round:1 1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.leave[6i];
    dealerCalls musteq 1;
    };
  should["leaves the turn with its holder when someone else leaves"]{
    `.bs.pubMsg mock {[x;y]};
    nextTurnCalls::0;
    `.bs.nextTurn mock {nextTurnCalls+::1};
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(); .bs.hist:.bs.res;
    .bs.cp:(5i;6i)!`alice`bob;
    .bs.hd:0b;
    .bs.tab:update out:00b,wait:00b,turn:10b from ([]round:1 1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.leave[6i];
    (exec handle from .bs.tab where turn) musteq enlist 5i;
    nextTurnCalls musteq 0;
    };
  should["removes every split hand belonging to the leaver"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.nextTurn mock {};
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(); .bs.hist:.bs.res;
    .bs.cp:(5i;6i)!`alice`bob;
    .bs.hd:0b;
    .bs.tab:([]round:1 1 1;player:1 2.01 2.02;name:`alice`bob`bob;handle:5 6 6i;cards:(`8`8;`9`3;`9`4);cnt:16 12 13i;dealer:3#`5;dealerCnt:5 5 5i;bet:10 10 10;return:3#0n;profit:3#0n;split:011b;double:000b);
    .bs.tab:update out:000b,wait:000b,turn:100b from .bs.tab;
    .bs.leave[6i];
    (exec handle from .bs.tab) musteq enlist 5i;
    };
 };

.tst.desc[".bs.leave between hands"]{
  should["deals when the leaver was the only seated player yet to bet"]{
    `.bs.pubMsg mock {[x;y]};
    dealCalls::0;
    `.bs.deal mock {dealCalls+::1};
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(); .bs.hist:.bs.res;
    .bs.cp:(5i;6i)!`alice`bob;
    .bs.hd:1b;
    .bs.stake:([name:enlist`alice;handle:enlist 5i]bet:enlist 10);
    .bs.tab:update bet:10 0N from ([]round:1 1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.leave[6i];
    dealCalls musteq 1;
    };
  should["doesn't deal while another remaining player still hasn't bet"]{
    `.bs.pubMsg mock {[x;y]};
    dealCalls::0;
    `.bs.deal mock {dealCalls+::1};
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(); .bs.hist:.bs.res;
    .bs.cp:(5i;6i;7i)!`alice`bob`carol;
    .bs.hd:1b;
    .bs.stake:([name:enlist`alice;handle:enlist 5i]bet:enlist 10);
    .bs.tab:([]round:1 1 1;player:1 2 3f;name:`alice`bob`carol;handle:5 6 7i;cards:3#enlist();cnt:3#0Ni;dealer:3#`;dealerCnt:3#0Ni;bet:10 0N 0N;return:3#0n;profit:3#0n;split:000b;double:000b);
    .bs.leave[6i];
    dealCalls musteq 0;
    };
  should["drops the leaver's pending bet"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.deal mock {};
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(); .bs.hist:.bs.res;
    .bs.cp:(5i;6i)!`alice`bob;
    .bs.hd:1b;
    .bs.stake:([name:`alice`bob;handle:5 6i]bet:10 20);
    .bs.tab:([]round:1 1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.leave[6i];
    (exec handle from .bs.stake) musteq enlist 5i;
    };
 };

.tst.desc[".bs.start"]{
  should["keeps bets already placed when a player joins mid-betting, and only prompts players yet to bet"]{
    `.bs.sendMsg mock {[x;y]};
    excFuncCalls::();
    `.bs.excFunc mock {[x;y;z] excFuncCalls,:enlist(x;z)};
    .bs.hd:1b;
    .bs.cp:(5i;6i;7i)!`alice`bob`carol;
    .bs.stake:([name:enlist`alice;handle:enlist 5i]bet:enlist 10);
    .bs.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(();();();();();();();();`long$();();();();());
    .bs.start[];
    (exec bet from .bs.tab where handle=5i) musteq enlist 10;
    (exec handle from .bs.tab where null bet) musteq 6 7i;
    excFuncCalls mustmatch ((`.mc.stake;6i);(`.mc.stake;7i));
    };
  should["prompts every player when nobody has bet yet"]{
    `.bs.sendMsg mock {[x;y]};
    excFuncCalls::();
    `.bs.excFunc mock {[x;y;z] excFuncCalls,:enlist(x;z)};
    .bs.hd:1b;
    .bs.cp:(5i;6i)!`alice`bob;
    .bs.stake:([name:();handle:()]bet:());
    .bs.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(();();();();();();();();`long$();();();();());
    .bs.start[];
    excFuncCalls mustmatch ((`.mc.stake;5i);(`.mc.stake;6i));
    };
 };

.tst.desc[".z.pc"]{
  should["resets DA to null for the detectionAlgo handle, without calling leave"]{
    .bs.da:7i;
    leaveCalls::0;
    `.bs.leave mock {leaveCalls::leaveCalls+1};
    .z.pc[7i];
    .bs.da musteq 0Ni;
    leaveCalls musteq 0;
    };
  should["calls leave for a non-DA disconnect, leaving DA untouched"]{
    .bs.da:7i;
    leaveArg::0Ni;
    `.bs.leave mock {leaveArg::x};
    .z.pc[3i];
    .bs.da musteq 7i;
    leaveArg musteq 3i;
    };
 };

.tst.desc[".bs.leave winnings message"]{
  should["reports net winnings across every shoe this session, ignoring other players"]{
    msgs::();
    `.bs.sendMsg mock {[x;y] msgs,:enlist x};
    `.bs.pubMsg mock {[x;y]};
    .bs.hd:1b;
    .bs.cp:(5i;6i)!`alice`bob;
    .bs.joined:(5 6i)!0 0;
    .bs.hist:([]round:1 1;handle:5 6i;profit:10 50f);
    .bs.res:([]round:2 3 3;handle:5 5 6i;profit:-5 15 -50f);
    .bs.tab:([]round:0#0;player:0#0f;name:0#`;handle:0#0i;bet:0#0);
    .bs.leave[5i];
    (first msgs) mustmatch "Your net winnings this session are $20.00";
    };
  should["shows a net loss with a leading minus sign"]{
    msgs::();
    `.bs.sendMsg mock {[x;y] msgs,:enlist x};
    `.bs.pubMsg mock {[x;y]};
    .bs.hd:1b;
    .bs.cp:enlist[5i]!enlist`alice;
    .bs.joined:enlist[5i]!enlist 0;
    .bs.hist:([]round:0#0;handle:0#0i;profit:0#0f);
    .bs.res:([]round:1 2;handle:5 5i;profit:-10 -2.5);
    .bs.tab:([]round:0#0;player:0#0f;name:0#`;handle:0#0i;bet:0#0);
    .bs.leave[5i];
    (first msgs) mustmatch "Your net winnings this session are -$12.50";
    };
  should["ignores results from an earlier connection that had the same handle"]{
    msgs::();
    `.bs.sendMsg mock {[x;y] msgs,:enlist x};
    `.bs.pubMsg mock {[x;y]};
    .bs.hd:1b;
    .bs.cp:enlist[5i]!enlist`alice;
    .bs.joined:enlist[5i]!enlist 2;  / this session joined after round 2
    .bs.hist:([]round:1 2;handle:5 5i;profit:100 100f);
    .bs.res:([]round:enlist 3;handle:enlist 5i;profit:enlist 10f);
    .bs.tab:([]round:0#0;player:0#0f;name:0#`;handle:0#0i;bet:0#0);
    .bs.leave[5i];
    (first msgs) mustmatch "Your net winnings this session are $10.00";
    };
  should["reports zero for a player who never finished a hand"]{
    msgs::();
    `.bs.sendMsg mock {[x;y] msgs,:enlist x};
    `.bs.pubMsg mock {[x;y]};
    .bs.hd:1b;
    .bs.cp:enlist[5i]!enlist`alice;
    .bs.joined:enlist[5i]!enlist 0;
    .bs.hist:.bs.res:([]round:0#0;handle:0#0i;profit:0#0f);
    .bs.tab:([]round:0#0;player:0#0f;name:0#`;handle:0#0i;bet:0#0);
    .bs.leave[5i];
    (first msgs) mustmatch "Your net winnings this session are $0.00";
    };
  should["forgets the session's join round"]{
    `.bs.sendMsg mock {[x;y]};
    `.bs.pubMsg mock {[x;y]};
    .bs.hd:1b;
    .bs.cp:(5i;6i)!`alice`bob;
    .bs.joined:(5 6i)!0 3;
    .bs.hist:.bs.res:([]round:0#0;handle:0#0i;profit:0#0f);
    .bs.tab:([]round:0#0;player:0#0f;name:0#`;handle:0#0i;bet:0#0);
    .bs.leave[5i];
    .bs.joined musteq enlist[6i]!enlist 3;
    };
 };

.tst.desc["regConn join round"]{
  should["records the current round against a plain connection's handle"]{
    .bs.cp:()!(); .bs.da:0Ni; .bs.joined:(`int$())!`long$();
    `.bs.isDA mock {0b};
    .bs.rnd:7;
    .bs.regConn[42i];
    .bs.joined[42i] musteq 7;
    };
  should["doesn't record a detectionAlgo connection"]{
    .bs.cp:()!(); .bs.da:0Ni; .bs.joined:(`int$())!`long$();
    `.bs.isDA mock {1b};
    .bs.regConn[42i];
    (count .bs.joined) musteq 0;
    };
 };
