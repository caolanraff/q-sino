.utl.load`:src/server/bin/blackjack.q;
.utl.load each .bjk.libs;

.tst.desc["checks[]"]{
  should["returns 0b and does not act when it isn't the caller's turn"]{
    .tst.pubCalls:0;
    `.bjk.pubMsg mock {[x;y].tst.pubCalls+:1};
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bjk.tab:update out:00b,wait:00b,turn:01b from .bjk.tab;                                         / player2 (handle 1) has the turn, not .z.w (0)
    .bjk.checks[] musteq 0b;
    .tst.pubCalls musteq 1;
  };
  should["returns 0b when the turn holder's hand is already past 21"]{
    .tst.pubCalls:0;
    `.bjk.pubMsg mock {[x;y].tst.pubCalls+:1};
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:25 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bjk.tab:update out:00b,wait:00b,turn:10b from .bjk.tab;
    .bjk.checks[] musteq 0b;
    .tst.pubCalls musteq 1;
  };
  should["returns 1b when it is the caller's turn and the hand isn't bust"]{
    .tst.pubCalls:0;
    `.bjk.pubMsg mock {[x;y].tst.pubCalls+:1};
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bjk.tab:update out:00b,wait:00b,turn:10b from .bjk.tab;
    .bjk.checks[] musteq 1b;
    .tst.pubCalls musteq 0;
  };
 };

