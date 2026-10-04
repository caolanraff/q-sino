.utl.load`:src/house/bin/blackjack.q;
.utl.load each .bjk.libs;

.tst.uid:{"G"$"00000000-0000-0000-0000-",-12#"00000000000",string x};

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
  before{
    .bjk.tab:([]round:"j"$();player:"j"$();name:`$();handle:"i"$();uid:"g"$();cards:();cnt:"i"$();dealer:();dealerCnt:"i"$();bet:"j"$();return:"f"$();profit:"f"$();split:"b"$();double:"b"$();insurance:"f"$();forced:"b"$());
  };
  should["succeeds for exactly one connected player"]{
    .bjk.cp:enlist[5i]!enlist`alice;
    threw:@[{`.bjk.tab upsert ([]player:1+til count .bjk.cp;name:value .bjk.cp;handle:key .bjk.cp);0b};();{1b}];
    threw musteq 0b;
    (count .bjk.tab) musteq 1;
    };
  should["succeeds for two connected players"]{
    .bjk.cp:(5i;6i)!`alice`bob;
    threw:@[{`.bjk.tab upsert ([]player:1+til count .bjk.cp;name:value .bjk.cp;handle:key .bjk.cp);0b};();{1b}];
    threw musteq 0b;
    (count .bjk.tab) musteq 2;
    (asc exec name from .bjk.tab) musteq `alice`bob;
    };
 };

.tst.desc[".bjk.tab keeps a typed bet column"]{
  should["select ... where null bet doesn't throw before anyone has staked this round"]{
    .bjk.tab:([]round:"j"$();player:"j"$();name:`$();handle:"i"$();uid:"g"$();cards:();cnt:"i"$();dealer:();dealerCnt:"i"$();bet:"j"$();return:"f"$();profit:"f"$();split:"b"$();double:"b"$();insurance:"f"$();forced:"b"$());
    `.bjk.tab upsert ([]player:1 2;name:`alice`bob;handle:10 11i);
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
  before{
    .bjk.cp:()!(); .bjk.pit:0Ni;
  };
  should["adds a plain connection to cp when isDA is false"]{
    `.bjk.isPit mock {0b};
    .bjk.regConn[42i];
    (count .bjk.cp) musteq 1;
    .bjk.pit musteq 0Ni;
    };
  should["routes a pitboss connection to .bjk.pit instead of cp"]{
    `.bjk.isPit mock {1b};
    .bjk.regConn[42i];
    .bjk.pit musteq 42i;
    (count .bjk.cp) musteq 0;
    };
 };

.tst.desc[".z.po"]{
  before{
    .tst.startCalls:0;
    `.bjk.isBanned mock {0b};
    `.bjk.start mock {.tst.startCalls+:1};
    .bjk.chipsDue:("i"$())!"p"$();
  };
  should["registers a player and starts their buy-in clock, without seating them or asking for bets"]{
    .bjk.cp:()!(); .bjk.pit:0Ni;
    .tst.regConnCalls:0;
    `.bjk.regConn mock {.tst.regConnCalls+:1};
    `.bjk.isPit mock {0b};
    .z.po[];
    .tst.regConnCalls musteq 1;
    .tst.startCalls musteq 0;
    (.z.w in key .bjk.chipsDue) musteq 1b;
    };
  should["gives a pitboss connection no buy-in clock"]{
    `.bjk.regConn mock {};
    `.bjk.isPit mock {1b};
    .z.po[];
    .tst.startCalls musteq 0;
    (.z.w in key .bjk.chipsDue) musteq 0b;
    };
 };

.tst.desc["leave removes the disconnecting handle from cp"]{
  should["drops only the disconnecting handle's key, leaving other connected players untouched"]{
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.tab:([]round:"j"$();player:"j"$();name:`$();handle:"i"$();uid:"g"$();cards:();cnt:"i"$();dealer:();dealerCnt:"i"$();bet:"j"$();return:"f"$();profit:"f"$();split:"b"$();double:"b"$();insurance:"f"$();forced:"b"$());
    .bjk.res:([]round:"j"$();player:"j"$();name:`$();handle:"i"$();uid:"g"$();cards:();cnt:"i"$();dealer:();dealerCnt:"i"$();bet:"j"$();return:"f"$();profit:"f"$();split:"b"$();double:"b"$();insurance:"f"$();forced:"b"$()); .bjk.hist:.bjk.res;
    .bjk.hd:1b;
    .bjk.leave[5i];
    .bjk.cp musteq enlist[6i]!enlist`bob;
    };
 };

