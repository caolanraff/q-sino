system "l src/server/bin/blackjackServer.q";

.tst.desc["stake[]"]{
  should["refuses a bet under 1"]{
    `.bs.sendMsg mock {[x;y]};
    .bs.hd:1b;
    .bs.stake:([name:();handle:()]bet:());
    stake[0];
    (count .bs.stake) musteq 0;
    };
  should["refuses when the hand isn't done"]{
    `.bs.sendMsg mock {[x;y]};
    .bs.hd:0b;
    .bs.stake:([name:();handle:()]bet:());
    stake[10];
    (count .bs.stake) musteq 0;
    };
  should["accepts a valid bet and joins it into .bs.tab, but doesn't deal while another player is unbet"]{
    `.bs.user mock {`p1};
    dealCalls::0;
    `.bs.deal mock {dealCalls+::1};
    .bs.hd:1b; .bs.bd:0b;
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:2#0N;return:2#0n;profit:2#0n;split:00b;double:00b);
    .bs.stake:([name:();handle:()]bet:());
    stake[10];
    (exec first bet from .bs.tab where player=1) musteq 10;
    .bs.bd musteq 1b;
    dealCalls musteq 0;
    };
  should["deals once the last unbet player places their bet"]{
    `.bs.user mock {`p1};
    dealCalls::0;
    `.bs.deal mock {dealCalls+::1};
    .bs.hd:1b; .bs.bd:0b;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 0N;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.stake:([name:();handle:()]bet:());
    stake[10];
    dealCalls musteq 1;
    };
 };