.tst.desc["stick[]"]{
  should["does nothing when checks[] fails"]{
    `.bjk.checks mock {0b};
    `.bjk.pubMsg mock {[x;y]};
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`8`8;cnt:enlist 16i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bjk.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bjk.tab;
    stick[];
    (exec first wait from .bjk.tab) musteq 0b;
    (exec first turn from .bjk.tab) musteq 1b;
  };
  should["passes the turn to the next eligible player and doesn't call .bjk.dealer[]"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.excFunc mock {[x;y;z]};
    .tst.dealerCalls:0;
    `.bjk.dealer mock {.tst.dealerCalls+:1};
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bjk.tab:update out:00b,wait:00b,turn:10b from .bjk.tab;
    .bjk.cp:0 1i!`p1`p2;
    stick[];
    (exec first wait from .bjk.tab where player=1) musteq 1b;
    (exec first turn from .bjk.tab where player=1) musteq 0b;
    (exec first turn from .bjk.tab where player=2) musteq 1b;
    .tst.dealerCalls musteq 0;
  };
  should["calls .bjk.dealer[] when the sticking player was the last one with a turn"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    .tst.dealerCalls:0;
    `.bjk.dealer mock {.tst.dealerCalls+:1};
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`8`8;cnt:enlist 16i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bjk.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bjk.tab;
    .bjk.cp:enlist[0i]!enlist`p1;
    stick[];
    (exec first wait from .bjk.tab) musteq 1b;
    .tst.dealerCalls musteq 1;
  };
  should["triggers an async play prompt for the next player, addressed to their own handle"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    .tst.excFuncCalls:();
    `.bjk.excFunc mock {.tst.excFuncCalls,:enlist(x;z)};
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bjk.tab:update out:00b,wait:00b,turn:10b from .bjk.tab;
    .bjk.cp:0 1i!`p1`p2;
    stick[];
    .tst.excFuncCalls mustmatch enlist(`.plr.play;1i);
  };
 };

.tst.desc["hit[] / .bjk.dealTo / .bjk.hit1"]{
  should["does nothing when checks[] fails"]{
    `.bjk.checks mock {0b};
    .tst.getCardCalls:0;
    `.bjk.getCard mock {.tst.getCardCalls+:1;`5};
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`7`6;cnt:enlist 13i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bjk.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bjk.tab;
    hit[];
    .tst.getCardCalls musteq 0;
    (exec first cnt from .bjk.tab) musteq 13i;
  };
  should["adds a card and updates the count for a hand under 21"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.excFunc mock {[x;y;z]};
    `.bjk.getCard mock {`5};
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`7`6;`9`7);cnt:13 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bjk.tab:update out:00b,wait:00b,turn:10b from .bjk.tab;
    .bjk.cp:0 1i!`p1`p2;
    .bjk.double:0b;
    hit[];
    (exec first cards from .bjk.tab where player=1) mustmatch`7`6`5;
    (exec first cnt from .bjk.tab where player=1) musteq 18i;
    (exec first turn from .bjk.tab where player=1) musteq 1b;
  };
  should["automatically sticks on exactly 21 and passes the turn"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.excFunc mock {[x;y;z]};
    `.bjk.getCard mock {`6};
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`7`8;`9`7);cnt:15 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bjk.tab:update out:00b,wait:00b,turn:10b from .bjk.tab;
    .bjk.cp:0 1i!`p1`p2;
    .bjk.double:0b;
    hit[];
    (exec first cnt from .bjk.tab where player=1) musteq 21i;
    (exec first wait from .bjk.tab where player=1) musteq 1b;
    (exec first turn from .bjk.tab where player=1) musteq 0b;
    (exec first turn from .bjk.tab where player=2) musteq 1b;
  };
  should["busts the hand and passes the turn to the next player when one remains"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.excFunc mock {[x;y;z]};
    `.bjk.getCard mock {`10};
    .tst.dealerCalls:0;
    `.bjk.dealer mock {.tst.dealerCalls+:1};
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`7`8;`9`7);cnt:15 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bjk.tab:update out:00b,wait:00b,turn:10b from .bjk.tab;
    .bjk.cp:enlist[0i]!enlist`p1;
    .bjk.double:0b;
    hit[];
    (exec first return from .bjk.tab where player=1) musteq 0f;
    (exec first out from .bjk.tab where player=1) musteq 1b;
    (exec first turn from .bjk.tab where player=1) musteq 0b;
    (exec first turn from .bjk.tab where player=2) musteq 1b;
    .tst.dealerCalls musteq 0;
  };
  should["busts the hand and calls .bjk.dealer[] when no player has a turn left"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.getCard mock {`10};
    .tst.dealerCalls:0;
    `.bjk.dealer mock {.tst.dealerCalls+:1};
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`7`8;cnt:enlist 15i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bjk.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bjk.tab;
    .bjk.cp:enlist[0i]!enlist`p1;
    .bjk.double:0b;
    hit[];
    (exec first out from .bjk.tab) musteq 1b;
    .tst.dealerCalls musteq 1;
  };
  should["reduces the count by 10 when a newly-drawn ace would otherwise bust the hand"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.getCard mock {`A};
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`10`9;cnt:enlist 19i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bjk.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bjk.tab;
    .bjk.dealTo 1f;
    (exec first cnt from .bjk.tab) musteq 20i;
  };
  should["reduces the count by 10 for an existing ace when a later card busts the hand"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.getCard mock {`5};
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`9;cnt:enlist 20i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bjk.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bjk.tab;
    .bjk.dealTo 1f;
    (exec first cnt from .bjk.tab) musteq 15i;
  };
 };

.tst.desc["hit[] on split hands"]{
  should["busting one split hand leaves the player's other split hand live and gives it the turn"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.excFunc mock {[x;y;z]};
    `.bjk.getCard mock {`10};
    .tst.dealerCalls:0;
    `.bjk.dealer mock {.tst.dealerCalls+:1};
    .bjk.dc:`9`7;
    .bjk.tab:([]round:1 1;player:1.01 1.02;name:`p1`p1;handle:0 0i;cards:(`8`10;`8`3);cnt:18 11i;dealer:(`9;`9);dealerCnt:9 9i;bet:10 10f;return:0n 0n;profit:0n 0n;split:11b;double:00b);
    .bjk.tab:update out:00b,wait:00b,turn:10b from .bjk.tab;
    .bjk.cp:enlist[0i]!enlist`p1;
    .bjk.double:0b;
    hit[];
    (exec first out from .bjk.tab where player=1.01) musteq 1b;
    (exec first out from .bjk.tab where player=1.02) musteq 0b;
    (exec first turn from .bjk.tab where player=1.02) musteq 1b;
    .tst.dealerCalls musteq 0;
  };
  should["refuses to hit a split ace hand, which stands on its one card"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.excFunc mock {[x;y;z]};
    .tst.cardseq:`5`A`10;                                                                          / hand 1 gets 5 (A,5), hand 2 gets A (A,A); the 10 must never be drawn
    `.bjk.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`A`A;`9`7);cnt:12 16i;dealer:(`9;`9);dealerCnt:9 9i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bjk.tab:update out:00b,wait:00b,turn:10b from .bjk.tab;
    .bjk.cp:0 1i!`p1`p2;
    .bjk.double:0b;
    split[];
    hit[];
    (exec first cards from .bjk.tab where player=1) mustmatch`A`5;
    (exec first cnt from .bjk.tab where player=1) musteq 16i;
    (exec first cnt from .bjk.tab where player=1.01) musteq 12i;
    .tst.cardseq mustmatch enlist`10;
  };
 };

