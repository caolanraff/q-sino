.utl.load`:src/server/bin/blackjack.q;
.utl.load each .bjk.libs;

.tst.desc[".bjk.shuffle pitboss-notify guard"]{
  should["behaves as intended AND semantics"]{
    .tst.guard:{[shufflecnt;pit](shufflecnt>1)&not null pit};
    threw:@[{.tst.guard[1;0Ni];0b};();{1b}];
    threw musteq 0b;
    (.tst.guard[1;0Ni]) musteq 0b;
    (.tst.guard[1;5i]) musteq 0b;
    (.tst.guard[2;5i]) musteq 1b;
    (.tst.guard[2;0Ni]) musteq 0b;
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
    .tst.regConnCalls:0;
    .tst.startCalls:0;
    `.bjk.regConn mock {.tst.regConnCalls+:1};
    `.bjk.isPit mock {0b};
    `.bjk.isBanned mock {0b};
    `.bjk.start mock {.tst.startCalls+:1};
    .z.po[];
    .tst.regConnCalls musteq 1;
    .tst.startCalls musteq 1;
    };
  should["skips .bjk.start for a pitboss connection"]{
    .tst.startCalls:0;
    `.bjk.regConn mock {};
    `.bjk.isPit mock {1b};
    `.bjk.isBanned mock {0b};
    `.bjk.start mock {.tst.startCalls+:1};
    .z.po[];
    .tst.startCalls musteq 0;
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
    .tst.excFuncCalls:();
    `.bjk.excFunc mock {.tst.excFuncCalls,:enlist(x;z)};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(); .bjk.hist:.bjk.res;
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.hd:0b;
    .bjk.tab:update out:00b,wait:00b,turn:10b from ([]round:1 1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10;return:0n 0n;profit:0n 0n;split:00b;double:00b;insurance:0f);
    .bjk.leave[5i];
    (exec handle from .bjk.tab) musteq enlist 6i;
    (exec first turn from .bjk.tab) musteq 1b;
    .tst.excFuncCalls mustmatch enlist(`.plr.play;6i);
    };
  should["runs the dealer when the leaver was the last player still to act"]{
    `.bjk.pubMsg mock {[x;y]};
    .tst.dealerCalls:0;
    `.bjk.dealer mock {.tst.dealerCalls+:1};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(); .bjk.hist:.bjk.res;
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.hd:0b;
    .bjk.tab:update out:00b,wait:10b,turn:01b from ([]round:1 1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10;return:0n 0n;profit:0n 0n;split:00b;double:00b;insurance:0f);
    .bjk.leave[6i];
    .tst.dealerCalls musteq 1;
    };
  should["leaves the turn with its holder when someone else leaves"]{
    `.bjk.pubMsg mock {[x;y]};
    .tst.nextTurnCalls:0;
    `.bjk.nextTurn mock {.tst.nextTurnCalls+:1};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(); .bjk.hist:.bjk.res;
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.hd:0b;
    .bjk.tab:update out:00b,wait:00b,turn:10b from ([]round:1 1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10;return:0n 0n;profit:0n 0n;split:00b;double:00b;insurance:0f);
    .bjk.leave[6i];
    (exec handle from .bjk.tab where turn) musteq enlist 5i;
    .tst.nextTurnCalls musteq 0;
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
    .tst.dealCalls:0;
    `.bjk.deal mock {.tst.dealCalls+:1};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(); .bjk.hist:.bjk.res;
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.hd:1b;
    .bjk.stake:([name:enlist`alice;handle:enlist 5i]bet:enlist 10);
    .bjk.tab:update bet:10 0N from ([]round:1 1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10;return:0n 0n;profit:0n 0n;split:00b;double:00b;insurance:0f);
    .bjk.leave[6i];
    .tst.dealCalls musteq 1;
    };
  should["doesn't deal while another remaining player still hasn't bet"]{
    `.bjk.pubMsg mock {[x;y]};
    .tst.dealCalls:0;
    `.bjk.deal mock {.tst.dealCalls+:1};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(); .bjk.hist:.bjk.res;
    .bjk.cp:(5i;6i;7i)!`alice`bob`carol;
    .bjk.hd:1b;
    .bjk.stake:([name:enlist`alice;handle:enlist 5i]bet:enlist 10);
    .bjk.tab:([]round:1 1 1;player:1 2 3f;name:`alice`bob`carol;handle:5 6 7i;cards:3#enlist();cnt:3#0Ni;dealer:3#`;dealerCnt:3#0Ni;bet:10 0N 0N;return:3#0n;profit:3#0n;split:000b;double:000b;insurance:0f);
    .bjk.leave[6i];
    .tst.dealCalls musteq 0;
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
    .tst.excFuncCalls:();
    `.bjk.excFunc mock {.tst.excFuncCalls,:enlist(x;z)};
    .bjk.hd:1b;
    .bjk.cp:(5i;6i;7i)!`alice`bob`carol;
    .bjk.stake:([name:enlist`alice;handle:enlist 5i]bet:enlist 10);
    .bjk.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bjk.start[];
    (exec bet from .bjk.tab where handle=5i) musteq enlist 10;
    (exec handle from .bjk.tab where null bet) musteq 6 7i;
    .tst.excFuncCalls mustmatch ((`.plr.stake;6i);(`.plr.stake;7i));
    };
  should["prompts every player when nobody has bet yet"]{
    `.bjk.sendMsg mock {[x;y]};
    .tst.excFuncCalls:();
    `.bjk.excFunc mock {.tst.excFuncCalls,:enlist(x;z)};
    .bjk.hd:1b;
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.stake:([name:();handle:()]bet:());
    .bjk.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bjk.start[];
    .tst.excFuncCalls mustmatch ((`.plr.stake;5i);(`.plr.stake;6i));
    };
 };

.tst.desc[".z.pc"]{
  should["resets .bjk.pit to null for the pitboss handle, without calling leave"]{
    .bjk.pit:7i;
    .tst.leaveCalls:0;
    `.bjk.leave mock {.tst.leaveCalls+:1};
    .z.pc[7i];
    .bjk.pit musteq 0Ni;
    .tst.leaveCalls musteq 0;
  };
  should["calls leave for a seated player's disconnect, leaving .bjk.pit untouched"]{
    .bjk.pit:7i;
    .bjk.cp:enlist[3i]!enlist`bob_3;
    .tst.leaveArg:0Ni;
    `.bjk.leave mock {.tst.leaveArg:x};
    .z.pc[3i];
    .bjk.pit musteq 7i;
    .tst.leaveArg musteq 3i;
  };
  should["ignores a handle that never joined, such as the console closing"]{
    .bjk.pit:7i;
    .bjk.cp:enlist[3i]!enlist`bob_3;
    .tst.leaveCalls:0;
    `.bjk.leave mock {.tst.leaveCalls+:1};
    .z.pc[0i];
    .tst.leaveCalls musteq 0;
  };
 };

.tst.desc[".bjk.leave winnings message"]{
  should["reports net winnings across every shoe this session, ignoring other players"]{
    .tst.msgs:();
    `.bjk.sendMsg mock {[x;y]};
    `.log.info mock {.tst.msgs,:enlist raze x};
    `.bjk.pubMsg mock {[x;y]};
    .bjk.hd:1b;
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.joined:(5 6i)!0 0;
    .bjk.hist:([]round:1 1;handle:5 6i;profit:10 50f);
    .bjk.res:([]round:2 3 3;handle:5 5 6i;profit:-5 15 -50f);
    .bjk.tab:([]round:0#0;player:0#0f;name:0#`;handle:0#0i;bet:0#0);
    .bjk.leave[5i];
    (any .tst.msgs like "*net winnings this session $20.00*") musteq 1b;
    };
  should["shows a net loss with a leading minus sign"]{
    .tst.msgs:();
    `.bjk.sendMsg mock {[x;y]};
    `.log.info mock {.tst.msgs,:enlist raze x};
    `.bjk.pubMsg mock {[x;y]};
    .bjk.hd:1b;
    .bjk.cp:enlist[5i]!enlist`alice;
    .bjk.joined:enlist[5i]!enlist 0;
    .bjk.hist:([]round:0#0;handle:0#0i;profit:0#0f);
    .bjk.res:([]round:1 2;handle:5 5i;profit:-10 -2.5);
    .bjk.tab:([]round:0#0;player:0#0f;name:0#`;handle:0#0i;bet:0#0);
    .bjk.leave[5i];
    (any .tst.msgs like "*net winnings this session -$12.50*") musteq 1b;
    };
  should["ignores results from an earlier connection that had the same handle"]{
    .tst.msgs:();
    `.bjk.sendMsg mock {[x;y]};
    `.log.info mock {.tst.msgs,:enlist raze x};
    `.bjk.pubMsg mock {[x;y]};
    .bjk.hd:1b;
    .bjk.cp:enlist[5i]!enlist`alice;
    .bjk.joined:enlist[5i]!enlist 2;  / this session joined after round 2
    .bjk.hist:([]round:1 2;handle:5 5i;profit:100 100f);
    .bjk.res:([]round:enlist 3;handle:enlist 5i;profit:enlist 10f);
    .bjk.tab:([]round:0#0;player:0#0f;name:0#`;handle:0#0i;bet:0#0);
    .bjk.leave[5i];
    (any .tst.msgs like "*net winnings this session $10.00*") musteq 1b;
    };
  should["reports zero for a player who never finished a hand"]{
    .tst.msgs:();
    `.bjk.sendMsg mock {[x;y]};
    `.log.info mock {.tst.msgs,:enlist raze x};
    `.bjk.pubMsg mock {[x;y]};
    .bjk.hd:1b;
    .bjk.cp:enlist[5i]!enlist`alice;
    .bjk.joined:enlist[5i]!enlist 0;
    .bjk.hist:.bjk.res:([]round:0#0;handle:0#0i;profit:0#0f);
    .bjk.tab:([]round:0#0;player:0#0f;name:0#`;handle:0#0i;bet:0#0);
    .bjk.leave[5i];
    (any .tst.msgs like "*net winnings this session $0.00*") musteq 1b;
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
    .tst.timerCalls:0;
    `.bjk.betTimer mock {.tst.timerCalls+:1};
    .z.ts[.z.p];
    .tst.timerCalls musteq 1;
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
    .tst.msgs:();
    `.bjk.sendMsg mock {[x;y]};
    `.log.info mock {.tst.msgs,:enlist raze x};
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.nextTurn mock {};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();()); .bjk.hist:0#.bjk.res;
    .bjk.res:([]round:enlist 1;player:enlist 1;name:enlist`alice;handle:enlist 5i;cards:enlist`K`9;cnt:enlist 19i;dealer:enlist`K`8;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 25f;profit:enlist 15f;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.hd:0b;
    .bjk.cp:(5i;6i)!`alice`bob; .bjk.joined:(5 6i)!0 0;
    .bjk.tab:([]round:2 2;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`K`6;`9`7);cnt:16 16i;dealer:`9`9;dealerCnt:9 9i;bet:10 10;return:(();());profit:0n 0n;split:00b;double:00b;insurance:0f);
    .bjk.tab:update out:00b,wait:00b,turn:01b from .bjk.tab;
    .bjk.leave[5i];
    (any .tst.msgs like "*net winnings this session $5.00*") musteq 1b;
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
    .tst.sent:();
    `.bjk.excFunc mock {.tst.sent,:enlist(x;y;z)};
    .bjk.hd:1b;
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.stake:([name:();handle:()]bet:());
    .bjk.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bjk.start[];
    (.tst.sent[;0]) mustmatch `.plr.stake`.plr.stake;
    ({x[1]`me} each .tst.sent) musteq 5 6i;
    ({x[1]`tab} each .tst.sent) mustmatch 2#enlist .bjk.tab;
    };
 };

.tst.desc[".bjk.leave during insurance"]{
  should["closes insurance when the last player yet to answer leaves"]{
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.pubMsg mock {[x;y]};
    .tst.closeCalls:0;
    `.bjk.closeInsurance mock {.tst.closeCalls+:1};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();()); .bjk.hist:0#.bjk.res;
    .bjk.hd:0b; .bjk.insuring:1b;
    .bjk.cp:(5i;6i)!`alice`bob; .bjk.joined:(5 6i)!0 0;
    .bjk.tab:([]round:1 1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`9`7;`10`8);cnt:16 18i;dealer:2#`A;dealerCnt:11 11i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:5 0n);
    .bjk.tab:update out:00b,wait:00b,turn:00b from .bjk.tab;
    .bjk.leave[6i];
    .tst.closeCalls musteq 1;
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
    .tst.betCalls:0;
    .tst.insCalls:0;
    `.bjk.betTimer mock {.tst.betCalls+:1};
    `.bjk.insureTimer mock {.tst.insCalls+:1};
    .z.ts[.z.p];
    (.tst.betCalls,.tst.insCalls) musteq 1 1;
    };
 };

.tst.desc[".z.ts turn clock"]{
  should["drives the turn clock"]{
    .tst.turnCalls:0;
    `.bjk.betTimer mock {};
    `.bjk.insureTimer mock {};
    `.bjk.turnTimer mock {.tst.turnCalls+:1};
    .z.ts[.z.p];
    .tst.turnCalls musteq 1;
  };
 };

.tst.desc[".bjk.start mid-hand"]{
  should["tells the connection that just arrived to wait for the hand to finish"]{
    .tst.sent:();
    `.bjk.sendMsg mock {.tst.sent,:enlist(x;y)};
    .bjk.hd:0b;
    .bjk.start[];
    .tst.sent mustmatch enlist("Please wait until the hand is over";.z.w);
    .bjk.hd:1b;
    };
 };

.tst.desc[".bjk.command"]{
  should["accepts the manual string form and the forms the clients send"]{
    .bjk.command["stake 10"] mustmatch(`stake;10);
    .bjk.command["hit[]"] mustmatch(`hit;::);
    .bjk.command[(`hit;`)] mustmatch`hit`;
    .bjk.command[(`insure;2.5)] mustmatch(`insure;2.5);
    .bjk.command[(`stake;10i)] mustmatch(`stake;10i);
  };
  should["rejects anything that isn't a single public command"]{
    "Send a command*" mustthrow(.bjk.command;".bjk.getCard:{`A}");
    "Send a command*" mustthrow(.bjk.command;"select from .bjk.dc");
    "Send a command*" mustthrow(.bjk.command;"stake 10;.bjk.hd:1b");
    "Send a command*" mustthrow(.bjk.command;`hit);
    "Only *" mustthrow(.bjk.command;".bjk.deal[]");
    "Only *" mustthrow(.bjk.command;({x};1));
  };
  should["rejects an argument that isn't a single number, so it can't read or run server code"]{
    "A command takes*" mustthrow(.bjk.command;"stake x");
    "A command takes*" mustthrow(.bjk.command;"stake .bjk.hd");
    "A command takes*" mustthrow(.bjk.command;"stake[.bjk.hd:0b]");
    "A command takes*" mustthrow(.bjk.command;"stake 10 20");
    "A command takes*" mustthrow(.bjk.command;(`stake;`a));
  };
 };

.tst.desc[".bjk.run"]{
  should["runs a player's public command"]{
    `.bjk.isPit mock {0b};
    `stake mock {.tst.staked:x};
    .bjk.run(`stake;10);
    .tst.staked musteq 10;
  };
  should["doesn't run anything else a player sends"]{
    `.bjk.isPit mock {0b};
    .tst.x:0;
    @[.bjk.run;".tst.x:1";{}];
    .tst.x musteq 0;
  };
  should["runs any query from the pitboss"]{
    `.bjk.isPit mock {1b};
    .bjk.run["52*.bjk.rules`deckCnt"] musteq 52*.bjk.rules`deckCnt;
  };
 };

.tst.desc[".bjk.pg"]{
  should["logs a failed request and returns the error to the caller"]{
    .tst.logged:();
    `.log.warn mock {.tst.logged,:enlist x};
    `.bjk.isPit mock {0b};
    @[.bjk.pg;".tst.x:1";{x}] mustlike"Send a command*";
    first[.tst.logged] mustlike string[.z.u],"'s request failed: Send a command*";
  };
 };

.tst.desc[".bjk.ps"]{
  should["logs a failed request and messages the player instead of throwing"]{
    .tst.logged:.tst.sent:();
    `.log.warn mock {.tst.logged,:enlist x};
    `.bjk.sendMsg mock {[x;y].tst.sent,:enlist x};
    `.bjk.isPit mock {0b};
    .bjk.ps".tst.x:1";
    first[.tst.logged] mustlike string[.z.u],"'s request failed: Send a command*";
    first[.tst.sent] mustlike"That didn't work: Send a command*";
  };
 };

.tst.desc[".bjk.eject"]{
  should["only logs the suspicion when ejection is off"]{
    .tst.logged:();
    `.log.info mock {.tst.logged,:enlist x};
    .tst.left:();
    `.bjk.leave mock {.tst.left,:x};
    `.bjk.disconnect mock {};
    .bjk.ejectCounters:0b;
    .bjk.cp:enlist[5i]!enlist`a_5;
    .bjk.users:enlist[5i]!enlist`alice;
    .bjk.banned:`symbol$();
    .bjk.eject 5i;
    count[.tst.left] musteq 0;
    .bjk.banned mustmatch`symbol$();
    first[.tst.logged] mustlike"The pitboss suspects a_5 of counting cards*";
  };
  should["tells the player, takes them off the table and closes their connection when ejection is on"]{
    .tst.msgs:();
    `.bjk.sendMsg mock {.tst.msgs,:enlist(x;y)};
    `.log.warn mock {[x]};
    .tst.left:();
    `.bjk.leave mock {.tst.left,:x};
    .tst.closed:();
    `.bjk.disconnect mock {.tst.closed,:x};
    .bjk.ejectCounters:1b;
    .bjk.cp:enlist[5i]!enlist`a_5;
    .bjk.users:enlist[5i]!enlist`alice;
    .bjk.banned:`symbol$();
    .bjk.eject 5i;
    .bjk.banned mustmatch enlist`alice;
    .tst.msgs mustmatch enlist("The pitboss has asked you to leave the table";5i);
    .tst.left mustmatch enlist 5i;
    .tst.closed mustmatch enlist 5i;
  };
  should["ignores a handle that isn't at the table, e.g. a player who has already left"]{
    .tst.left:();
    `.bjk.leave mock {.tst.left,:x};
    `.bjk.disconnect mock {};
    .bjk.ejectCounters:1b;
    .bjk.cp:enlist[5i]!enlist`a_5;
    .bjk.eject 9i;
    count[.tst.left] musteq 0;
  };
 };

.tst.desc[".bjk.isBanned"]{
  should["is true for a username on the ban list, and false otherwise"]{
    .bjk.banned:enlist .z.u;
    .bjk.isBanned[] musteq 1b;
    .bjk.banned:enlist`someoneElse;
    .bjk.isBanned[] musteq 0b;
  };
 };

.tst.desc[".z.po ban list"]{
  should["turns a banned user away before they're registered or seated"]{
    `.bjk.isBanned mock {1b};
    .tst.turnedAway:();
    `.bjk.turnAway mock {.tst.turnedAway,:x};
    .tst.regConnCalls:0;
    `.bjk.regConn mock {.tst.regConnCalls+:1};
    `.bjk.start mock {};
    .z.po[];
    .tst.turnedAway mustmatch enlist .z.w;
    .tst.regConnCalls musteq 0;
  };
 };

.tst.desc[".bjk.turnAway"]{
  should["tells the user they've been asked to leave, then closes the connection"]{
    `.log.info mock {[x]};
    .tst.msgs:();
    `.bjk.sendMsg mock {.tst.msgs,:enlist(x;y)};
    .tst.closed:();
    `.bjk.disconnect mock {.tst.closed,:x};
    .bjk.turnAway 7i;
    .tst.msgs mustmatch enlist("You've been asked to leave this table";7i);
    .tst.closed mustmatch enlist 7i;
  };
 };

.tst.desc[".bjk.users"]{
  should["records each player's username when they connect, and forgets it when they leave"]{
    `.bjk.isPit mock {0b};
    .bjk.cp:()!();
    .bjk.users:(`int$())!`symbol$();
    .bjk.regConn[42i];
    .bjk.users[42i] musteq .z.u;
    .bjk.unseat 42i;
    (42i in key .bjk.users) musteq 0b;
  };
 };

.tst.desc[".bjk.chips"]{
  should["gives a player no chips until they buy in, and forgets them when they leave"]{
    `.bjk.isPit mock {0b};
    `.bjk.sendMsg mock {[x;y]};
    .bjk.cp:()!();
    .bjk.chips:(`int$())!`float$();
    .bjk.regConn[42i];
    (42i in key .bjk.chips) musteq 0b;
    .bjk.buyIn[42i;500f];
    .bjk.chips[42i] musteq 500f;
    .bjk.unseat 42i;
    (42i in key .bjk.chips) musteq 0b;
  };
  should["counts what a player has on the table, bets and insurance, against their chips"]{
    .bjk.chips:(0 1i)!100 50f;
    .bjk.tab:update insurance:5 0f from ([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 20;return:0n 0n;profit:0n 0n;split:00b;double:00b;insurance:0 0f;out:00b;wait:00b;turn:10b);
    .bjk.committed[0i] musteq 15f;
    .bjk.available[0i] musteq 85f;
  };
 };

.tst.desc[".bjk.betPrompt"]{
  before{.bjk.rules:`maxSplitHands`deckCnt`minBet`maxBet`minBuyIn!4 6 10 500 100};
  should["asks for a bet and shows the player's chips"]{
    .tst.msgs:();
    `.bjk.sendMsg mock {[x;y].tst.msgs,:enlist x};
    .bjk.chips:enlist[7i]!enlist 512.5;
    .bjk.betPrompt 7i;
    .tst.msgs mustmatch enlist"Please place your bets via the stake[] function, $10 to $500; your chips: $512.50";
  };
  should["tells a player who can't afford the minimum bet that they're out of chips"]{
    .tst.msgs:();
    `.bjk.sendMsg mock {[x;y].tst.msgs,:enlist x};
    .bjk.chips:enlist[7i]!enlist 8f;
    .bjk.betPrompt 7i;
    .tst.msgs mustmatch enlist"You're out of chips: buyin[amount] for more";
  };
 };

.tst.desc[".bjk.clientState chips"]{
  should["pushes the player their own chips"]{
    .bjk.chips:(5 6i)!250 80f;
    .bjk.clientState[6i][`chips] musteq 80f;
  };
 };

.tst.desc[".bjk.logLeaver chips"]{
  should["says what a player leaves with, less anything lost on a hand in play"]{
    .tst.msgs:();
    `.log.info mock {.tst.msgs,:enlist raze x};
    .bjk.hist:.bjk.res:0#.bjk.res;
    .bjk.joined:enlist[0i]!enlist 0;
    .bjk.cp:enlist[0i]!enlist`p1;
    .bjk.chips:enlist[0i]!enlist 300f;
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 20;return:0n 0n;profit:0n 0n;split:00b;double:00b;insurance:0 0f;out:00b;wait:00b;turn:10b);
    .bjk.hd:1b;
    .bjk.logLeaver 0i;
    .bjk.hd:0b;
    .bjk.logLeaver 0i;
    .bjk.hd:1b;
    .tst.msgs[0] mustlike"*leaving with $300.00 in chips";
    .tst.msgs[1] mustlike"*leaving with $290.00 in chips";
  };
 };

.tst.desc[".bjk.outOfChips"]{
  should["is only true for a player with chips, but fewer than the minimum bet"]{
    .bjk.rules:`maxSplitHands`deckCnt`minBet`maxBet`minBuyIn!4 6 10 500 100;
    .bjk.chips:(5 6i)!8 50f;
    (.bjk.outOfChips each 5 6 7i) mustmatch 100b;
  };
 };

.tst.desc[".bjk.betPrompt before buying in"]{
  should["tells a player without chips how to get them"]{
    .tst.msgs:();
    `.bjk.sendMsg mock {[x;y].tst.msgs,:enlist x};
    .bjk.rules:`maxSplitHands`deckCnt`minBet`maxBet`minBuyIn!4 6 10 500 100;
    .bjk.chips:(`int$())!`float$();
    .bjk.betPrompt 7i;
    .tst.msgs mustmatch enlist"Please place your bets via the stake[] function, $10 to $500; buy some chips first: buyin[amount]";
  };
 };