.tst.desc[".bs.deal0"]{
  should["does nothing when no players are seated"]{
    `.bs.pubMsg mock {[x;y]};
    getCardCalls::0;
    `.bs.getCard mock {getCardCalls+::1;`5};
    .bs.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!();
    .bs.deal0[];
    getCardCalls musteq 0;
    };
  should["rebuilds the deck when fewer than 78 cards remain"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    buildCalls::0; shuffleCalls::0;
    `.bs.buildDeck mock {buildCalls+::1};
    `.bs.shuffle mock {shuffleCalls+::1};
    `.bs.getCard mock {`5};
    .bs.deck:5#`2;
    .bs.rnd:0;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.deal0[];
    buildCalls musteq 1;
    shuffleCalls musteq 1;
    };
  should["deals two cards to every player and two to the dealer, computing counts"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.deck:200#`2;
    cardseq::`7`8`5`3;  / p1's 1st, dealer's 1st (up-card), p1's 2nd, dealer's 2nd (hole card)
    `.bs.getCard mock {c:first cardseq;cardseq::1_cardseq;c};
    .bs.rnd:0;
    .bs.hd:1b;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.deal0[];
    (exec first cards from .bs.tab) mustmatch `7`5;
    (exec first cnt from .bs.tab) musteq 12i;
    .bs.dc mustmatch `8`3;
    .bs.hd musteq 0b;
    };
  should["deals each player's first card in seating order before either gets a second, with multiple players"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.deck:200#`2;
    cardseq::`2`9`5`3`8`6;  / p1's 1st, p2's 1st, dealer's up-card, p1's 2nd, p2's 2nd, dealer's hole card
    `.bs.getCard mock {c:first cardseq;cardseq::1_cardseq;c};
    .bs.rnd:0;
    .bs.hd:1b;
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b);
    .bs.deal0[];
    (exec first cards from .bs.tab where player=1) mustmatch `2`3;
    (exec first cards from .bs.tab where player=2) mustmatch `9`8;
    (exec first cnt from .bs.tab where player=1) musteq 5i;
    (exec first cnt from .bs.tab where player=2) musteq 17i;
    .bs.dc mustmatch `5`6;
    .bs.hd musteq 0b;
    };
  should["an immediate player blackjack against a dealer up-card under 10 pays out and calls .bs.dealer[] when no one else is left to act"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.deck:200#`2;
    cardseq::`A`5`K`3;  / p1: A,K = 21; dealer up-card 5 (<10)
    `.bs.getCard mock {c:first cardseq;cardseq::1_cardseq;c};
    stickCalls::0;
    `stick mock {stickCalls+::1};
    dealerCalls::0;
    `.bs.dealer mock {dealerCalls+::1};
    .bs.rnd:0;
    .bs.hd:1b;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.deal0[];
    (exec first return from .bs.tab) musteq 25f;
    (exec first out from .bs.tab) musteq 1b;
    stickCalls musteq 0;
    dealerCalls musteq 1;
    .bs.hd musteq 1b;
    };
  should["pays a player blackjack immediately against a dealer 10 up-card once the dealer has peeked and has no blackjack"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.deck:200#`2;
    cardseq::`A`K`K`3;  / p1: A,K = 21; dealer K up, 3 in the hole (no dealer blackjack)
    `.bs.getCard mock {c:first cardseq;cardseq::1_cardseq;c};
    stickCalls::0;
    `stick mock {stickCalls+::1};
    dealerCalls::0;
    `.bs.dealer mock {dealerCalls+::1};
    .bs.rnd:0;
    .bs.hd:1b;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.deal0[];
    (exec first return from .bs.tab) musteq 25f;
    (exec first out from .bs.tab) musteq 1b;
    stickCalls musteq 0;
    dealerCalls musteq 1;
    };
  should["ends the hand via .bs.dealerPeek before anyone acts when the dealer has blackjack"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.deck:200#`2;
    cardseq::`6`A`5`K;  / p1: 6,5 = 11; dealer A up, K in the hole (blackjack)
    `.bs.getCard mock {c:first cardseq;cardseq::1_cardseq;c};
    peekCalls::0;
    `.bs.dealerPeek mock {peekCalls+::1};
    deal1Calls::0;
    `.bs.deal1 mock {[h]deal1Calls+::1};
    .bs.rnd:0;
    .bs.hd:1b;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.deal0[];
    peekCalls musteq 1;
    deal1Calls musteq 0;
    (exec first cnt from .bs.tab) musteq 11i;
    };
  should["pays out one player's immediate blackjack but doesn't call .bs.dealer[] while another player still needs to act"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.deck:200#`2;
    cardseq::`A`9`5`K`8`3;  / p1: A,K = 21 (blackjack); p2: 9,8 = 17 (no blackjack); dealer up-card 5 (<10)
    `.bs.getCard mock {c:first cardseq;cardseq::1_cardseq;c};
    dealerCalls::0;
    `.bs.dealer mock {dealerCalls+::1};
    .bs.rnd:0;
    .bs.hd:1b;
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b);
    .bs.deal0[];
    (exec first return from .bs.tab where player=1) musteq 25f;
    (exec first out from .bs.tab where player=1) musteq 1b;
    (exec first cnt from .bs.tab where player=2) musteq 17i;
    (exec first out from .bs.tab where player=2) musteq 0b;
    dealerCalls musteq 0;
    .bs.hd musteq 0b;
    };
  should["calls .bs.dealer[] exactly once, after the last player's immediate blackjack leaves nobody still in"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.deck:200#`2;
    cardseq::`A`A`5`K`Q`3;  / p1: A,K = 21 (blackjack); p2: A,Q = 21 (blackjack); dealer up-card 5 (<10)
    `.bs.getCard mock {c:first cardseq;cardseq::1_cardseq;c};
    dealerCalls::0;
    `.bs.dealer mock {dealerCalls+::1};
    .bs.rnd:0;
    .bs.hd:1b;
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b);
    .bs.deal0[];
    (exec first return from .bs.tab where player=1) musteq 25f;
    (exec first return from .bs.tab where player=2) musteq 25f;
    (exec out from .bs.tab) musteq 11b;
    dealerCalls musteq 1;
    .bs.hd musteq 1b;
    };
 };

.tst.desc[".bs.dealerPeek"]{
  should["sends every player straight to settlement and runs the dealer"]{
    `.bs.pubMsg mock {[x;y]};
    dealerCalls::0;
    `.bs.dealer mock {dealerCalls+::1};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`A`K;`6`5);cnt:21 11i;dealer:(`A;`A);dealerCnt:11 11i;bet:10 10;return:0n 0n;profit:0n 0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b,turn:00b from .bs.tab;
    .bs.cp:0 1i!`p1`p2;
    .bs.dealerPeek[];
    (exec wait from .bs.tab) musteq 11b;
    dealerCalls musteq 1;
    };
 };

