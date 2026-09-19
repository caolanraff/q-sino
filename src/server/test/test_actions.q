system "l src/server/bin/blackjackServer.q";

.tst.desc["checks[]"]{
  should["returns 0b and does not act when it isn't the caller's turn"]{
    pubCalls::0;
    `.bs.pubMsg mock {[x;y] pubCalls+::1};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:01b from .bs.tab;  / player2 (handle 1) has the turn, not .z.w (0)
    (.bs.checks[]) musteq 0b;
    pubCalls musteq 1;
    };
  should["returns 0b when the turn holder's hand is already past 21"]{
    pubCalls::0;
    `.bs.pubMsg mock {[x;y] pubCalls+::1};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:25 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    (.bs.checks[]) musteq 0b;
    pubCalls musteq 1;
    };
  should["returns 1b when it is the caller's turn and the hand isn't bust"]{
    pubCalls::0;
    `.bs.pubMsg mock {[x;y] pubCalls+::1};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    (.bs.checks[]) musteq 1b;
    pubCalls musteq 0;
    };
 };

.tst.desc["stick[] / .bs.stick0"]{
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
    dealerCalls::0;
    `.bs.dealer mock {dealerCalls+::1};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    .bs.cp:0 1i!`p1`p2;
    stick[];
    (exec first wait from .bs.tab where player=1) musteq 1b;
    (exec first turn from .bs.tab where player=1) musteq 0b;
    (exec first turn from .bs.tab where player=2) musteq 1b;
    dealerCalls musteq 0;
    };
  should["calls .bs.dealer[] when the sticking player was the last one with a turn"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    dealerCalls::0;
    `.bs.dealer mock {dealerCalls+::1};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`8`8;cnt:enlist 16i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    stick[];
    (exec first wait from .bs.tab) musteq 1b;
    dealerCalls musteq 1;
    };
  should["triggers an async play prompt for the next player, addressed to their own handle"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    excFuncCalls::();
    `.bs.excFunc mock {[x;y;z] excFuncCalls,:enlist(x;z)};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    .bs.cp:0 1i!`p1`p2;
    stick[];
    excFuncCalls mustmatch enlist(`.mc.play;1i);
    };
 };

.tst.desc["hit[] / .bs.hit0 / .bs.hit1"]{
  should["does nothing when checks[] fails"]{
    `.bs.checks mock {0b};
    getCardCalls::0;
    `.bs.getCard mock {getCardCalls+::1;`5};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`7`6;cnt:enlist 13i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bs.tab;
    hit[];
    getCardCalls musteq 0;
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
    .bs.acelow:0;
    .bs.double:0b;
    hit[];
    (exec first cards from .bs.tab where player=1) mustmatch `7`6`5;
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
    .bs.acelow:0;
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
    dealerCalls::0;
    `.bs.dealer mock {dealerCalls+::1};
    .bs.dc:`5`5;  / .bs.hit1 unconditionally reads the global .bs.dc after the dealer branch; real gameplay sets it in .bs.deal0
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`7`8;`9`7);cnt:15 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    .bs.acelow:0;
    .bs.double:0b;
    hit[];
    (exec first return from .bs.tab where player=1) musteq 0f;
    (exec first out from .bs.tab where player=1) musteq 1b;
    (exec first turn from .bs.tab where player=1) musteq 0b;
    (exec first turn from .bs.tab where player=2) musteq 1b;
    dealerCalls musteq 0;
    };
  should["busts the hand and calls .bs.dealer[] when no player has a turn left"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.getCard mock {`10};
    dealerCalls::0;
    `.bs.dealer mock {dealerCalls+::1};
    .bs.dc:`5`5;  / .bs.hit1 unconditionally reads the global .bs.dc after the dealer branch; real gameplay sets it in .bs.deal0
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`7`8;cnt:enlist 15i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    .bs.acelow:0;
    .bs.double:0b;
    hit[];
    (exec first out from .bs.tab) musteq 1b;
    dealerCalls musteq 1;
    };
  should["reduces the count by 10 when a newly-drawn ace would otherwise bust the hand"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.getCard mock {`A};
    .bs.acelow:0;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`10`9;cnt:enlist 19i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bs.tab;
    .bs.hit0[];
    (exec first cnt from .bs.tab) musteq 20i;
    .bs.acelow musteq 1;
    };
  should["reduces the count by 10 for an existing ace when a later card busts the hand"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.getCard mock {`5};
    .bs.acelow:0;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`9;cnt:enlist 20i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bs.tab;
    .bs.hit0[];
    (exec first cnt from .bs.tab) musteq 15i;
    .bs.acelow musteq 1;
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
    dealerCalls::0;
    `.bs.dealer mock {dealerCalls+::1};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`7`8;cnt:enlist 15i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    .bs.acelow:0;
    double[];
    (exec first bet from .bs.tab) musteq 20f;
    (exec first double from .bs.tab) musteq 1b;
    (exec first cards from .bs.tab) mustmatch `7`8`5;
    (exec first wait from .bs.tab) musteq 1b;
    .bs.double musteq 0b;
    dealerCalls musteq 1;
    };
 };

.tst.desc["split[] / .bs.split0 / .bs.splitHit"]{
  should["does nothing when checks[] fails"]{
    `.bs.checks mock {0b};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`10`9;cnt:enlist 19i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10f;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 0b,wait:enlist 0b,turn:enlist 1b from .bs.tab;
    split[];
    (count .bs.tab) musteq 1;
    };
  should["refuses to split a hand whose two cards aren't the same rank"]{
    `.bs.sendMsg mock {[x;y]};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`10`9;`9`7);cnt:19 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    split[];
    (count .bs.tab) musteq 2;
    (exec first split from .bs.tab where player=1) musteq 0b;
    };
  should["forces the count to 22 before splitting a pair of aces"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.excFunc mock {[x;y;z]};
    `.bs.getCard mock {`2};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`A`A;`9`7);cnt:12 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    .bs.acelow:0;
    split[];
    (count .bs.tab) musteq 3;
    (asc exec cnt from .bs.tab where player in 1.01 1.02) musteq 13 13i;
    (exec cards from .bs.tab where player=1.01) mustmatch enlist `A`2;
    };
  should["splits a pair into two one-card hands, each dealt a new card"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    `.bs.excFunc mock {[x;y;z]};
    cardseq::`3`4;
    `.bs.getCard mock {c:first cardseq;cardseq::1_cardseq;c};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`8`8;`9`7);cnt:16 16i;dealer:(`5;`5);dealerCnt:5 5i;bet:10 10f;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:10b from .bs.tab;
    .bs.cp:0 1i!`p1`p2;
    .bs.acelow:0;
    split[];
    (count .bs.tab) musteq 3;
    `splithand mustnin cols .bs.tab;
    (exec first cards from .bs.tab where player=1.01) mustmatch `8`3;
    (exec first cnt from .bs.tab where player=1.01) musteq 11i;
    (exec first cards from .bs.tab where player=1.02) mustmatch `8`4;
    (exec first cnt from .bs.tab where player=1.02) musteq 12i;
    (exec first turn from .bs.tab where player=1.01) musteq 1b;
    (exec first turn from .bs.tab where player=1.02) musteq 0b;
    (exec first cards from .bs.tab where player=2) mustmatch `9`7;
    };
 };
