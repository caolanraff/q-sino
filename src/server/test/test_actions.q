system"l src/server/bin/blackjackServer.q";
.bs.loadLibs[];

.tst.desc["checks[]"]{
  should["returns 0b and does not act when it isn't the caller's turn"]{
    .tst.pubCalls:0;
    `.bs.pubMsg mock {[x;y].tst.pubCalls+:1};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:01b from .bs.tab;                                         / player2 (handle 1) has the turn, not .z.w (0)
    .bs.checks[] musteq 0b;
    .tst.pubCalls musteq 1;
  };
  should["returns 0b when the turn holder's hand is already past 21"]{
    .tst.pubCalls:0;
    `.bs.pubMsg mock {[x;y].tst.pubCalls+:1};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:25 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    .bs.checks[] musteq 0b;
    .tst.pubCalls musteq 1;
  };
  should["returns 1b when it is the caller's turn and the hand isn't bust"]{
    .tst.pubCalls:0;
    `.bs.pubMsg mock {[x;y].tst.pubCalls+:1};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    .bs.checks[] musteq 1b;
    .tst.pubCalls musteq 0;
  };
 };

.tst.desc["stick[]"]{
  should["does nothing when checks[] fails"]{
    `.bs.checks mock {0b};
    `.bs.pubMsg mock {[x;y]};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`8`8;cnt:enlist 16i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bs.tab;
    stick[];
    (exec first wait from .bs.tab) musteq 0b;
    (exec first turn from .bs.tab) musteq 1b;
  };
  should["passes the turn to the next eligible player and doesn't call .bs.dealer[]"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    `.bs.excFunc mock {[x;y;z]};
    .tst.dealerCalls:0;
    `.bs.dealer mock {.tst.dealerCalls+:1};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    .bs.cp:0 1i!`p1`p2;
    stick[];
    (exec first wait from .bs.tab where player=1) musteq 1b;
    (exec first turn from .bs.tab where player=1) musteq 0b;
    (exec first turn from .bs.tab where player=2) musteq 1b;
    .tst.dealerCalls musteq 0;
  };
  should["calls .bs.dealer[] when the sticking player was the last one with a turn"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .tst.dealerCalls:0;
    `.bs.dealer mock {.tst.dealerCalls+:1};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`8`8;cnt:enlist 16i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    stick[];
    (exec first wait from .bs.tab) musteq 1b;
    .tst.dealerCalls musteq 1;
  };
  should["triggers an async play prompt for the next player, addressed to their own handle"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .tst.excFuncCalls:();
    `.bs.excFunc mock {[x;y;z].tst.excFuncCalls,:enlist(x;z)};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    .bs.cp:0 1i!`p1`p2;
    stick[];
    .tst.excFuncCalls mustmatch enlist(`.mc.play;1i);
  };
 };

