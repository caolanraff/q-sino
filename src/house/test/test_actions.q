.utl.load`:src/house/bin/blackjack.q;
.utl.load each .bjk.libs;

.tst.desc["checks[]"]{
  before{
    .tst.pubCalls:0;
    `.bjk.pubMsg mock {[x;y].tst.pubCalls+:1};
  };
  should["returns 0b and does not act when it isn't the caller's turn"]{
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:01b from .bjk.tab;                                         / player2 (handle 1) has the turn, not .z.w (0)
    .bjk.checks[] musteq 0b;
    .tst.pubCalls musteq 1;
  };
  should["returns 0b when the turn holder's hand is already past 21"]{
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:25 16i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:10b from .bjk.tab;
    .bjk.checks[] musteq 0b;
    .tst.pubCalls musteq 1;
  };
  should["returns 1b when it is the caller's turn and the hand isn't bust"]{
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:10b from .bjk.tab;
    .bjk.checks[] musteq 1b;
    .tst.pubCalls musteq 0;
  };
 };

.tst.desc["stick[]"]{
  before{
    `.bjk.pubMsg mock {[x;y]};
  };
  should["does nothing when checks[] fails"]{
    `.bjk.checks mock {0b};
    .bjk.tab:([]round:1;player:1f;name:`p1;handle:0i;cards:enlist`8`8;cnt:16i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:1b from .bjk.tab;
    stick[];
    (exec first wait from .bjk.tab) musteq 0b;
    (exec first turn from .bjk.tab) musteq 1b;
  };
  should["passes the turn to the next eligible player and doesn't call .bjk.dealer[]"]{
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.excFunc mock {[x;y;z]};
    .tst.dealerCalls:0;
    `.bjk.dealer mock {.tst.dealerCalls+:1};
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:10b from .bjk.tab;
    .bjk.cp:0 1i!`p1`p2;
    stick[];
    (exec first wait from .bjk.tab where player=1) musteq 1b;
    (exec first turn from .bjk.tab where player=1) musteq 0b;
    (exec first turn from .bjk.tab where player=2) musteq 1b;
    .tst.dealerCalls musteq 0;
  };
  should["calls .bjk.dealer[] when the sticking player was the last one with a turn"]{
    `.bjk.sendMsg mock {[x;y]};
    .tst.dealerCalls:0;
    `.bjk.dealer mock {.tst.dealerCalls+:1};
    .bjk.tab:([]round:1;player:1f;name:`p1;handle:0i;cards:enlist`8`8;cnt:16i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:1b from .bjk.tab;
    .bjk.cp:enlist[0i]!enlist`p1;
    stick[];
    (exec first wait from .bjk.tab) musteq 1b;
    .tst.dealerCalls musteq 1;
  };
  should["triggers an async play prompt for the next player, addressed to their own handle"]{
    `.bjk.sendMsg mock {[x;y]};
    .tst.excFuncCalls:();
    `.bjk.excFunc mock {.tst.excFuncCalls,:enlist(x;z)};
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:10b from .bjk.tab;
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
    .bjk.tab:([]round:1;player:1f;name:`p1;handle:0i;cards:enlist`7`6;cnt:13i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:1b from .bjk.tab;
    hit[];
    .tst.getCardCalls musteq 0;
    (exec first cnt from .bjk.tab) musteq 13i;
  };
  should["adds a card and updates the count for a hand under 21"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.excFunc mock {[x;y;z]};
    `.bjk.getCard mock {`5};
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`7`6;`9`7);cnt:13 16i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:10b from .bjk.tab;
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
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`7`8;`9`7);cnt:15 16i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:10b from .bjk.tab;
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
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`7`8;`9`7);cnt:15 16i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:10b from .bjk.tab;
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
    .bjk.tab:([]round:1;player:1f;name:`p1;handle:0i;cards:enlist`7`8;cnt:15i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:1b from .bjk.tab;
    .bjk.cp:enlist[0i]!enlist`p1;
    .bjk.double:0b;
    hit[];
    (exec first out from .bjk.tab) musteq 1b;
    .tst.dealerCalls musteq 1;
  };
  should["reduces the count by 10 when a newly-drawn ace would otherwise bust the hand"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.getCard mock {`A};
    .bjk.tab:([]round:1;player:1f;name:`p1;handle:0i;cards:enlist`10`9;cnt:19i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:1b from .bjk.tab;
    .bjk.dealTo 1f;
    (exec first cnt from .bjk.tab) musteq 20i;
  };
  should["reduces the count by 10 for an existing ace when a later card busts the hand"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.getCard mock {`5};
    .bjk.tab:([]round:1;player:1f;name:`p1;handle:0i;cards:enlist`A`9;cnt:20i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:1b from .bjk.tab;
    .bjk.dealTo 1f;
    (exec first cnt from .bjk.tab) musteq 15i;
  };
 };

.tst.desc["hit[] on split hands"]{
  before{
    `.bjk.available mock {1e9};
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.excFunc mock {[x;y;z]};
  };
  should["busting one split hand leaves the player's other split hand live and gives it the turn"]{
    `.bjk.getCard mock {`10};
    .tst.dealerCalls:0;
    `.bjk.dealer mock {.tst.dealerCalls+:1};
    .bjk.dc:`9`7;
    .bjk.tab:([]round:1;player:1.01 1.02;name:`p1;handle:0i;cards:(`8`10;`8`3);cnt:18 11i;dealer:`9;dealerCnt:9i;bet:10f;return:0n;profit:0n;split:1b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:10b from .bjk.tab;
    .bjk.cp:enlist[0i]!enlist`p1;
    .bjk.double:0b;
    hit[];
    (exec first out from .bjk.tab where player=1.01) musteq 1b;
    (exec first out from .bjk.tab where player=1.02) musteq 0b;
    (exec first turn from .bjk.tab where player=1.02) musteq 1b;
    .tst.dealerCalls musteq 0;
  };
  should["refuses to hit a split ace hand, which sticks on its one card"]{
    .tst.cardseq:`5`A`10;                                                                          / hand 1 gets 5 (A,5), hand 2 gets A (A,A); the 10 must never be drawn
    `.bjk.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`A`A;`9`7);cnt:12 16i;dealer:`9;dealerCnt:9i;bet:10f;return:0n;profit:0n;split:0b;double:0b;insurance:0f);
    .bjk.tab:update out:0b,wait:0b,turn:10b from .bjk.tab;
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
  before{`.bjk.available mock {1e9}};
  should["does nothing when checks[] fails"]{
    `.bjk.checks mock {0b};
    .bjk.tab:([]round:1;player:1f;name:`p1;handle:0i;cards:enlist`7`8;cnt:15i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:1b from .bjk.tab;
    double[];
    (exec first bet from .bjk.tab) musteq 10f;
    .bjk.double musteq 0b;
  };
  should["refuses to double after a third card has been dealt"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.tab:([]round:1;player:1f;name:`p1;handle:0i;cards:enlist`7`8`2;cnt:17i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:1b from .bjk.tab;
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
    .bjk.tab:([]round:1;player:1f;name:`p1;handle:0i;cards:enlist`7`8;cnt:15i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:1b from .bjk.tab;
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
  before{`.bjk.available mock {1e9}};
  should["does nothing when checks[] fails"]{
    `.bjk.checks mock {0b};
    .bjk.tab:([]round:1;player:1f;name:`p1;handle:0i;cards:enlist`10`9;cnt:19i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:1b from .bjk.tab;
    split[];
    count[.bjk.tab] musteq 1;
  };
  should["refuses to split a hand whose two cards aren't the same rank"]{
    `.bjk.sendMsg mock {[x;y]};
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`10`9;`9`7);cnt:19 16i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:10b from .bjk.tab;
    .bjk.cp:enlist[0i]!enlist`p1;
    split[];
    count[.bjk.tab] musteq 2;
    (exec first split from .bjk.tab where player=1) musteq 0b;
  };
  should["scores each split ace hand from its ace and new card"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.excFunc mock {[x;y;z]};
    `.bjk.getCard mock {`2};
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`A`A;`9`7);cnt:12 16i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b;insurance:0f);
    .bjk.tab:update out:0b,wait:0b,turn:10b from .bjk.tab;
    .bjk.cp:enlist[0i]!enlist`p1;
    split[];
    count[.bjk.tab] musteq 3;
    asc[exec cnt from .bjk.tab where player in 1 1.01] musteq 13 13i;
    (exec cards from .bjk.tab where player=1) mustmatch enlist`A`2;
  };
  should["keeps a hand's insurance on the first hand only, so it isn't charged twice"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.excFunc mock {[x;y;z]};
    `.bjk.hit1 mock {};
    `.bjk.getCard mock {`2};
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16i;dealer:`A;dealerCnt:11i;bet:100 10f;return:0n;profit:0n;split:0b;double:0b;insurance:50 0f);
    .bjk.tab:update out:0b,wait:0b,turn:10b from .bjk.tab;
    .bjk.cp:0 1i!`p1`p2;
    split[];
    (exec insurance from .bjk.tab where handle=0i) mustmatch 50 0f;
  };
  should["refuses to split a hand of more than two cards, even if every card matches"]{
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.pubMsg mock {[x;y]};
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`5`5`5;`9`7);cnt:15 16i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:10b from .bjk.tab;
    .bjk.cp:0 1i!`p1`p2;
    split[];
    count[.bjk.tab] musteq 2;
    (exec first cards from .bjk.tab where player=1) mustmatch`5`5`5;
    (exec first split from .bjk.tab where player=1) musteq 0b;
  };
  should["refuses a fourth split once the player already has four hands"]{
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.pubMsg mock {[x;y]};
    .bjk.tab:([]round:1;player:1.01 1.02 1.03 1.04 2;name:`p1`p1`p1`p1`p2;handle:0 0 0 0 1i;cards:(`8`8;`8`3;`8`10;`8`2;`9`7);cnt:16 11 18 10 16i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:11110b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:10000b from .bjk.tab;
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
    .bjk.tab:([]round:1;player:1.01 1.02 2;name:`p1`p1`p2;handle:0 0 1i;cards:(`8`8;`8`3;`9`7);cnt:16 11 16i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:110b;double:0b;insurance:0f);
    .bjk.tab:update out:0b,wait:0b,turn:100b from .bjk.tab;
    .bjk.cp:0 1i!`p1`p2;
    split[];
    count[select from .bjk.tab where handle=0i] musteq 3;
  };
  should["deals each split ace one card, sticks both hands, and passes the turn on"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    .tst.excFuncCalls:();
    `.bjk.excFunc mock {.tst.excFuncCalls,:enlist(x;z)};
    .tst.cardseq:`K`7;
    `.bjk.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`A`A;`9`7);cnt:12 16i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b;insurance:0f);
    .bjk.tab:update out:0b,wait:0b,turn:10b from .bjk.tab;
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
    .bjk.tab:([]round:1;player:1f;name:`p1;handle:0i;cards:enlist`A`A;cnt:12i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b;insurance:0f);
    .bjk.tab:update out:0b,wait:0b,turn:1b from .bjk.tab;
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
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b;insurance:0f);
    .bjk.tab:update out:0b,wait:0b,turn:10b from .bjk.tab;
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
  should["offers another split when a split hand is dealt a second card of the same value"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.excFunc mock {[x;y;z]};
    .tst.msgs:();
    `.bjk.prompt mock {.tst.msgs,:enlist(x;y)};
    .tst.cardseq:`8`4;
    `.bjk.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bjk.rules:`maxSplitHands`deckCnt`minBet`maxBet`minBuyIn!4 6 10 500 100;
    .bjk.double:0b;
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b;insurance:0f);
    .bjk.tab:update out:0b,wait:0b,turn:10b from .bjk.tab;
    .bjk.cp:0 1i!`p1`p2;
    split[];
    .tst.msgs mustmatch enlist("Hit, stick or split?";0i);
  };
 };

.tst.desc["split[] out of turn"]{
  should["only reports the turn problem, without checking the turn hand for a split"]{
    .tst.msgs:();
    `.bjk.pubMsg mock {[x;y].tst.msgs,:enlist x};
    `.bjk.sendMsg mock {[x;y].tst.msgs,:enlist x};
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`7;`K`9);cnt:16 19i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:01b from .bjk.tab;
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
    .bjk.timeout:0D00:00:15;
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
    `.bjk.prompt mock {.tst.msgs,:enlist(x;y)};
    `.bjk.pubMsg mock {.tst.msgs,:enlist(x;y)};
    .bjk.cp:7 8i!`alice`bob;
    .bjk.timeout:0D00:00:15;
    .bjk.tab:([]name:`alice`bob;handle:7 8i;cards:(`9`7;`8`8);turn:10b);
    .bjk.giveTurn 7i;
    .tst.msgs mustmatch (("It's alice's turn: 9,7 (16)";7 8i);("You have 15 seconds per move";7i);("Hit or stick?";7i));
    .tst.prompted mustmatch enlist 7i;
  };
  should["offers a split on a pair"]{
    `.bjk.sendMsg mock {[x;y]};
    .tst.msgs:();
    `.bjk.prompt mock {.tst.msgs,:enlist(x;y)};
    `.bjk.promptPlay mock {};
    `.bjk.pubMsg mock {[x;y]};
    .bjk.rules:`maxSplitHands`deckCnt`minBet`maxBet`minBuyIn!4 6 10 500 100;
    .bjk.chips:7 8i!2#1000f;
    .bjk.tab:([]name:`alice`bob;handle:7 8i;cards:(`9`7;`K`Q);bet:10;insurance:0f;turn:01b);
    .bjk.giveTurn 8i;
    .tst.msgs mustmatch enlist("Hit, stick or split?";8i);
  };
 };

.tst.desc[".bjk.playPrompt"]{
  before{
    .tst.msgs:();
    `.bjk.prompt mock {.tst.msgs,:enlist(x;y)};
    `.bjk.sendMsg mock {[x;y]};
    .bjk.rules:`maxSplitHands`deckCnt`minBet`maxBet`minBuyIn!4 6 10 500 100;
    .bjk.chips:7 8i!2#1000f;
  };
  should["offers a split on a pair the player can split"]{
    .bjk.tab:([]player:1 2f;name:`alice`bob;handle:7 8i;cards:(`9`7;`8`8);bet:10;insurance:0f;turn:01b);
    .bjk.playPrompt 8i;
    .tst.msgs mustmatch enlist("Hit, stick or split?";8i);
  };
  should["doesn't offer a split on a hand that isn't a pair"]{
    .bjk.tab:([]player:1 2f;name:`alice`bob;handle:7 8i;cards:(`9`7;`8`7);bet:10;insurance:0f;turn:01b);
    .bjk.playPrompt 8i;
    .tst.msgs mustmatch enlist("Hit or stick?";8i);
  };
  should["doesn't offer a split the player can't afford"]{
    .bjk.chips:7 8i!1000 15f;
    .bjk.tab:([]player:1 2f;name:`alice`bob;handle:7 8i;cards:(`9`7;`8`8);bet:10;insurance:0f;turn:01b);
    .bjk.playPrompt 8i;
    .tst.msgs mustmatch enlist("Hit or stick?";8i);
  };
  should["doesn't offer a split once the player has as many hands as the table allows"]{
    .bjk.rules[`maxSplitHands]:2;
    .bjk.tab:([]player:1 1.01;name:`bob;handle:8i;cards:(`8`8;`8`3);bet:10;insurance:0f;turn:10b);
    .bjk.playPrompt 8i;
    .tst.msgs mustmatch enlist("Hit or stick?";8i);
  };
 };