.tst.desc[".bs.deal"]{
  should["refuses to deal before the previous hand is done"]{
    deal0Calls::0;
    `.bs.deal0 mock {deal0Calls+::1};
    .bs.hd:0b; .bs.bd:1b;
    .bs.deal[];
    deal0Calls musteq 0;
    };
  should["refuses to deal until bets are placed"]{
    deal0Calls::0;
    `.bs.deal0 mock {deal0Calls+::1};
    .bs.hd:1b; .bs.bd:0b;
    .bs.deal[];
    deal0Calls musteq 0;
    };
  should["drops any player left with a null bet before dealing"]{
    `.bs.sendMsg mock {[x;y]};
    `.bs.deal0 mock {.bs.hd:1b};
    .bs.hd:1b; .bs.bd:1b;
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:10 0N;return:2#0n;profit:2#0n;split:00b;double:00b);
    .bs.deal[];
    (count .bs.tab) musteq 1;
    (exec first name from .bs.tab) musteq `p1;
    };
  should["sets the first player's turn, rebuilds .bs.turn and prompts them, when the hand isn't already decided"]{
    excFuncCalls::();
    `.bs.excFunc mock {[x;y;z] excFuncCalls,:enlist(x;z)};
    `.bs.sendMsg mock {[x;y]};
    `.bs.deal0 mock {.bs.hd:0b};
    .bs.hd:1b; .bs.bd:1b; .bs.count:0f;
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(enlist`7;enlist`8);cnt:7 8i;dealer:2#`5;dealerCnt:2#5i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:00b from .bs.tab;
    .bs.cp:0 1i!`p1`p2;
    .bs.deal[];
    (exec first turn from .bs.tab where player=1) musteq 1b;
    (exec first turn from .bs.tab where player=2) musteq 0b;
    (exec turn from .bs.turn) musteq 10b;
    excFuncCalls mustmatch enlist(`.mc.play;0i);
    };
  should["leaves the turn untouched when .bs.deal0 already decided the hand"]{
    excFuncCalls::();
    `.bs.excFunc mock {[x;y;z] excFuncCalls,:enlist(x;z)};
    `.bs.deal0 mock {.bs.hd:1b};
    .bs.hd:1b; .bs.bd:1b;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`K;cnt:enlist 21i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10;return:enlist 25f;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 1b,wait:enlist 0b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    .bs.deal[];
    excFuncCalls musteq ();
    };
 };

.tst.desc[".bs.dealer0"]{
  should["doesn't draw when the dealer already has 17 or more"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dc:`K`8;
    getCardCalls::0;
    `.bs.getCard mock {getCardCalls+::1;`5};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K;dealerCnt:enlist 10i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer0[];
    getCardCalls musteq 0;
    (exec first dealerCnt from .bs.tab) musteq 18i;
    };
  should["hits until the dealer reaches 17 or more"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dc:`6`5;
    cardseq::`4`2`2`2`2;
    `.bs.getCard mock {c:first cardseq;cardseq::1_cardseq;c};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`6;dealerCnt:enlist 6i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer0[];
    (exec first dealer from .bs.tab) mustmatch `6`5`4`2;
    (exec first dealerCnt from .bs.tab) musteq 17i;
    };
  should["reduces a newly-drawn ace by 10 to avoid busting"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dc:`6`9;
    cardseq::`A`3`2`2`2;
    `.bs.getCard mock {c:first cardseq;cardseq::1_cardseq;c};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`6;dealerCnt:enlist 6i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer0[];
    (exec first dealerCnt from .bs.tab) musteq 19i;
    };
  should["drops an ace drawn earlier to 1 when a later card would otherwise bust the dealer"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dc:`3`2;
    cardseq::`A`10`2;  / 3,2,A = soft 16; +10 = hard 16 (not 26); +2 = 18
    `.bs.getCard mock {c:first cardseq;cardseq::1_cardseq;c};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`3;dealerCnt:enlist 3i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer0[];
    (exec first dealer from .bs.tab) mustmatch `3`2`A`10`2;
    (exec first dealerCnt from .bs.tab) musteq 18i;
    };
 };