.tst.desc[".bjk.leave mid-hand"]{
  before{
    .bjk.res:([]round:"j"$();player:"j"$();name:`$();handle:"i"$();uid:"g"$();cards:();cnt:"i"$();dealer:();dealerCnt:"i"$();bet:"j"$();return:"f"$();profit:"f"$();split:"b"$();double:"b"$();insurance:"f"$();forced:"b"$()); .bjk.hist:.bjk.res;
    `.bjk.pubMsg mock {[x;y]};
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.hd:0b;
  };
  should["passes the turn to the next player's hand when the leaver held it"]{
    `.bjk.sendMsg mock {[x;y]};
    .tst.excFuncCalls:();
    `.bjk.excFunc mock {.tst.excFuncCalls,:enlist(x;z)};
    .bjk.tab:update out:0b,wait:0b,turn:10b from ([]round:1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`8`8;`9`7);cnt:16i;dealer:`5;dealerCnt:5i;bet:10;return:0n;profit:0n;split:0b;double:0b;insurance:0f);
    .bjk.leave[5i];
    (exec handle from .bjk.tab) musteq enlist 6i;
    (exec first turn from .bjk.tab) musteq 1b;
    .tst.excFuncCalls mustmatch enlist(`.plr.play;6i);
    };
  should["runs the dealer when the leaver was the last player still to act"]{
    .tst.dealerCalls:0;
    `.bjk.dealer mock {.tst.dealerCalls+:1};
    .bjk.tab:update out:0b,wait:10b,turn:01b from ([]round:1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`8`8;`9`7);cnt:16i;dealer:`5;dealerCnt:5i;bet:10;return:0n;profit:0n;split:0b;double:0b;insurance:0f);
    .bjk.leave[6i];
    .tst.dealerCalls musteq 1;
    };
  should["leaves the turn with its holder when someone else leaves"]{
    .tst.nextTurnCalls:0;
    `.bjk.nextTurn mock {.tst.nextTurnCalls+:1};
    .bjk.tab:update out:0b,wait:0b,turn:10b from ([]round:1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`8`8;`9`7);cnt:16i;dealer:`5;dealerCnt:5i;bet:10;return:0n;profit:0n;split:0b;double:0b;insurance:0f);
    .bjk.leave[6i];
    (exec handle from .bjk.tab where turn) musteq enlist 5i;
    .tst.nextTurnCalls musteq 0;
    };
  should["removes every split hand belonging to the leaver"]{
    `.bjk.nextTurn mock {};
    .bjk.tab:([]round:1;player:1 2.01 2.02;name:`alice`bob`bob;handle:5 6 6i;cards:(`8`8;`9`3;`9`4);cnt:16 12 13i;dealer:`5;dealerCnt:5i;bet:10;return:0n;profit:0n;split:011b;double:0b;insurance:0f);
    .bjk.tab:update out:0b,wait:0b,turn:100b from .bjk.tab;
    .bjk.leave[6i];
    (exec handle from .bjk.tab) musteq enlist 5i;
    };
 };

.tst.desc[".bjk.leave between hands"]{
  before{
    .bjk.res:([]round:"j"$();player:"j"$();name:`$();handle:"i"$();uid:"g"$();cards:();cnt:"i"$();dealer:();dealerCnt:"i"$();bet:"j"$();return:"f"$();profit:"f"$();split:"b"$();double:"b"$();insurance:"f"$();forced:"b"$()); .bjk.hist:.bjk.res;
    `.bjk.pubMsg mock {[x;y]};
    .bjk.hd:1b;
  };
  should["deals when the leaver was the only seated player yet to bet"]{
    .tst.dealCalls:0;
    `.bjk.deal mock {.tst.dealCalls+:1};
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.stake:([name:enlist`alice;handle:5i]bet:enlist 10);
    .bjk.tab:update bet:10 0N from ([]round:1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`8`8;`9`7);cnt:16i;dealer:`5;dealerCnt:5i;bet:10;return:0n;profit:0n;split:0b;double:0b;insurance:0f);
    .bjk.leave[6i];
    .tst.dealCalls musteq 1;
    };
  should["doesn't deal while another remaining player still hasn't bet"]{
    .tst.dealCalls:0;
    `.bjk.deal mock {.tst.dealCalls+:1};
    .bjk.cp:(5i;6i;7i)!`alice`bob`carol;
    .bjk.stake:([name:enlist`alice;handle:5i]bet:enlist 10);
    .bjk.tab:([]round:1;player:1 2 3f;name:`alice`bob`carol;handle:5 6 7i;cards:3#enlist();cnt:0Ni;dealer:`;dealerCnt:0Ni;bet:10 0N 0N;return:0n;profit:0n;split:0b;double:0b;insurance:0f);
    .bjk.leave[6i];
    .tst.dealCalls musteq 0;
    };
  should["drops the leaver's pending bet"]{
    `.bjk.deal mock {};
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.stake:([name:`alice`bob;handle:5 6i]bet:10 20);
    .bjk.tab:([]round:1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`8`8;`9`7);cnt:16i;dealer:`5;dealerCnt:5i;bet:10;return:0n;profit:0n;split:0b;double:0b;insurance:0f);
    .bjk.leave[6i];
    (exec handle from .bjk.stake) musteq enlist 5i;
    };
 };