.tst.desc[".bjk.turnTimer"]{
  should["does nothing while no turn clock is running"]{
    .tst.sticks:0;
    `.bjk.stickHand mock {.tst.sticks+:1};
    .bjk.turnDeadline:0Np;
    .bjk.turnTimer[];
    .tst.sticks musteq 0;
  };
  should["does nothing before the deadline"]{
    .tst.sticks:0;
    `.bjk.stickHand mock {.tst.sticks+:1};
    .bjk.turnDeadline:.z.p+0D00:00:10;
    .bjk.turnTimer[];
    .tst.sticks musteq 0;
  };
  should["sticks the hand whose turn it is once the deadline passes, and says so"]{
    .tst.msgs:();
    `.bjk.pubMsg mock {[x;y].tst.msgs,:enlist x};
    `.bjk.nextTurn mock {};
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:01b from .bjk.tab;
    .bjk.cp:0 1i!`p1`p2;
    .bjk.turnDeadline:.z.p-0D00:00:01;
    .bjk.turnTimer[];
    (exec wait from .bjk.tab) musteq 01b;
    (exec turn from .bjk.tab) musteq 00b;
    (exec forced from .bjk.tab) musteq 01b;
    .tst.msgs mustmatch enlist"p2 took too long - sticking";
    .bjk.turnDeadline musteq 0Np;
  };
  should["just clears the clock when no hand has the turn"]{
    .tst.sticks:0;
    `.bjk.stickHand mock {.tst.sticks+:1};
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:0b from .bjk.tab;
    .bjk.turnDeadline:.z.p-0D00:00:01;
    .bjk.turnTimer[];
    .tst.sticks musteq 0;
    .bjk.turnDeadline musteq 0Np;
  };
  should["restarts after each move, since a hit that doesn't end the hand prompts again"]{
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.excFunc mock {[x;y;z]};
    .bjk.double:0b;
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 15i;dealer:`5;dealerCnt:5i;bet:10f;return:0n;profit:0n;split:0b;double:0b);
    .bjk.tab:update out:0b,wait:0b,turn:01b from .bjk.tab;
    .bjk.timeout:0D00:00:15;
    .bjk.turnDeadline:.z.p-0D00:00:01;
    .bjk.hit1[];
    (.bjk.turnDeadline>.z.p) musteq 1b;
  };
 };