.tst.desc["double[]"]{
  should["does nothing when checks[] fails"]{
    `.bjk.checks mock {0b};
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`7`8;cnt:enlist 15i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bjk.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bjk.tab;
    double[];
    (exec first bet from .bjk.tab) musteq 10f;
    .bjk.double musteq 0b;
  };
  should["refuses to double after a third card has been dealt"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`7`8`2;cnt:enlist 17i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bjk.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bjk.tab;
    double[];
    (exec first bet from .bjk.tab) musteq 10f;
    .bjk.double musteq 0b;
  };
  should["doubles the bet, deals exactly one card, and always sticks afterwards"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.getCard mock {`5};
    .tst.dealerCalls:0;
    `.bjk.dealer mock {.tst.dealerCalls+:1};
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`7`8;cnt:enlist 15i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bjk.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bjk.tab;
    .bjk.cp:enlist[0i]!enlist`p1;
    double[];
    (exec first bet from .bjk.tab) musteq 20f;
    (exec first double from .bjk.tab) musteq 1b;
    (exec first cards from .bjk.tab) mustmatch`7`8`5;
    (exec first wait from .bjk.tab) musteq 1b;
    .bjk.double musteq 0b;
    .tst.dealerCalls musteq 1;
  };
 };

.tst.desc["split[] / .bjk.split0 / .bjk.dealTo"]{
  should["does nothing when checks[] fails"]{
    `.bjk.checks mock {0b};
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`10`9;cnt:enlist 19i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bjk.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bjk.tab;
    split[];
    count[.bjk.tab] musteq 1;
  };
  should["refuses to split a hand whose two cards aren't the same rank"]{
    `.bjk.sendMsg mock {[x;y]};
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`10`9;`9`7);cnt:19 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bjk.tab:update out:00b,wait:00b,turn:10b from .bjk.tab;
    .bjk.cp:enlist[0i]!enlist`p1;
    split[];
    count[.bjk.tab] musteq 2;
    (exec first split from .bjk.tab where player=1) musteq 0b;
  };
  should["scores each split ace hand from its ace and new card"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.excFunc mock {[x;y;z]};
    `.bjk.getCard mock {`2};
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`A`A;`9`7);cnt:12 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bjk.tab:update out:00b,wait:00b,turn:10b from .bjk.tab;
    .bjk.cp:enlist[0i]!enlist`p1;
    split[];
    count[.bjk.tab] musteq 3;
    asc[exec cnt from .bjk.tab where player in 1 1.01] musteq 13 13i;
    (exec cards from .bjk.tab where player=1) mustmatch enlist`A`2;
  };
  should["refuses to split a hand of more than two cards, even if every card matches"]{
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.pubMsg mock {[x;y]};
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`5`5`5;`9`7);cnt:15 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bjk.tab:update out:00b,wait:00b,turn:10b from .bjk.tab;
    .bjk.cp:0 1i!`p1`p2;
    split[];
    count[.bjk.tab] musteq 2;
    (exec first cards from .bjk.tab where player=1) mustmatch`5`5`5;
    (exec first split from .bjk.tab where player=1) musteq 0b;
  };
  should["refuses a fourth split once the player already has four hands"]{
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.pubMsg mock {[x;y]};
    .bjk.tab:([]round:1 1 1 1 1;player:1.01 1.02 1.03 1.04 2;name:`p1`p1`p1`p1`p2;handle:0 0 0 0 1i;cards:(`8`8;`8`3;`8`10;`8`2;`9`7);cnt:16 11 18 10 16i;dealer:5#`5;dealerCnt:5#5i;bet:5#10f;return:5#0n;profit:5#0n;split:11110b;double:00000b);
    .bjk.tab:update out:00000b,wait:00000b,turn:10000b from .bjk.tab;
    .bjk.cp:0 1i!`p1`p2;
    split[];
    count[.bjk.tab] musteq 5;
    (exec first cards from .bjk.tab where player=1.01) mustmatch`8`8;
  };
  should["allows a re-split while the player has fewer than four hands"]{
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.excFunc mock {[x;y;z]};
    `.bjk.getCard mock {`3};
    .bjk.tab:([]round:1 1 1;player:1.01 1.02 2;name:`p1`p1`p2;handle:0 0 1i;cards:(`8`8;`8`3;`9`7);cnt:16 11 16i;dealer:3#`5;dealerCnt:3#5i;bet:3#10f;return:3#0n;profit:3#0n;split:110b;double:000b);
    .bjk.tab:update out:000b,wait:000b,turn:100b from .bjk.tab;
    .bjk.cp:0 1i!`p1`p2;
    split[];
    count[select from .bjk.tab where handle=0i] musteq 3;
  };
  should["deals each split ace one card, stands both hands, and passes the turn on"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    .tst.excFuncCalls:();
    `.bjk.excFunc mock {.tst.excFuncCalls,:enlist(x;z)};
    .tst.cardseq:`K`7;
    `.bjk.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`A`A;`9`7);cnt:12 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bjk.tab:update out:00b,wait:00b,turn:10b from .bjk.tab;
    .bjk.cp:0 1i!`p1`p2;
    split[];
    (exec cards from .bjk.tab where player in 1 1.01) mustmatch (`A`K;`A`7);
    (exec cnt from .bjk.tab where player in 1 1.01) musteq 21 18i;
    (exec wait from .bjk.tab where player in 1 1.01) musteq 11b;
    (exec turn from .bjk.tab where player in 1 1.01) musteq 00b;
    (exec first turn from .bjk.tab where player=2) musteq 1b;
    .tst.excFuncCalls mustmatch enlist(`.plr.play;1i);
  };
  should["goes to the dealer after split aces when nobody else is left to act"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.getCard mock {`9};
    .tst.dealerCalls:0;
    `.bjk.dealer mock {.tst.dealerCalls+:1};
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`A;cnt:enlist 12i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bjk.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bjk.tab;
    .bjk.cp:enlist[0i]!enlist`p1;
    split[];
    (exec wait from .bjk.tab) musteq 11b;
    .tst.dealerCalls musteq 1;
  };
  should["splits a pair into two one-card hands, each dealt a new card"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.excFunc mock {[x;y;z]};
    .tst.cardseq:`3`4;
    `.bjk.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bjk.tab:update out:00b,wait:00b,turn:10b from .bjk.tab;
    .bjk.cp:0 1i!`p1`p2;
    split[];
    count[.bjk.tab] musteq 3;
    `splithand mustnin cols .bjk.tab;
    (exec first cards from .bjk.tab where player=1) mustmatch`8`3;
    (exec first cnt from .bjk.tab where player=1) musteq 11i;
    (exec first cards from .bjk.tab where player=1.01) mustmatch`8`4;
    (exec first cnt from .bjk.tab where player=1.01) musteq 12i;
    (exec first turn from .bjk.tab where player=1) musteq 1b;
    (exec first turn from .bjk.tab where player=1.01) musteq 0b;
    (exec first cards from .bjk.tab where player=2) mustmatch`9`7;
  };
 };

.tst.desc["split[] out of turn"]{
  should["only reports the turn problem, without checking the turn hand for a split"]{
    .tst.msgs:();
    `.bjk.pubMsg mock {[x;y].tst.msgs,:enlist x};
    `.bjk.sendMsg mock {[x;y].tst.msgs,:enlist x};
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`7;`K`9);cnt:16 19i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bjk.tab:update out:00b,wait:00b,turn:01b from .bjk.tab;
    split[];
    count[.tst.msgs] musteq 1;
    first[.tst.msgs] mustlike "*trying to play ahead of their turn";
    count[.bjk.tab] musteq 2;
  };
 };