.tst.desc["hit[] / .bs.hit0 / .bs.hit1"]{
  should["does nothing when checks[] fails"]{
    `.bs.checks mock {0b};
    .tst.getCardCalls:0;
    `.bs.getCard mock {.tst.getCardCalls+:1;`5};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`7`6;cnt:enlist 13i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bs.tab;
    hit[];
    .tst.getCardCalls musteq 0;
    (exec first cnt from .bs.tab) musteq 13i;
  };
  should["adds a card and updates the count for a hand under 21"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    `.bs.excFunc mock {[x;y;z]};
    `.bs.getCard mock {`5};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`7`6;`9`7);cnt:13 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    .bs.cp:0 1i!`p1`p2;
    .bs.double:0b;
    hit[];
    (exec first cards from .bs.tab where player=1) mustmatch`7`6`5;
    (exec first cnt from .bs.tab where player=1) musteq 18i;
    (exec first turn from .bs.tab where player=1) musteq 1b;
  };
  should["automatically sticks on exactly 21 and passes the turn"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    `.bs.excFunc mock {[x;y;z]};
    `.bs.getCard mock {`6};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`7`8;`9`7);cnt:15 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    .bs.cp:0 1i!`p1`p2;
    .bs.double:0b;
    hit[];
    (exec first cnt from .bs.tab where player=1) musteq 21i;
    (exec first wait from .bs.tab where player=1) musteq 1b;
    (exec first turn from .bs.tab where player=1) musteq 0b;
    (exec first turn from .bs.tab where player=2) musteq 1b;
  };
  should["busts the hand and passes the turn to the next player when one remains"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    `.bs.excFunc mock {[x;y;z]};
    `.bs.getCard mock {`10};
    .tst.dealerCalls:0;
    `.bs.dealer mock {.tst.dealerCalls+:1};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`7`8;`9`7);cnt:15 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    .bs.double:0b;
    hit[];
    (exec first return from .bs.tab where player=1) musteq 0f;
    (exec first out from .bs.tab where player=1) musteq 1b;
    (exec first turn from .bs.tab where player=1) musteq 0b;
    (exec first turn from .bs.tab where player=2) musteq 1b;
    .tst.dealerCalls musteq 0;
  };
  should["busts the hand and calls .bs.dealer[] when no player has a turn left"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.getCard mock {`10};
    .tst.dealerCalls:0;
    `.bs.dealer mock {.tst.dealerCalls+:1};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`7`8;cnt:enlist 15i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    .bs.double:0b;
    hit[];
    (exec first out from .bs.tab) musteq 1b;
    .tst.dealerCalls musteq 1;
  };
  should["reduces the count by 10 when a newly-drawn ace would otherwise bust the hand"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.getCard mock {`A};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`10`9;cnt:enlist 19i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bs.tab;
    .bs.hit0[];
    (exec first cnt from .bs.tab) musteq 20i;
  };
  should["reduces the count by 10 for an existing ace when a later card busts the hand"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.getCard mock {`5};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`9;cnt:enlist 20i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bs.tab;
    .bs.hit0[];
    (exec first cnt from .bs.tab) musteq 15i;
  };
 };

.tst.desc["hit[] on split hands"]{
  should["busting one split hand leaves the player's other split hand live and gives it the turn"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    `.bs.excFunc mock {[x;y;z]};
    `.bs.getCard mock {`10};
    .tst.dealerCalls:0;
    `.bs.dealer mock {.tst.dealerCalls+:1};
    .bs.dc:`9`7;
    .bs.tab:([]round:1 1;player:1.01 1.02;name:`p1`p1;handle:0 0i;cards:(`8`10;`8`3);cnt:18 11i;dealer:(`9;`9);dealerCnt:9 9i;bet:10 10f;return:0n 0n;profit:0n 0n;split:11b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    .bs.double:0b;
    hit[];
    (exec first out from .bs.tab where player=1.01) musteq 1b;
    (exec first out from .bs.tab where player=1.02) musteq 0b;
    (exec first turn from .bs.tab where player=1.02) musteq 1b;
    .tst.dealerCalls musteq 0;
  };
  should["refuses to hit a split ace hand, which stands on its one card"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    `.bs.excFunc mock {[x;y;z]};
    .tst.cardseq:`5`A`10;                                                                          / hand 1 gets 5 (A,5), hand 2 gets A (A,A); the 10 must never be drawn
    `.bs.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`A`A;`9`7);cnt:12 16i;dealer:(`9;`9);dealerCnt:9 9i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    .bs.cp:0 1i!`p1`p2;
    .bs.double:0b;
    split[];
    hit[];
    (exec first cards from .bs.tab where player=1) mustmatch`A`5;
    (exec first cnt from .bs.tab where player=1) musteq 16i;
    (exec first cnt from .bs.tab where player=1.01) musteq 12i;
    .tst.cardseq mustmatch enlist`10;
  };
 };

.tst.desc["double[]"]{
  should["does nothing when checks[] fails"]{
    `.bs.checks mock {0b};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`7`8;cnt:enlist 15i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bs.tab;
    double[];
    (exec first bet from .bs.tab) musteq 10f;
    .bs.double musteq 0b;
  };
  should["refuses to double after a third card has been dealt"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`7`8`2;cnt:enlist 17i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bs.tab;
    double[];
    (exec first bet from .bs.tab) musteq 10f;
    .bs.double musteq 0b;
  };
  should["doubles the bet, deals exactly one card, and always sticks afterwards"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    `.bs.getCard mock {`5};
    .tst.dealerCalls:0;
    `.bs.dealer mock {.tst.dealerCalls+:1};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`7`8;cnt:enlist 15i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    double[];
    (exec first bet from .bs.tab) musteq 20f;
    (exec first double from .bs.tab) musteq 1b;
    (exec first cards from .bs.tab) mustmatch`7`8`5;
    (exec first wait from .bs.tab) musteq 1b;
    .bs.double musteq 0b;
    .tst.dealerCalls musteq 1;
  };
 };

.tst.desc["split[] / .bs.split0 / .bs.dealTo"]{
  should["does nothing when checks[] fails"]{
    `.bs.checks mock {0b};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`10`9;cnt:enlist 19i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bs.tab;
    split[];
    count[.bs.tab] musteq 1;
  };
  should["refuses to split a hand whose two cards aren't the same rank"]{
    `.bs.sendMsg mock {[x;y]};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`10`9;`9`7);cnt:19 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    split[];
    count[.bs.tab] musteq 2;
    (exec first split from .bs.tab where player=1) musteq 0b;
  };
  should["scores each split ace hand from its ace and new card"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.excFunc mock {[x;y;z]};
    `.bs.getCard mock {`2};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`A`A;`9`7);cnt:12 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    split[];
    count[.bs.tab] musteq 3;
    asc[exec cnt from .bs.tab where player in 1 1.01] musteq 13 13i;
    (exec cards from .bs.tab where player=1) mustmatch enlist`A`2;
  };
  should["refuses to split a hand of more than two cards, even if every card matches"]{
    `.bs.sendMsg mock {[x;y]};
    `.bs.pubMsg mock {[x;y]};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`5`5`5;`9`7);cnt:15 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    .bs.cp:0 1i!`p1`p2;
    split[];
    count[.bs.tab] musteq 2;
    (exec first cards from .bs.tab where player=1) mustmatch`5`5`5;
    (exec first split from .bs.tab where player=1) musteq 0b;
  };
  should["refuses a fourth split once the player already has four hands"]{
    `.bs.sendMsg mock {[x;y]};
    `.bs.pubMsg mock {[x;y]};
    .bs.tab:([]round:1 1 1 1 1;player:1.01 1.02 1.03 1.04 2;name:`p1`p1`p1`p1`p2;handle:0 0 0 0 1i;cards:(`8`8;`8`3;`8`10;`8`2;`9`7);cnt:16 11 18 10 16i;dealer:5#`5;dealerCnt:5#5i;bet:5#10f;return:5#0n;profit:5#0n;split:11110b;double:00000b);
    .bs.tab:update out:00000b,wait:00000b,turn:10000b from .bs.tab;
    .bs.cp:0 1i!`p1`p2;
    split[];
    count[.bs.tab] musteq 5;
    (exec first cards from .bs.tab where player=1.01) mustmatch`8`8;
  };
  should["allows a re-split while the player has fewer than four hands"]{
    `.bs.sendMsg mock {[x;y]};
    `.bs.pubMsg mock {[x;y]};
    `.bs.excFunc mock {[x;y;z]};
    `.bs.getCard mock {`3};
    .bs.tab:([]round:1 1 1;player:1.01 1.02 2;name:`p1`p1`p2;handle:0 0 1i;cards:(`8`8;`8`3;`9`7);cnt:16 11 16i;dealer:3#`5;dealerCnt:3#5i;bet:3#10f;return:3#0n;profit:3#0n;split:110b;double:000b);
    .bs.tab:update out:000b,wait:000b,turn:100b from .bs.tab;
    .bs.cp:0 1i!`p1`p2;
    split[];
    count[select from .bs.tab where handle=0i] musteq 3;
  };
  should["deals each split ace one card, stands both hands, and passes the turn on"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .tst.excFuncCalls:();
    `.bs.excFunc mock {[x;y;z].tst.excFuncCalls,:enlist(x;z)};
    .tst.cardseq:`K`7;
    `.bs.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`A`A;`9`7);cnt:12 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    .bs.cp:0 1i!`p1`p2;
    split[];
    (exec cards from .bs.tab where player in 1 1.01) mustmatch (`A`K;`A`7);
    (exec cnt from .bs.tab where player in 1 1.01) musteq 21 18i;
    (exec wait from .bs.tab where player in 1 1.01) musteq 11b;
    (exec turn from .bs.tab where player in 1 1.01) musteq 00b;
    (exec first turn from .bs.tab where player=2) musteq 1b;
    .tst.excFuncCalls mustmatch enlist(`.mc.play;1i);
  };
  should["goes to the dealer after split aces when nobody else is left to act"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.getCard mock {`9};
    .tst.dealerCalls:0;
    `.bs.dealer mock {.tst.dealerCalls+:1};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`A;cnt:enlist 12i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    split[];
    (exec wait from .bs.tab) musteq 11b;
    .tst.dealerCalls musteq 1;
  };
  should["splits a pair into two one-card hands, each dealt a new card"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    `.bs.excFunc mock {[x;y;z]};
    .tst.cardseq:`3`4;
    `.bs.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    .bs.cp:0 1i!`p1`p2;
    split[];
    count[.bs.tab] musteq 3;
    `splithand mustnin cols .bs.tab;
    (exec first cards from .bs.tab where player=1) mustmatch`8`3;
    (exec first cnt from .bs.tab where player=1) musteq 11i;
    (exec first cards from .bs.tab where player=1.01) mustmatch`8`4;
    (exec first cnt from .bs.tab where player=1.01) musteq 12i;
    (exec first turn from .bs.tab where player=1) musteq 1b;
    (exec first turn from .bs.tab where player=1.01) musteq 0b;
    (exec first cards from .bs.tab where player=2) mustmatch`9`7;
  };
 };