.tst.desc["double[], split[] and insure[] chips"]{
  before{.bjk.rules:`maxSplitHands`deckCnt`minBet`maxBet`minBuyIn!4 6 10 500 100};
  should["refuses to double a bet the player can't cover"]{
    `.bjk.checks mock {1b};
    .tst.msgs:();
    `.bjk.pubMsg mock {[x;y].tst.msgs,:enlist x};
    `.bjk.available mock {5f};
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`5`6;`9`7);cnt:16i;dealer:`5;dealerCnt:5i;bet:10 20;return:0n;profit:0n;split:0b;double:0b;insurance:0f;out:0b;wait:0b;turn:10b);
    double[];
    (exec first bet from .bjk.tab where handle=0) musteq 10;
    first[.tst.msgs] mustlike"You can't afford to double*";
  };
  should["refuses to split a hand the player can't cover"]{
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.available mock {5f};
    .bjk.tab:([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16i;dealer:`5;dealerCnt:5i;bet:10 20;return:0n;profit:0n;split:0b;double:0b;insurance:0f;out:0b;wait:0b;turn:10b);
    .bjk.canSplit[] musteq 0b;
  };
  should["refuses more insurance than the player has left"]{
    .tst.msgs:();
    `.bjk.sendMsg mock {[x;y].tst.msgs,:enlist x};
    `.bjk.available mock {3f};
    .bjk.insuring:1b;
    .bjk.tab:update insurance:0n from ([]round:1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16i;dealer:`5;dealerCnt:5i;bet:10 20;return:0n;profit:0n;split:0b;double:0b;insurance:0f;out:0b;wait:0b;turn:10b);
    insure 5;
    .bjk.insuring:0b;
    (exec first insurance from .bjk.tab where handle=0) musteq 0n;
    .tst.msgs mustmatch enlist"You can't afford that much insurance";
  };
 };

.tst.desc[".bjk.checks during insurance"]{
  before{
    .tst.msgs:();
    `.bjk.sendMsg mock {.tst.msgs,:enlist(x;y)};
    `.bjk.pubMsg mock {[x;y]};
    .tst.declined:();
    .bjk.hd:0b;
    .bjk.insuring:1b;
    .bjk.tab:([]player:1 2f;name:`alice`bob;handle:.z.w,0Wi;cnt:18 16i;bet:10;insurance:0n;turn:10b;out:0b);
  };
  after{.bjk.insuring:0b};
  should["declines insurance for a player who plays on, then lets them play once insurance closes on their turn"]{
    `insure mock {.tst.declined,:x;.bjk.insuring:0b};
    .bjk.checks[] musteq 1b;
    .tst.declined musteq enlist 0;
    };
  should["declines insurance, then asks them to wait while others still have to answer"]{
    `insure mock {.tst.declined,:x};
    .bjk.checks[] musteq 0b;
    .tst.declined musteq enlist 0;
    .tst.msgs mustmatch enlist("Waiting for the other players to answer insurance";.z.w);
    };
  should["stops quietly when the decline closes insurance and the dealer's blackjack ends the hand"]{
    `insure mock {.bjk.insuring:0b;.bjk.hd:1b};
    .bjk.checks[] musteq 0b;
    .tst.msgs mustmatch ();
    };
 };