.tst.desc[".bjk.promptPlay"]{
  should["starts the turn clock and prompts the given handle to play"]{
    .tst.sent:();
    `.bjk.excFunc mock {.tst.sent,:enlist(x;z)};
    .bjk.turnTimeout:0D00:00:15;
    .bjk.turnDeadline:0Np;
    .bjk.promptPlay 7i;
    (.bjk.turnDeadline within .z.p+0D00:00:14 0D00:00:15) musteq 1b;
    .tst.sent mustmatch enlist(`.plr.play;7i);
  };
 };

.tst.desc[".bjk.giveTurn"]{
  should["tells the player how long they have per move, then prompts them"]{
    .tst.msgs:();
    `.bjk.sendMsg mock {.tst.msgs,:enlist(x;y)};
    .tst.prompted:();
    `.bjk.promptPlay mock {.tst.prompted,:x};
    .bjk.turnTimeout:0D00:00:15;
    .bjk.giveTurn 7i;
    .tst.msgs mustmatch enlist("You have 15 seconds per move";7i);
    .tst.prompted mustmatch enlist 7i;
  };
 };

.tst.desc[".bjk.turnTimer"]{
  should["does nothing while no turn clock is running"]{
    .tst.stands:0;
    `.bjk.stand mock {.tst.stands+:1};
    .bjk.turnDeadline:0Np;
    .bjk.turnTimer[];
    .tst.stands musteq 0;
  };
  should["does nothing before the deadline"]{
    .tst.stands:0;
    `.bjk.stand mock {.tst.stands+:1};
    .bjk.turnDeadline:.z.p+0D00:00:10;
    .bjk.turnTimer[];
    .tst.stands musteq 0;
  };
  should["stands the hand whose turn it is once the deadline passes, and says so"]{
    .tst.msgs:();
    `.bjk.pubMsg mock {[x;y].tst.msgs,:enlist x};
    `.bjk.nextTurn mock {};
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bjk.tab:update out:00b,wait:00b,turn:01b from .bjk.tab;
    .bjk.cp:0 1i!`p1`p2;
    .bjk.turnDeadline:.z.p-0D00:00:01;
    .bjk.turnTimer[];
    (exec wait from .bjk.tab) musteq 01b;
    (exec turn from .bjk.tab) musteq 00b;
    .tst.msgs mustmatch enlist"p2 took too long - standing";
    .bjk.turnDeadline musteq 0Np;
  };
  should["just clears the clock when no hand has the turn"]{
    .tst.stands:0;
    `.bjk.stand mock {.tst.stands+:1};
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bjk.tab:update out:00b,wait:00b,turn:00b from .bjk.tab;
    .bjk.turnDeadline:.z.p-0D00:00:01;
    .bjk.turnTimer[];
    .tst.stands musteq 0;
    .bjk.turnDeadline musteq 0Np;
  };
  should["restarts after each move, since a hit that doesn't end the hand prompts again"]{
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.excFunc mock {[x;y;z]};
    .bjk.double:0b;
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 15i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bjk.tab:update out:00b,wait:00b,turn:01b from .bjk.tab;
    .bjk.turnTimeout:0D00:00:15;
    .bjk.turnDeadline:.z.p-0D00:00:01;
    .bjk.hit1[];
    (.bjk.turnDeadline>.z.p) musteq 1b;
  };
 };