.tst.desc[".bjk.start"]{
  before{
    .bjk.tab:([]round:"j"$();player:"j"$();name:`$();handle:"i"$();uid:"g"$();cards:();cnt:"i"$();dealer:();dealerCnt:"i"$();bet:"j"$();return:"f"$();profit:"f"$();split:"b"$();double:"b"$();insurance:"f"$();forced:"b"$());
    `.bjk.sendMsg mock {[x;y]};
    .tst.excFuncCalls:();
    `.bjk.excFunc mock {.tst.excFuncCalls,:enlist(x;z)};
    .bjk.hd:1b;
    .bjk.chips:5 6 7i!3#1000f;
  };
  should["keeps bets already placed when a player joins mid-betting, and only prompts players yet to bet"]{
    .bjk.cp:(5i;6i;7i)!`alice`bob`carol;
    .bjk.stake:([name:enlist`alice;handle:5i]bet:enlist 10);
    .bjk.start[];
    (exec bet from .bjk.tab where handle=5i) musteq enlist 10;
    (exec handle from .bjk.tab where null bet) musteq 6 7i;
    .tst.excFuncCalls mustmatch ((`.plr.stake;6i);(`.plr.stake;7i));
    };
  should["prompts every player when nobody has bet yet"]{
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.stake:([name:`$();handle:"i"$()]bet:"j"$());
    .bjk.start[];
    .tst.excFuncCalls mustmatch ((`.plr.stake;5i);(`.plr.stake;6i));
    };
 };

.tst.desc[".z.pc"]{
  before{
    .bjk.pit:7i;
  };
  should["resets .bjk.pit to null for the pitboss handle, without calling leave"]{
    .tst.leaveCalls:0;
    `.bjk.leave mock {.tst.leaveCalls+:1};
    .z.pc[7i];
    .bjk.pit musteq 0Ni;
    .tst.leaveCalls musteq 0;
  };
  should["calls leave for a seated player's disconnect, leaving .bjk.pit untouched"]{
    .bjk.cp:enlist[3i]!enlist`bob_3;
    .tst.leaveArg:0Ni;
    `.bjk.leave mock {.tst.leaveArg:x};
    .z.pc[3i];
    .bjk.pit musteq 7i;
    .tst.leaveArg musteq 3i;
  };
  should["ignores a handle that never joined, such as the console closing"]{
    .bjk.cp:enlist[3i]!enlist`bob_3;
    .tst.leaveCalls:0;
    `.bjk.leave mock {.tst.leaveCalls+:1};
    .z.pc[0i];
    .tst.leaveCalls musteq 0;
  };
 };

.tst.desc[".bjk.leave winnings message"]{
  before{
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.pubMsg mock {[x;y]};
    .bjk.hd:1b;
    .bjk.tab:([]round:0#0;player:0f;name:`;handle:0i;bet:0);
  };
  should["reports net winnings across every shoe this session, ignoring other players"]{
    .tst.msgs:();
    `.log.info mock {.tst.msgs,:enlist raze x};
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.uids:(5 6i)!.tst.uid each 5 6;
    .bjk.hist:([]round:1;handle:5 6i;uid:.tst.uid each 5 6;profit:10 50f);
    .bjk.res:([]round:2 3 3;handle:5 5 6i;uid:.tst.uid each 5 5 6;profit:-5 15 -50f);
    .bjk.leave[5i];
    (any .tst.msgs like "*net winnings this session $20.00*") musteq 1b;
    };
  should["shows a net loss with a leading minus sign"]{
    .tst.msgs:();
    `.log.info mock {.tst.msgs,:enlist raze x};
    .bjk.cp:enlist[5i]!enlist`alice;
    .bjk.uids:enlist[5i]!enlist .tst.uid 5;
    .bjk.hist:([]round:0#0;handle:0i;uid:0Ng;profit:0f);
    .bjk.res:([]round:1 2;handle:5i;uid:.tst.uid 5;profit:-10 -2.5);
    .bjk.leave[5i];
    (any .tst.msgs like "*net winnings this session -$12.50*") musteq 1b;
    };
  should["ignores results from an earlier connection that had the same handle"]{
    .tst.msgs:();
    `.log.info mock {.tst.msgs,:enlist raze x};
    .bjk.cp:enlist[5i]!enlist`alice;
    .bjk.uids:enlist[5i]!enlist .tst.uid 5;
    .bjk.hist:([]round:1 2;handle:5i;uid:.tst.uid 15;profit:100f);
    .bjk.res:([]round:enlist 3;handle:5i;uid:.tst.uid 5;profit:10f);
    .bjk.leave[5i];
    (any .tst.msgs like "*net winnings this session $10.00*") musteq 1b;
    };
  should["reports zero for a player who never finished a hand"]{
    .tst.msgs:();
    `.log.info mock {.tst.msgs,:enlist raze x};
    .bjk.cp:enlist[5i]!enlist`alice;
    .bjk.uids:enlist[5i]!enlist .tst.uid 5;
    .bjk.hist:.bjk.res:([]round:0#0;handle:0i;uid:0Ng;profit:0f);
    .bjk.leave[5i];
    (any .tst.msgs like "*net winnings this session $0.00*") musteq 1b;
    };
  should["forgets the leaver's connection id"]{
    .bjk.cp:(5i;6i)!`alice`bob;
    .bjk.uids:(5 6i)!.tst.uid each 5 6;
    .bjk.hist:.bjk.res:([]round:0#0;handle:0i;uid:0Ng;profit:0f);
    .bjk.leave[5i];
    .bjk.uids mustmatch enlist[6i]!enlist .tst.uid 6;
    };
 };

.tst.desc["regConn connection id"]{
  before{
    .bjk.cp:()!(); .bjk.pit:0Ni; .bjk.uids:("i"$())!"g"$();
  };
  should["gives a plain connection an id"]{
    `.bjk.isPit mock {0b};
    .bjk.regConn[42i];
    (null .bjk.uids 42i) musteq 0b;
    };
  should["gives a new connection on a reused handle a different id"]{
    `.bjk.isPit mock {0b};
    .bjk.regConn[42i];
    u:.bjk.uids 42i;
    .bjk.regConn[42i];
    (u~.bjk.uids 42i) musteq 0b;
    };
  should["doesn't give a pitboss connection one"]{
    `.bjk.isPit mock {1b};
    .bjk.regConn[42i];
    (count .bjk.uids) musteq 0;
    };
 };