.tst.desc[".bs.dealer1"]{
  should["pays double the bet when the dealer busts and the player is 21 or under"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:24;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K;dealerCnt:enlist 24i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 20f;
    };
  should["pays nothing when both the dealer and the player bust"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:24;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`K`Q`5;cnt:enlist 25i;dealer:enlist`K;dealerCnt:enlist 24i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 0f;
    };
  should["pushes (returns the bet) when the counts are equal and both are 21 or under"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:18;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`9;cnt:enlist 18i;dealer:enlist`K;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 10f;
    };
  should["pays nothing when the dealer is under 21 and beats the player"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:19;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K;dealerCnt:enlist 19i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 0f;
    };
  should["pays nothing when the dealer is under 21 but the player busted"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:18;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`K`Q`5;cnt:enlist 25i;dealer:enlist`K;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 0f;
    };
  should["pays double the bet for a plain win when the player beats an under-21 dealer without blackjack"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:18;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`9`1;cnt:enlist 19i;dealer:enlist`K`3`4;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 20f;
    };
  should["pays 1.5x plus the bet for a two-card 21 (blackjack) against an under-21 dealer"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:19;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`K;cnt:enlist 21i;dealer:enlist`K`3`6;dealerCnt:enlist 19i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 25f;
    };
  should["pays nothing when the dealer has exactly 21 and the player doesn't"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:21;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K`Q`A;dealerCnt:enlist 21i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 0f;
    };
  should["pays 1.5x plus the bet for a blackjack when the dealer stands on two cards"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:17;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`K;cnt:enlist 21i;dealer:enlist`K`7;dealerCnt:enlist 17i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 25f;
    };
  should["pays 1.5x plus the bet for a blackjack when the dealer busts"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:24;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`K;cnt:enlist 21i;dealer:enlist`K`4`K;dealerCnt:enlist 24i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 25f;
    };
  should["pays 1.5x plus the bet for a blackjack against a dealer's three-card 21"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:21;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`K;cnt:enlist 21i;dealer:enlist`K`4`7;dealerCnt:enlist 21i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 25f;
    };
  should["pays nothing when the dealer has blackjack and the player has a three-card 21"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:21;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`5`6`10;cnt:enlist 21i;dealer:enlist`A`K;dealerCnt:enlist 21i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 0f;
    };
  should["pushes when both the dealer and the player have blackjack"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:21;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`Q;cnt:enlist 21i;dealer:enlist`A`K;dealerCnt:enlist 21i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 10f;
    };
  should["pays a two-card 21 on a split hand as a plain win, not a blackjack"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:18;
    .bs.tab:([]round:enlist 1;player:enlist 1.01;name:enlist`p1;handle:enlist 0i;cards:enlist`A`K;cnt:enlist 21i;dealer:enlist`K`8;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 1b;double:enlist 0b);
    .bs.dealer1[1.01];
    (exec first return from .bs.tab) musteq 20f;
    };
 };

.tst.desc[".bs.dealer"]{
  should["skips .bs.dealer0/.bs.dealer1 when every player is already out, but still records the result"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.wwch:0b; .bs.da:0Ni; .bs.dc:`K`5;
    dealer0Calls::0; dealer1Calls::0;
    `.bs.dealer0 mock {dealer0Calls+::1};
    `.bs.dealer1 mock {[p]dealer1Calls+::1};
    startCalls::0;
    `.bs.start mock {startCalls+::1};
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(();();();();();();();();`long$();();();();());
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K`Q`5;dealerCnt:enlist 25i;bet:enlist 10;return:enlist 0f;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 1b,wait:enlist 0b,turn:enlist 0b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    .bs.dealer[];
    dealer0Calls musteq 0;
    dealer1Calls musteq 0;
    (exec last round from .bs.res) musteq 1;
    .bs.bd musteq 0b;
    .bs.hd musteq 1b;
    };
  should["resolves every waiting player through .bs.dealer0/.bs.dealer1 and marks them out"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.wwch:0b; .bs.da:0Ni;
    dealer0Calls::0; dealer1Args::();
    `.bs.dealer0 mock {dealer0Calls+::1};
    `.bs.dealer1 mock {[p]dealer1Args,::p};
    startCalls::0;
    `.bs.start mock {startCalls+::1};
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(();();();();();();();();`long$();();();();());
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`8;`K`7);cnt:17 17i;dealer:(`K`Q`5;`K`Q`5);dealerCnt:25 25i;bet:10 10;return:0 0f;profit:2#0n;split:00b;double:00b);
    .bs.tab:update out:00b,wait:11b,turn:00b from .bs.tab;
    .bs.cp:0 1i!`p1`p2;
    .bs.dealer[];
    dealer0Calls musteq 1;
    dealer1Args musteq 1 2f;
    (exec out from .bs.tab) musteq 11b;
    (exec wait from .bs.tab) musteq 00b;
    };
  should["notifies the detection algo with the round's results when DA is connected"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.wwch:0b; .bs.da:99i; .bs.dc:`K`5;
    `.bs.start mock {};
    excFuncCalls::();
    `.bs.excFunc mock {[x;y;z] excFuncCalls,:enlist(x;z)};
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(();();();();();();();();`long$();();();();());
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K`Q`5;dealerCnt:enlist 25i;bet:enlist 10;return:enlist 0f;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 1b,wait:enlist 0b,turn:enlist 0b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    .bs.dealer[];
    excFuncCalls mustmatch enlist(`.da.gameover;99i);
    };
  should["always starts the next hand - the server has no round-count cap of its own"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.wwch:0b; .bs.da:0Ni; .bs.dc:`K`5;
    startCalls::0;
    `.bs.start mock {startCalls+::1};
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(();();();();();();();();`long$();();();();());
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K`Q`5;dealerCnt:enlist 25i;bet:enlist 10;return:enlist 0f;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab:update out:enlist 1b,wait:enlist 0b,turn:enlist 0b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    .bs.dealer[];
    startCalls musteq 1;
    };
 };