.tst.desc[".z.ts"]{
  should["drives the betting clock"]{
    .tst.timerCalls:0;
    `.bjk.betTimer mock {.tst.timerCalls+:1};
    `.bjk.chipsTimer mock {};
    .z.ts[.z.p];
    .tst.timerCalls musteq 1;
    };
 };

.tst.desc[".bjk.leave records a mid-hand leaver's hands"]{
  before{
    .bjk.res:([]round:"j"$();player:"j"$();name:`$();handle:"i"$();uid:"g"$();cards:();cnt:"i"$();dealer:();dealerCnt:"i"$();bet:"j"$();return:"f"$();profit:"f"$();split:"b"$();double:"b"$();insurance:"f"$();forced:"b"$()); .bjk.hist:0#.bjk.res;
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.pubMsg mock {[x;y]};
    .bjk.cp:(5i;6i)!`alice`bob; .bjk.uids:(5 6i)!.tst.uid each 5 6;
  };
  should["records an unfinished hand as a loss of its bet"]{
    `.bjk.nextTurn mock {};
    .bjk.hd:0b;
    .bjk.tab:([]round:3;player:1 2f;name:`alice`bob;handle:5 6i;uid:.tst.uid each 5 6;cards:(`K`6;`9`7);cnt:16i;dealer:`9;dealerCnt:9i;bet:10;return:(();());profit:0n;split:0b;double:0b;insurance:0f;forced:0b);
    .bjk.tab:update out:0b,wait:0b,turn:01b from .bjk.tab;
    .bjk.leave[5i];
    (exec handle from .bjk.res) musteq enlist 5i;
    (exec uid from .bjk.res) mustmatch enlist .tst.uid 5;
    (exec forced from .bjk.res) musteq enlist 1b;
    (exec return from .bjk.res) musteq enlist 0f;
    (exec profit from .bjk.res) musteq enlist -10f;
    (exec round from .bjk.res) musteq enlist 3;
    (exec first dealer from .bjk.res) mustmatch enlist`9;
    };
  should["keeps the result of a hand that was already settled, like a paid blackjack"]{
    `.bjk.nextTurn mock {};
    .bjk.hd:0b;
    .bjk.tab:([]round:3;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`A`K;`9`7);cnt:21 16i;dealer:`9;dealerCnt:9i;bet:10;return:(25f;());profit:0n;split:0b;double:0b;insurance:0f);
    .bjk.tab:update out:10b,wait:0b,turn:01b from .bjk.tab;
    .bjk.leave[5i];
    (exec profit from .bjk.res) musteq enlist 15f;
    };
  should["records every split hand, forfeiting a doubled stake in full"]{
    `.bjk.nextTurn mock {};
    .bjk.hd:0b;
    .bjk.tab:([]round:3;player:1.01 1.02 2;name:`alice`alice`bob;handle:5 5 6i;cards:(`8`3`K;`8`K`5;`9`7);cnt:21 23 16i;dealer:`9;dealerCnt:9i;bet:20 10 10;return:(();0f;());profit:0n;split:110b;double:100b;insurance:0f);
    .bjk.tab:update out:010b,wait:100b,turn:001b from .bjk.tab;
    .bjk.leave[5i];
    (exec player from .bjk.res) musteq 1 1;
    (exec profit from .bjk.res) musteq -20 -10f;
    };
  should["counts the forfeited hand in the leaver's session winnings"]{
    .tst.msgs:();
    `.log.info mock {.tst.msgs,:enlist raze x};
    `.bjk.nextTurn mock {};
    .bjk.res:([]round:1;player:1;name:`alice;handle:5i;uid:.tst.uid 5;cards:enlist`K`9;cnt:19i;dealer:enlist`K`8;dealerCnt:18i;bet:10;return:25f;profit:15f;split:0b;double:0b;insurance:0f;forced:0b);
    .bjk.hd:0b;
    .bjk.tab:([]round:2;player:1 2f;name:`alice`bob;handle:5 6i;uid:.tst.uid each 5 6;cards:(`K`6;`9`7);cnt:16i;dealer:`9;dealerCnt:9i;bet:10;return:(();());profit:0n;split:0b;double:0b;insurance:0f;forced:0b);
    .bjk.tab:update out:0b,wait:0b,turn:01b from .bjk.tab;
    .bjk.leave[5i];
    (any .tst.msgs like "*net winnings this session $5.00*") musteq 1b;
    };
  should["records nothing for a player who leaves between hands"]{
    `.bjk.deal mock {};
    .bjk.hd:1b;
    .bjk.stake:([name:enlist`alice;handle:5i]bet:enlist 10);
    .bjk.tab:([]round:0N;player:1 2f;name:`alice`bob;handle:5 6i;cards:2#enlist();cnt:0Ni;dealer:`;dealerCnt:0Ni;bet:10 0N;return:(();());profit:0n;split:0b;double:0b;insurance:0f);
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
    .bjk.cp:5 6i!`alice`bob;
    .bjk.chips:5 6i!2#1000f;
    .bjk.stake:([name:`$();handle:"i"$()]bet:"j"$());
    .bjk.tab:([]round:"j"$();player:"j"$();name:`$();handle:"i"$();uid:"g"$();cards:();cnt:"i"$();dealer:();dealerCnt:"i"$();bet:"j"$();return:"f"$();profit:"f"$();split:"b"$();double:"b"$();insurance:"f"$();forced:"b"$());
    .bjk.start[];
    (.tst.sent[;0]) mustmatch `.plr.stake`.plr.stake;
    ({x[1]`me} each .tst.sent) musteq 5 6i;
    ({x[1]`tab} each .tst.sent) mustmatch 2#enlist .bjk.tab;
    };
 };

.tst.desc[".bjk.seat"]{
  should["seats only connected players who have bought in, keeping their bets"]{
    .bjk.cp:5 6 7i!`alice`bob`carol;
    .bjk.chips:5 7i!100 5f;
    .bjk.stake:([name:enlist`carol;handle:7i]bet:enlist 10);
    .bjk.tab:([]round:"j"$();player:"j"$();name:`$();handle:"i"$();uid:"g"$();cards:();cnt:"i"$();dealer:();dealerCnt:"i"$();bet:"j"$();return:"f"$();profit:"f"$();split:"b"$();double:"b"$();insurance:"f"$();forced:"b"$());
    .bjk.seat[];
    (select player,name,handle,bet from .bjk.tab) mustmatch ([]player:1 2;name:`alice`carol;handle:5 7i;bet:0N 10);
    };
 };

.tst.desc[".bjk.sitIn"]{
  should["seats the player and asks only them to bet"]{
    .tst.msgs:();
    `.bjk.prompt mock {.tst.msgs,:enlist(x;y)};
    .tst.sent:();
    `.bjk.excFunc mock {.tst.sent,:enlist(x;z)};
    .bjk.rules:`maxSplitHands`deckCnt`minBet`maxBet`minBuyIn!4 6 10 500 100;
    .bjk.cp:5 6i!`alice`bob;
    .bjk.chips:5 6i!1000 300f;
    .bjk.stake:([name:`$();handle:"i"$()]bet:"j"$());
    .bjk.tab:([]round:"j"$();player:"j"$();name:`$();handle:"i"$();uid:"g"$();cards:();cnt:"i"$();dealer:();dealerCnt:"i"$();bet:"j"$();return:"f"$();profit:"f"$();split:"b"$();double:"b"$();insurance:"f"$();forced:"b"$());
    .bjk.sitIn 6i;
    (exec handle from .bjk.tab) musteq 5 6i;
    .tst.msgs[;1] musteq enlist 6i;
    .tst.sent mustmatch enlist(`.plr.stake;6i);
    };
 };

.tst.desc[".bjk.leave during insurance"]{
  before{
    .bjk.res:([]round:"j"$();player:"j"$();name:`$();handle:"i"$();uid:"g"$();cards:();cnt:"i"$();dealer:();dealerCnt:"i"$();bet:"j"$();return:"f"$();profit:"f"$();split:"b"$();double:"b"$();insurance:"f"$();forced:"b"$()); .bjk.hist:0#.bjk.res;
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.pubMsg mock {[x;y]};
    .bjk.hd:0b; .bjk.insuring:1b;
    .bjk.cp:(5i;6i)!`alice`bob; .bjk.uids:(5 6i)!.tst.uid each 5 6;
    .bjk.tab:([]round:1;player:1 2f;name:`alice`bob;handle:5 6i;cards:(`9`7;`10`8);cnt:16 18i;dealer:`A;dealerCnt:11i;bet:10;return:0n;profit:0n;split:0b;double:0b;insurance:5 0n);
  };
  should["closes insurance when the last player yet to answer leaves"]{
    .tst.closeCalls:0;
    `.bjk.closeInsurance mock {.tst.closeCalls+:1};
    .bjk.tab:update out:0b,wait:0b,turn:0b from .bjk.tab;
    .bjk.leave[6i];
    .tst.closeCalls musteq 1;
    .bjk.insuring:0b;
    };
  should["records a leaver's insurance as lost along with their bet"]{
    `.bjk.closeInsurance mock {};
    .bjk.tab:update out:0b,wait:0b,turn:0b from .bjk.tab;
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
    `.bjk.chipsTimer mock {};
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
    `.bjk.chipsTimer mock {};
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
  before{
    .tst.left:();
    `.bjk.leave mock {.tst.left,:x};
    .bjk.cp:enlist[5i]!enlist`a_5;
    .bjk.uids:enlist[5i]!enlist .tst.uid 5;
  };
  should["only logs the suspicion when ejection is off"]{
    .tst.logged:();
    `.log.info mock {.tst.logged,:enlist x};
    `.bjk.disconnect mock {};
    .bjk.ejectCounters:0b;
    .bjk.users:enlist[5i]!enlist`alice;
    .bjk.banned:`$();
    .bjk.eject .tst.uid 5;
    count[.tst.left] musteq 0;
    .bjk.banned mustmatch`$();
    first[.tst.logged] mustlike"The pitboss suspects a_5 of counting cards*";
  };
  should["tells the player, takes them off the table and closes their connection when ejection is on"]{
    .tst.msgs:();
    `.bjk.sendMsg mock {.tst.msgs,:enlist(x;y)};
    `.log.warn mock {[x]};
    .tst.closed:();
    `.bjk.disconnect mock {.tst.closed,:x};
    .bjk.ejectCounters:1b;
    .bjk.users:enlist[5i]!enlist`alice;
    .bjk.banned:`$();
    .bjk.eject .tst.uid 5;
    .bjk.banned mustmatch enlist`alice;
    .tst.msgs mustmatch enlist("The pitboss has asked you to leave the table";5i);
    .tst.left mustmatch enlist 5i;
    .tst.closed mustmatch enlist 5i;
  };
  should["ignores a player who isn't at the table, e.g. one who has already left"]{
    `.bjk.disconnect mock {};
    .bjk.ejectCounters:1b;
    .bjk.eject .tst.uid 9;
    count[.tst.left] musteq 0;
  };
  should["leaves alone a newcomer who has been given a departed suspect's handle"]{
    `.bjk.disconnect mock {};
    .bjk.ejectCounters:1b;
    .bjk.uids:enlist[5i]!enlist .tst.uid 15;
    .bjk.eject .tst.uid 5;
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
    .bjk.users:("i"$())!`$();
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
    .bjk.chips:("i"$())!"f"$();
    .bjk.regConn[42i];
    (42i in key .bjk.chips) musteq 0b;
    .bjk.buyIn[42i;500f];
    .bjk.chips[42i] musteq 500f;
    .bjk.unseat 42i;
    (42i in key .bjk.chips) musteq 0b;
  };
  should["counts what a player has on the table, bets and insurance, against their chips"]{
    .bjk.chips:(0 1i)!100 50f;
    .bjk.tab:update insurance:5 0f from ([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16i;dealer:`5;dealerCnt:5i;bet:10 20;return:0n;profit:0n;split:0b;double:0b;insurance:0f;out:0b;wait:0b;turn:10b);
    .bjk.committed[0i] musteq 15f;
    .bjk.available[0i] musteq 85f;
  };
 };

.tst.desc[".bjk.betPrompt"]{
  before{.bjk.rules:`maxSplitHands`deckCnt`minBet`maxBet`minBuyIn!4 6 10 500 100};
  should["asks for a bet and shows the player's chips"]{
    .tst.msgs:();
    `.bjk.prompt mock {[x;y].tst.msgs,:enlist x};
    .bjk.chips:enlist[7i]!enlist 512.5;
    .bjk.betPrompt 7i;
    .tst.msgs mustmatch enlist"Please place your bets via the stake[] function, $10 to $500; your chips: $512.50";
  };
  should["tells a player who can't afford the minimum bet that they're out of chips"]{
    .tst.msgs:();
    `.bjk.prompt mock {[x;y].tst.msgs,:enlist x};
    .bjk.chips:enlist[7i]!enlist 8f;
    .bjk.chipsDue:("i"$())!"p"$();
    .bjk.timeout:0D00:00:15;
    .bjk.betPrompt 7i;
    .tst.msgs mustmatch enlist"You're out of chips: buyin[amount] within 15 seconds, or you'll be asked to leave";
    (.bjk.chipsDue[7i]>.z.p) musteq 1b;
  };
 };

.tst.desc[".bjk.clientState chips"]{
  should["pushes the player their own chips"]{
    .bjk.chips:(5 6i)!250 80f;
    .bjk.clientState[6i][`chips] musteq 80f;
  };
  should["pushes the player what they've bought in total"]{
    .bjk.bought:5 6i!1000 300f;
    .bjk.clientState[6i][`bought] musteq 300f;
  };
 };

.tst.desc[".bjk.logLeaver chips"]{
  should["says what a player leaves with, less anything lost on a hand in play"]{
    .tst.msgs:();
    `.log.info mock {.tst.msgs,:enlist raze x};
    .bjk.hist:.bjk.res:([]round:"j"$();handle:"i"$();uid:"g"$();profit:"f"$());
    .bjk.uids:enlist[0i]!enlist .tst.uid 0;
    .bjk.cp:enlist[0i]!enlist`p1;
    .bjk.chips:enlist[0i]!enlist 300f;
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16i;dealer:`5;dealerCnt:5i;bet:10 20;return:0n;profit:0n;split:0b;double:0b;insurance:0f;out:0b;wait:0b;turn:10b);
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
    `.bjk.prompt mock {[x;y].tst.msgs,:enlist x};
    .bjk.rules:`maxSplitHands`deckCnt`minBet`maxBet`minBuyIn!4 6 10 500 100;
    .bjk.chips:("i"$())!"f"$();
    .bjk.chipsDue:("i"$())!"p"$();
    .bjk.timeout:0D00:00:15;
    .bjk.betPrompt 7i;
    .tst.msgs mustmatch enlist"Please buy some chips: buyin[amount] within 15 seconds, or you'll be asked to leave";
    (.bjk.chipsDue[7i]>.z.p) musteq 1b;
  };
 };

.tst.desc[".bjk.chipsTimer"]{
  should["asks every player past their buy-in deadline to leave, and nobody else"]{
    .tst.asked:();
    `.bjk.askToLeave mock {.tst.asked,:x};
    .bjk.chipsDue:(5 6i)!(.z.p-0D00:00:01;.z.p+0D00:00:10);
    .bjk.chipsTimer[];
    .tst.asked mustmatch enlist 5i;
  };
 };

.tst.desc[".bjk.askToLeave"]{
  should["tells the player why, takes them off the table and closes their connection"]{
    `.log.info mock {[x]};
    .tst.msgs:();
    `.bjk.sendMsg mock {.tst.msgs,:enlist(x;y)};
    .tst.left:();
    `.bjk.leave mock {.tst.left,:x};
    .tst.closed:();
    `.bjk.disconnect mock {.tst.closed,:x};
    .bjk.cp:enlist[5i]!enlist`a_5;
    .bjk.askToLeave 5i;
    .tst.msgs mustmatch enlist("You've been asked to leave the table: no chips";5i);
    .tst.left mustmatch enlist 5i;
    .tst.closed mustmatch enlist 5i;
  };
 };

.tst.desc[".bjk.chipsDue"]{
  should["forgets a player's buy-in deadline when they leave"]{
    .bjk.chipsDue:enlist[42i]!enlist .z.p;
    .bjk.unseat 42i;
    (42i in key .bjk.chipsDue) musteq 0b;
  };
 };

.tst.desc[".z.ts buy-in clock"]{
  should["drives the buy-in clock"]{
    .tst.calls:0;
    `.bjk.betTimer mock {};
    `.bjk.insureTimer mock {};
    `.bjk.turnTimer mock {};
    `.bjk.chipsTimer mock {.tst.calls+:1};
    .z.ts[.z.p];
    .tst.calls musteq 1;
  };
 };

.tst.desc[".bjk.chipsWindow"]{
  should["opens once: a later round's prompt doesn't move the deadline or repeat the warning"]{
    .tst.msgs:();
    `.bjk.sendMsg mock {[x;y].tst.msgs,:enlist x};
    .bjk.timeout:0D00:00:15;
    .bjk.chips:("i"$())!"f"$();
    due:.z.p+0D00:00:02;
    .bjk.chipsDue:enlist[7i]!enlist due;
    .bjk.chipsWindow 7i;
    .bjk.chipsDue[7i] musteq due;
    count[.tst.msgs] musteq 0;
  };
 };

.tst.desc[".bjk.leave pitboss"]{
  before{
    `.bjk.logLeaver mock {};
    `.bjk.dealIfReady mock {};
    .tst.sent:();
    `.bjk.excFunc mock {.tst.sent,:enlist(x;y;z)};
    .bjk.hd:1b;
    .bjk.insuring:0b;
    .bjk.cp:enlist[5i]!enlist`alice_5;
    .bjk.uids:enlist[5i]!enlist .tst.uid 5;
    .bjk.tab:0#.bjk.tab;
    .bjk.stake:0#.bjk.stake;
  };
  should["tells the pitboss the leaver's id, so it can forget them"]{
    .bjk.pit:9i;
    .bjk.leave 5i;
    .tst.sent mustmatch enlist(`.pit.left;.tst.uid 5;9i);
  };
  should["tells no one when no pitboss is connected"]{
    .bjk.pit:0Ni;
    .bjk.leave 5i;
    count[.tst.sent] musteq 0;
  };
 };
