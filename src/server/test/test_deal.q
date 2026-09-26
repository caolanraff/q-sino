system"l src/server/bin/blackjackServer.q";
.bs.loadLibs[];

.tst.desc["stake[]"]{
  should["refuses a bet under 1"]{
    `.bs.sendMsg mock {[x;y]};
    .bs.hd:1b;
    .bs.stake:([name:();handle:()]bet:());
    stake[0];
    count[.bs.stake] musteq 0;
  };
  should["refuses when the hand isn't done"]{
    `.bs.sendMsg mock {[x;y]};
    .bs.hd:0b;
    .bs.stake:([name:();handle:()]bet:());
    stake[10];
    count[.bs.stake] musteq 0;
  };
  should["accepts a valid bet and joins it into .bs.tab, but doesn't deal while another player is unbet"]{
    `.bs.user mock {`p1};
    `.bs.sendMsg mock {[x;y]};
    .tst.dealCalls:0;
    `.bs.deal mock {.tst.dealCalls+:1};
    .bs.hd:1b;
    .bs.bd:0b;
    .bs.betDeadline:0Np;
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:2#0N;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:0f);
    .bs.stake:([name:();handle:()]bet:());
    stake[10];
    (exec first bet from .bs.tab where player=1) musteq 10;
    .bs.bd musteq 1b;
    .tst.dealCalls musteq 0;
  };
  should["deals once the last unbet player places their bet"]{
    `.bs.user mock {`p1};
    `.bs.sendMsg mock {[x;y]};
    .tst.dealCalls:0;
    `.bs.deal mock {.tst.dealCalls+:1};
    .bs.hd:1b;
    .bs.bd:0b;
    .bs.betDeadline:0Np;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 0N;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.stake:([name:();handle:()]bet:());
    stake[10];
    .tst.dealCalls musteq 1;
  };
 };

.tst.desc["stake[] betting clock"]{
  should["starts the clock on the round's first bet and tells the players still to bet"]{
    `.bs.user mock {`p1};
    .tst.msgs:();
    `.bs.sendMsg mock {[x;y].tst.msgs,:enlist(x;y)};
    `.bs.deal mock {};
    .bs.hd:1b;
    .bs.bd:0b;
    .bs.betDeadline:0Np;
    .bs.betTimeout:0D00:00:15;
    .bs.tab:([]round:1 1 1;player:1 2 3f;name:`p1`p2`p3;handle:0 1 2i;cards:3#enlist();cnt:3#0Ni;dealer:3#`;dealerCnt:3#0Ni;bet:3#0N;return:3#0n;profit:3#0n;split:000b;double:000b;insurance:0f);
    .bs.stake:([name:();handle:()]bet:());
    t0:.z.p;
    stake[10];
    (.bs.betDeadline within t0+.bs.betTimeout+0D00:00:00 0D00:00:01) musteq 1b;
    .tst.msgs mustmatch (("Betting closes in 15 seconds";1i);("Betting closes in 15 seconds";2i));
  };
  should["doesn't restart the clock on later bets"]{
    `.bs.user mock {`p2};
    `.bs.sendMsg mock {[x;y]};
    `.bs.deal mock {};
    .bs.hd:1b;
    .bs.bd:1b;
    deadline:.z.p+0D00:00:05;
    .bs.betDeadline:deadline;
    .bs.tab:([]round:1 1 1;player:1 2 3f;name:`p1`p2`p3;handle:0 1 2i;cards:3#enlist();cnt:3#0Ni;dealer:3#`;dealerCnt:3#0Ni;bet:10 0N 0N;return:3#0n;profit:3#0n;split:000b;double:000b;insurance:0f);
    .bs.stake:([name:enlist`p1;handle:enlist 0i]bet:enlist 10);
    stake[10];
    .bs.betDeadline musteq deadline;
  };
 };

.tst.desc[".bs.betTimer"]{
  should["does nothing while no betting clock is running"]{
    .tst.dealCalls:0;
    `.bs.deal mock {.tst.dealCalls+:1};
    .bs.betDeadline:0Np;
    .bs.tab:([]round:1 1 1;player:1 2 3f;name:`p1`p2`p3;handle:0 1 2i;cards:3#enlist();cnt:3#0Ni;dealer:3#`;dealerCnt:3#0Ni;bet:10 0N 0N;return:3#0n;profit:3#0n;split:000b;double:000b;insurance:0f);
    .bs.betTimer[];
    .tst.dealCalls musteq 0;
  };
  should["does nothing before betting closes"]{
    .tst.dealCalls:0;
    `.bs.deal mock {.tst.dealCalls+:1};
    .bs.betDeadline:.z.p+0D00:00:10;
    .bs.tab:([]round:1 1 1;player:1 2 3f;name:`p1`p2`p3;handle:0 1 2i;cards:3#enlist();cnt:3#0Ni;dealer:3#`;dealerCnt:3#0Ni;bet:10 0N 0N;return:3#0n;profit:3#0n;split:000b;double:000b;insurance:0f);
    .bs.betTimer[];
    .tst.dealCalls musteq 0;
  };
  should["deals once betting has closed"]{
    .tst.dealCalls:0;
    `.bs.deal mock {.tst.dealCalls+:1};
    .bs.betDeadline:.z.p-0D00:00:01;
    .bs.tab:([]round:1 1 1;player:1 2 3f;name:`p1`p2`p3;handle:0 1 2i;cards:3#enlist();cnt:3#0Ni;dealer:3#`;dealerCnt:3#0Ni;bet:10 0N 0N;return:3#0n;profit:3#0n;split:000b;double:000b;insurance:0f);
    .bs.betTimer[];
    .tst.dealCalls musteq 1;
  };
  should["stops the clock without dealing when every bettor has since left"]{
    .tst.dealCalls:0;
    `.bs.deal mock {.tst.dealCalls+:1};
    .bs.betDeadline:.z.p-0D00:00:01;
    .bs.tab:([]round:1 1 1;player:1 2 3f;name:`p1`p2`p3;handle:0 1 2i;cards:3#enlist();cnt:3#0Ni;dealer:3#`;dealerCnt:3#0Ni;bet:3#0N;return:3#0n;profit:3#0n;split:000b;double:000b;insurance:0f);
    .bs.betTimer[];
    .tst.dealCalls musteq 0;
    null[.bs.betDeadline] musteq 1b;
    count[.bs.tab] musteq 3;
  };
  should["sits out the players who didn't bet in time and deals the rest"]{
    .tst.msgs:();
    `.bs.sendMsg mock {[x;y].tst.msgs,:enlist(x;y)};
    .tst.deal0Calls:0;
    `.bs.deal0 mock {.tst.deal0Calls+:1;.bs.hd:1b};
    .bs.hd:1b;
    .bs.bd:1b;
    .bs.betDeadline:.z.p-0D00:00:01;
    .bs.tab:([]round:1 1 1;player:1 2 3f;name:`p1`p2`p3;handle:0 1 2i;cards:3#enlist();cnt:3#0Ni;dealer:3#`;dealerCnt:3#0Ni;bet:10 0N 0N;return:3#0n;profit:3#0n;split:000b;double:000b;insurance:0f);
    .bs.betTimer[];
    .tst.deal0Calls musteq 1;
    (exec handle from .bs.tab) musteq enlist 0i;
    .tst.msgs mustmatch (("No bet placed, please wait until the next hand";1i);("No bet placed, please wait until the next hand";2i));
    null[.bs.betDeadline] musteq 1b;
  };
 };

.tst.desc[".bs.deal0"]{
  should["does nothing when no players are seated"]{
    `.bs.pubMsg mock {[x;y]};
    .tst.getCardCalls:0;
    `.bs.getCard mock {.tst.getCardCalls+:1;`5};
    .bs.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!();
    .bs.deal0[];
    .tst.getCardCalls musteq 0;
  };
  should["rebuilds the deck when fewer than 78 cards remain"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .tst.buildCalls:0;
    .tst.shuffleCalls:0;
    `.bs.buildDeck mock {.tst.buildCalls+:1};
    `.bs.shuffle mock {.tst.shuffleCalls+:1};
    `.bs.getCard mock {`5};
    .bs.deck:5#`2;
    .bs.rnd:0;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.deal0[];
    .tst.buildCalls musteq 1;
    .tst.shuffleCalls musteq 1;
  };
  should["deals two cards to every player and two to the dealer, computing counts"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.deck:200#`2;
    .tst.cardseq:`7`8`5`3;                                                                         / p1's 1st, dealer's 1st (up-card), p1's 2nd, dealer's 2nd (hole card)
    `.bs.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bs.rnd:0;
    .bs.hd:1b;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.deal0[];
    (exec first cards from .bs.tab) mustmatch`7`5;
    (exec first cnt from .bs.tab) musteq 12i;
    .bs.dc mustmatch`8`3;
    .bs.hd musteq 0b;
  };
  should["deals each player's first card in seating order before either gets a second, with multiple players"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.deck:200#`2;
    .tst.cardseq:`2`9`5`3`8`6;                                                                     / p1's 1st, p2's 1st, dealer's up-card, p1's 2nd, p2's 2nd, dealer's hole card
    `.bs.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bs.rnd:0;
    .bs.hd:1b;
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:0f);
    .bs.deal0[];
    (exec first cards from .bs.tab where player=1) mustmatch`2`3;
    (exec first cards from .bs.tab where player=2) mustmatch`9`8;
    (exec first cnt from .bs.tab where player=1) musteq 5i;
    (exec first cnt from .bs.tab where player=2) musteq 17i;
    .bs.dc mustmatch`5`6;
    .bs.hd musteq 0b;
  };
  should["an immediate player blackjack against a dealer up-card under 10 pays out and calls .bs.dealer[] when no one else is left to act"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.deck:200#`2;
    .tst.cardseq:`A`5`K`3;                                                                         / p1: A,K = 21; dealer up-card 5 (<10)
    `.bs.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .tst.stickCalls:0;
    `stick mock {.tst.stickCalls+:1};
    .tst.dealerCalls:0;
    `.bs.dealer mock {.tst.dealerCalls+:1};
    .bs.rnd:0;
    .bs.hd:1b;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.deal0[];
    (exec first return from .bs.tab) musteq 25f;
    (exec first out from .bs.tab) musteq 1b;
    .tst.stickCalls musteq 0;
    .tst.dealerCalls musteq 1;
    .bs.hd musteq 1b;
  };
  should["pays a player blackjack immediately against a dealer 10 up-card once the dealer has peeked and has no blackjack"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.deck:200#`2;
    .tst.cardseq:`A`K`K`3;                                                                         / p1: A,K = 21; dealer K up, 3 in the hole (no dealer blackjack)
    `.bs.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .tst.stickCalls:0;
    `stick mock {.tst.stickCalls+:1};
    .tst.dealerCalls:0;
    `.bs.dealer mock {.tst.dealerCalls+:1};
    .bs.rnd:0;
    .bs.hd:1b;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.deal0[];
    (exec first return from .bs.tab) musteq 25f;
    (exec first out from .bs.tab) musteq 1b;
    .tst.stickCalls musteq 0;
    .tst.dealerCalls musteq 1;
  };
  should["ends the hand via .bs.dealerPeek before anyone acts when the dealer has blackjack"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.deck:200#`2;
    .tst.cardseq:`6`K`5`A;                                                                         / p1: 6,5 = 11; dealer K up, A in the hole (blackjack)
    `.bs.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .tst.peekCalls:0;
    `.bs.dealerPeek mock {.tst.peekCalls+:1};
    .tst.deal1Calls:0;
    `.bs.deal1 mock {[h].tst.deal1Calls+:1};
    .bs.rnd:0;
    .bs.hd:1b;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.deal0[];
    .tst.peekCalls musteq 1;
    .tst.deal1Calls musteq 0;
    (exec first cnt from .bs.tab) musteq 11i;
  };
  should["pays out one player's immediate blackjack but doesn't call .bs.dealer[] while another player still needs to act"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.deck:200#`2;
    .tst.cardseq:`A`9`5`K`8`3;                                                                     / p1: A,K = 21 (blackjack); p2: 9,8 = 17 (no blackjack); dealer up-card 5 (<10)
    `.bs.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .tst.dealerCalls:0;
    `.bs.dealer mock {.tst.dealerCalls+:1};
    .bs.rnd:0;
    .bs.hd:1b;
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:0f);
    .bs.deal0[];
    (exec first return from .bs.tab where player=1) musteq 25f;
    (exec first out from .bs.tab where player=1) musteq 1b;
    (exec first cnt from .bs.tab where player=2) musteq 17i;
    (exec first out from .bs.tab where player=2) musteq 0b;
    .tst.dealerCalls musteq 0;
    .bs.hd musteq 0b;
  };
  should["calls .bs.dealer[] exactly once, after the last player's immediate blackjack leaves nobody still in"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.deck:200#`2;
    .tst.cardseq:`A`A`5`K`Q`3;                                                                     / p1: A,K = 21 (blackjack); p2: A,Q = 21 (blackjack); dealer up-card 5 (<10)
    `.bs.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .tst.dealerCalls:0;
    `.bs.dealer mock {.tst.dealerCalls+:1};
    .bs.rnd:0;
    .bs.hd:1b;
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:0f);
    .bs.deal0[];
    (exec first return from .bs.tab where player=1) musteq 25f;
    (exec first return from .bs.tab where player=2) musteq 25f;
    (exec out from .bs.tab) musteq 11b;
    .tst.dealerCalls musteq 1;
    .bs.hd musteq 1b;
  };
 };

.tst.desc[".bs.dealerPeek"]{
  should["sends every player straight to settlement and runs the dealer"]{
    `.bs.pubMsg mock {[x;y]};
    .tst.dealerCalls:0;
    `.bs.dealer mock {.tst.dealerCalls+:1};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`A`K;`6`5);cnt:21 11i;dealer:(`A;`A);dealerCnt:11 11i;bet:10 10;return:0n 0n;profit:0n 0n;split:00b;double:00b;insurance:0f);
    .bs.tab:update out:00b,wait:00b,turn:00b from .bs.tab;
    .bs.cp:0 1i!`p1`p2;
    .bs.dealerPeek[];
    (exec wait from .bs.tab) musteq 11b;
    .tst.dealerCalls musteq 1;
  };
 };

.tst.desc[".bs.deal"]{
  should["refuses to deal before the previous hand is done"]{
    .tst.deal0Calls:0;
    `.bs.deal0 mock {.tst.deal0Calls+:1};
    .bs.hd:0b;
    .bs.bd:1b;
    .bs.deal[];
    .tst.deal0Calls musteq 0;
  };
  should["refuses to deal until bets are placed"]{
    .tst.deal0Calls:0;
    `.bs.deal0 mock {.tst.deal0Calls+:1};
    .bs.hd:1b;
    .bs.bd:0b;
    .bs.deal[];
    .tst.deal0Calls musteq 0;
  };
  should["drops any player left with a null bet before dealing"]{
    `.bs.sendMsg mock {[x;y]};
    `.bs.deal0 mock {.bs.hd:1b};
    .bs.hd:1b;
    .bs.bd:1b;
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:10 0N;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:0f);
    .bs.deal[];
    count[.bs.tab] musteq 1;
    (exec first name from .bs.tab) musteq`p1;
  };
  should["clears the betting clock"]{
    `.bs.sendMsg mock {[x;y]};
    `.bs.deal0 mock {.bs.hd:1b};
    .bs.hd:1b;
    .bs.bd:1b;
    .bs.betDeadline:.z.p+0D00:00:10;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.deal[];
    null[.bs.betDeadline] musteq 1b;
  };
  should["sets the first player's turn, rebuilds .bs.turn and prompts them, when the hand isn't already decided"]{
    .tst.excFuncCalls:();
    `.bs.excFunc mock {[x;y;z].tst.excFuncCalls,:enlist(x;z)};
    `.bs.sendMsg mock {[x;y]};
    `.bs.deal0 mock {.bs.hd:0b};
    .bs.hd:1b;
    .bs.bd:1b;
    .bs.insuring:0b;
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(enlist`7;enlist`8);cnt:7 8i;dealer:2#`5;dealerCnt:2#5i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:0f);
    .bs.tab:update out:00b,wait:00b from .bs.tab;
    .bs.cp:0 1i!`p1`p2;
    .bs.deal[];
    (exec first turn from .bs.tab where player=1) musteq 1b;
    (exec first turn from .bs.tab where player=2) musteq 0b;
    (exec turn from .bs.turn) musteq 10b;
    .tst.excFuncCalls mustmatch enlist(`.mc.play;0i);
  };
  should["leaves the turn untouched when .bs.deal0 already decided the hand"]{
    .tst.excFuncCalls:();
    `.bs.excFunc mock {[x;y;z].tst.excFuncCalls,:enlist(x;z)};
    `.bs.deal0 mock {.bs.hd:1b};
    .bs.hd:1b;
    .bs.bd:1b;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`K;cnt:enlist 21i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10;return:enlist 25f;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.tab:update out:enlist 1b,wait:enlist 0b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    .bs.deal[];
    .tst.excFuncCalls mustmatch();
  };
 };

.tst.desc[".bs.dealer0"]{
  should["doesn't draw when the dealer already has 17 or more"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dc:`K`8;
    .tst.getCardCalls:0;
    `.bs.getCard mock {.tst.getCardCalls+:1;`5};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K;dealerCnt:enlist 10i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.dealer0[];
    .tst.getCardCalls musteq 0;
    (exec first dealerCnt from .bs.tab) musteq 18i;
  };
  should["hits until the dealer reaches 17 or more"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dc:`6`5;
    .tst.cardseq:`4`2`2`2`2;
    `.bs.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`6;dealerCnt:enlist 6i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.dealer0[];
    (exec first dealer from .bs.tab) mustmatch`6`5`4`2;
    (exec first dealerCnt from .bs.tab) musteq 17i;
  };
  should["reduces a newly-drawn ace by 10 to avoid busting"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dc:`6`9;
    .tst.cardseq:`A`3`2`2`2;
    `.bs.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`6;dealerCnt:enlist 6i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.dealer0[];
    (exec first dealerCnt from .bs.tab) musteq 19i;
  };
  should["drops an ace drawn earlier to 1 when a later card would otherwise bust the dealer"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dc:`3`2;
    .tst.cardseq:`A`10`2;                                                                          / 3,2,A = soft 16; +10 = hard 16 (not 26); +2 = 18
    `.bs.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`3;dealerCnt:enlist 3i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.dealer0[];
    (exec first dealer from .bs.tab) mustmatch`3`2`A`10`2;
    (exec first dealerCnt from .bs.tab) musteq 18i;
  };
 };

.tst.desc[".bs.dealerDraws"]{
  should["draws below 17 and stands on hard 17 under either rule"]{
    .bs.hitSoft17:0b;
    .bs.dealerDraws[`K`6] musteq 1b;
    .bs.dealerDraws[`K`7] musteq 0b;
    .bs.hitSoft17:1b;
    .bs.dealerDraws[`K`6] musteq 1b;
    .bs.dealerDraws[`K`7] musteq 0b;
  };
  should["stands on soft 17 when the table stands on all 17s"]{
    .bs.hitSoft17:0b;
    .bs.dealerDraws[`A`6] musteq 0b;
  };
  should["draws on soft 17 when the table hits soft 17, but stands on soft 18"]{
    .bs.hitSoft17:1b;
    .bs.dealerDraws[`A`6] musteq 1b;
    .bs.dealerDraws[`A`A`5] musteq 1b;
    .bs.dealerDraws[`A`7] musteq 0b;
  };
 };

.tst.desc[".bs.dealer0 soft 17"]{
  should["stands on A,6 when the table stands on all 17s"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.hitSoft17:0b;
    .bs.dc:`A`6;
    .tst.getCardCalls:0;
    `.bs.getCard mock {.tst.getCardCalls+:1;`2};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`A;dealerCnt:enlist 11i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.dealer0[];
    .tst.getCardCalls musteq 0;
    .bs.dealerCount musteq 17i;
  };
  should["draws on A,6 when the table hits soft 17"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.hitSoft17:1b;
    .bs.dc:`A`6;
    `.bs.getCard mock {`2};
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`A;dealerCnt:enlist 11i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.dealer0[];
    (exec first dealer from .bs.tab) mustmatch`A`6`2;
    .bs.dealerCount musteq 19i;
  };
 };

.tst.desc[".bs.dealer1"]{
  should["pays double the bet when the dealer busts and the player is 21 or under"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:24;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K;dealerCnt:enlist 24i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 20f;
  };
  should["pays nothing when both the dealer and the player bust"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:24;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`K`Q`5;cnt:enlist 25i;dealer:enlist`K;dealerCnt:enlist 24i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 0f;
  };
  should["pushes (returns the bet) when the counts are equal and both are 21 or under"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:18;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`9;cnt:enlist 18i;dealer:enlist`K;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 10f;
  };
  should["pays nothing when the dealer is under 21 and beats the player"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:19;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K;dealerCnt:enlist 19i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 0f;
  };
  should["pays nothing when the dealer is under 21 but the player busted"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:18;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`K`Q`5;cnt:enlist 25i;dealer:enlist`K;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 0f;
  };
  should["pays double the bet for a plain win when the player beats an under-21 dealer without blackjack"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:18;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`9`1;cnt:enlist 19i;dealer:enlist`K`3`4;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 20f;
  };
  should["pays 1.5x plus the bet for a two-card 21 (blackjack) against an under-21 dealer"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:19;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`K;cnt:enlist 21i;dealer:enlist`K`3`6;dealerCnt:enlist 19i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 25f;
  };
  should["pays nothing when the dealer has exactly 21 and the player doesn't"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:21;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K`Q`A;dealerCnt:enlist 21i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 0f;
  };
  should["pays 1.5x plus the bet for a blackjack when the dealer stands on two cards"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:17;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`K;cnt:enlist 21i;dealer:enlist`K`7;dealerCnt:enlist 17i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 25f;
  };
  should["pays 1.5x plus the bet for a blackjack when the dealer busts"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:24;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`K;cnt:enlist 21i;dealer:enlist`K`4`K;dealerCnt:enlist 24i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 25f;
  };
  should["pays 1.5x plus the bet for a blackjack against a dealer's three-card 21"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:21;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`K;cnt:enlist 21i;dealer:enlist`K`4`7;dealerCnt:enlist 21i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 25f;
  };
  should["pays nothing when the dealer has blackjack and the player has a three-card 21"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:21;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`5`6`10;cnt:enlist 21i;dealer:enlist`A`K;dealerCnt:enlist 21i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 0f;
  };
  should["pushes when both the dealer and the player have blackjack"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:21;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`Q;cnt:enlist 21i;dealer:enlist`A`K;dealerCnt:enlist 21i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 10f;
  };
  should["pays a two-card 21 on a split hand as a plain win, not a blackjack"]{
    `.bs.pubMsg mock {[x;y]};
    .bs.dealerCount:18;
    .bs.tab:([]round:enlist 1;player:enlist 1.01;name:enlist`p1;handle:enlist 0i;cards:enlist`A`K;cnt:enlist 21i;dealer:enlist`K`8;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 1b;double:enlist 0b;insurance:0f);
    .bs.dealer1[1.01];
    (exec first return from .bs.tab) musteq 20f;
  };
 };

.tst.desc[".bs.dealer"]{
  should["skips .bs.dealer0/.bs.dealer1 when every player is already out, but still records the result"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.wwch:0b;
    .bs.da:0Ni;
    .bs.dc:`K`5;
    .tst.dealer0Calls:0;
    .tst.dealer1Calls:0;
    `.bs.dealer0 mock {.tst.dealer0Calls+:1};
    `.bs.dealer1 mock {[p].tst.dealer1Calls+:1};
    .tst.startCalls:0;
    `.bs.start mock {.tst.startCalls+:1};
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K`Q`5;dealerCnt:enlist 25i;bet:enlist 10;return:enlist 0f;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.tab:update out:enlist 1b,wait:enlist 0b,turn:enlist 0b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    .bs.dealer[];
    .tst.dealer0Calls musteq 0;
    .tst.dealer1Calls musteq 0;
    (exec last round from .bs.res) musteq 1;
    .bs.bd musteq 0b;
    .bs.hd musteq 1b;
  };
  should["resolves every waiting player through .bs.dealer0/.bs.dealer1 and marks them out"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.wwch:0b;
    .bs.da:0Ni;
    .tst.dealer0Calls:0;
    .tst.dealer1Args:();
    `.bs.dealer0 mock {.tst.dealer0Calls+:1};
    `.bs.dealer1 mock {[p].tst.dealer1Args,:p};
    .tst.startCalls:0;
    `.bs.start mock {.tst.startCalls+:1};
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`8;`K`7);cnt:17 17i;dealer:(`K`Q`5;`K`Q`5);dealerCnt:25 25i;bet:10 10;return:0 0f;profit:2#0n;split:00b;double:00b;insurance:0f);
    .bs.tab:update out:00b,wait:11b,turn:00b from .bs.tab;
    .bs.cp:0 1i!`p1`p2;
    .bs.dealer[];
    .tst.dealer0Calls musteq 1;
    .tst.dealer1Args musteq 1 2f;
    (exec out from .bs.tab) musteq 11b;
    (exec wait from .bs.tab) musteq 00b;
  };
  should["notifies the detection algo with the round's results when DA is connected"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.wwch:0b;
    .bs.da:99i;
    .bs.dc:`K`5;
    `.bs.start mock {};
    .tst.excFuncCalls:();
    `.bs.excFunc mock {[x;y;z].tst.excFuncCalls,:enlist(x;z)};
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K`Q`5;dealerCnt:enlist 25i;bet:enlist 10;return:enlist 0f;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.tab:update out:enlist 1b,wait:enlist 0b,turn:enlist 0b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    .bs.dealer[];
    .tst.excFuncCalls mustmatch enlist(`.da.gameover;99i);
  };
  should["sends the detection algo the shoe's results and the round just played"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.wwch:0b;
    .bs.da:99i;
    .bs.dc:`K`5;
    .bs.rnd:4;
    `.bs.start mock {};
    .tst.sent:();
    `.bs.excFunc mock {[x;y;z].tst.sent,:enlist(x;y;z)};
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bs.tab:([]round:enlist 4;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K`Q`5;dealerCnt:enlist 25i;bet:enlist 10;return:enlist 0f;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.tab:update out:enlist 1b,wait:enlist 0b,turn:enlist 0b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    .bs.dealer[];
    (.tst.sent[0;1]`rnd) musteq 4;
    (.tst.sent[0;1]`res) mustmatch .bs.res;
  };
  should["records each hand's net profit - return minus bet - in .bs.res"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    `.bs.start mock {};
    .bs.wwch:0b;
    .bs.da:0Ni;
    .bs.dc:`K`5;
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bs.tab:([]round:5#1;player:1 2 3 4 5f;name:`p1`p2`p3`p4`p5;handle:0 1 2 3 4i;cards:(`K`9;`K`6;`K`8;`A`K;`5`6`K);cnt:19 16 18 21 21i;dealer:5#`K;dealerCnt:5#18i;bet:10 10 10 10 20;return:20 0 10 25 40f;profit:5#0n;split:00000b;double:00001b;insurance:0f);
    .bs.tab:update out:11111b,wait:00000b,turn:00000b from .bs.tab;
    .bs.cp:(0 1 2 3 4i)!`p1`p2`p3`p4`p5;
    .bs.dealer[];
    (exec profit from .bs.res) musteq 10 -10 0 15 20f;
  };
  should["doesn't carry a running total into a player's later hands"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    `.bs.start mock {};
    .bs.wwch:0b;
    .bs.da:0Ni;
    .bs.dc:`K`5;
    .bs.res:([]round:enlist 1;player:enlist 1;name:enlist`p1;handle:enlist 0i;cards:enlist`K`9;cnt:enlist 19i;dealer:enlist`K`8;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 20f;profit:enlist 10f;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.tab:([]round:enlist 2;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`K`6`K;cnt:enlist 26i;dealer:enlist`K;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 0f;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.tab:update out:enlist 1b,wait:enlist 0b,turn:enlist 0b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    .bs.dealer[];
    (exec profit from .bs.res) musteq 10 -10f;
  };
  should["clears the round's bets before starting the next hand"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.wwch:0b;
    .bs.da:0Ni;
    .bs.dc:`K`5;
    .tst.stakeAtStart:-1;
    `.bs.start mock {.tst.stakeAtStart:count .bs.stake};
    .bs.stake:([name:enlist`p1;handle:enlist 0i]bet:enlist 10);
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K`Q`5;dealerCnt:enlist 25i;bet:enlist 10;return:enlist 0f;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.tab:update out:enlist 1b,wait:enlist 0b,turn:enlist 0b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    .bs.dealer[];
    .tst.stakeAtStart musteq 0;
  };
  should["always starts the next hand - the server has no round-count cap of its own"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .bs.wwch:0b;
    .bs.da:0Ni;
    .bs.dc:`K`5;
    .tst.startCalls:0;
    `.bs.start mock {.tst.startCalls+:1};
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K`Q`5;dealerCnt:enlist 25i;bet:enlist 10;return:enlist 0f;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.tab:update out:enlist 1b,wait:enlist 0b,turn:enlist 0b from .bs.tab;
    .bs.cp:enlist[0i]!enlist`p1;
    .bs.dealer[];
    .tst.startCalls musteq 1;
  };
 };

.tst.desc[".bs.deal0 insurance offer"]{
  should["offers insurance before the dealer checks for blackjack when the up-card is an ace"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .tst.sent:();
    `.bs.excFunc mock {[x;y;z].tst.sent,:enlist(x;z)};
    .tst.peekCalls:0;
    .tst.deal1Calls:0;
    `.bs.dealerPeek mock {.tst.peekCalls+:1};
    `.bs.deal1 mock {[h].tst.deal1Calls+:1};
    .bs.deck:200#`2;
    .tst.cardseq:`9`A`7`K;
    `.bs.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bs.rnd:0;
    .bs.hd:1b;
    .bs.insuring:0b;
    .bs.insureDeadline:0Np;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.cp:enlist[0i]!enlist`p1;
    .bs.deal0[];
    .bs.insuring musteq 1b;
    null[.bs.insureDeadline] musteq 0b;
    (exec first null insurance from .bs.tab) musteq 1b;
    .tst.sent mustmatch enlist(`.mc.insure;0i);
    .tst.peekCalls musteq 0;
    .tst.deal1Calls musteq 0;
  };
  should["doesn't offer insurance under any other up-card"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    .tst.sent:();
    `.bs.excFunc mock {[x;y;z].tst.sent,:enlist(x;z)};
    `.bs.deal1 mock {[h]};
    .bs.deck:200#`2;
    .tst.cardseq:`9`K`7`6;
    `.bs.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bs.rnd:0;
    .bs.hd:1b;
    .bs.insuring:0b;
    .bs.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bs.cp:enlist[0i]!enlist`p1;
    .bs.deal0[];
    .bs.insuring musteq 0b;
    count[.tst.sent] musteq 0;
  };
 };

.tst.desc[".bs.deal while insurance is open"]{
  should["doesn't start anyone's turn until insurance closes"]{
    `.bs.sendMsg mock {[x;y]};
    .tst.startCalls:0;
    `.bs.startTurns mock {.tst.startCalls+:1};
    `.bs.deal0 mock {.bs.hd:0b;.bs.insuring:1b};
    .bs.hd:1b;
    .bs.bd:1b;
    .bs.insuring:0b;
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`7;`10`8);cnt:16 18i;dealer:2#`A;dealerCnt:11 11i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:2#0n);
    .bs.deal[];
    .tst.startCalls musteq 0;
    .bs.insuring:0b;
  };
 };

.tst.desc["insure[]"]{
  should["records the side bet"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.closeInsurance mock {};
    .bs.insuring:1b;
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`7;`10`8);cnt:16 18i;dealer:2#`A;dealerCnt:11 11i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:2#0n);
    insure[5];
    (exec first insurance from .bs.tab where handle=0i) musteq 5f;
    (exec first null insurance from .bs.tab where handle=1i) musteq 1b;
    .bs.insuring:0b;
  };
  should["records a decline as zero"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.closeInsurance mock {};
    .bs.insuring:1b;
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`7;`10`8);cnt:16 18i;dealer:2#`A;dealerCnt:11 11i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:2#0n);
    insure[0];
    (exec first insurance from .bs.tab where handle=0i) musteq 0f;
    .bs.insuring:0b;
  };
  should["refuses more than half the bet"]{
    `.bs.sendMsg mock {[x;y]};
    .bs.insuring:1b;
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`7;`10`8);cnt:16 18i;dealer:2#`A;dealerCnt:11 11i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:2#0n);
    insure[6];
    (exec first null insurance from .bs.tab where handle=0i) musteq 1b;
    .bs.insuring:0b;
  };
  should["refuses a second answer"]{
    `.bs.sendMsg mock {[x;y]};
    .bs.insuring:1b;
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`7;`10`8);cnt:16 18i;dealer:2#`A;dealerCnt:11 11i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:0 0n);
    insure[5];
    (exec first insurance from .bs.tab where handle=0i) musteq 0f;
    .bs.insuring:0b;
  };
  should["refuses when insurance isn't on offer"]{
    `.bs.sendMsg mock {[x;y]};
    .bs.insuring:0b;
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`7;`10`8);cnt:16 18i;dealer:2#`A;dealerCnt:11 11i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:2#0n);
    insure[5];
    (exec first null insurance from .bs.tab where handle=0i) musteq 1b;
  };
  should["closes insurance once the last player answers"]{
    `.bs.pubMsg mock {[x;y]};
    .tst.closeCalls:0;
    `.bs.closeInsurance mock {.tst.closeCalls+:1};
    .bs.insuring:1b;
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`7;`10`8);cnt:16 18i;dealer:2#`A;dealerCnt:11 11i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:0n 0f);
    insure[5];
    .tst.closeCalls musteq 1;
    .bs.insuring:0b;
  };
 };

.tst.desc[".bs.insureTimer"]{
  should["does nothing before the window closes"]{
    .tst.closeCalls:0;
    `.bs.closeInsurance mock {.tst.closeCalls+:1};
    .bs.insureDeadline:.z.p+0D00:00:10;
    .bs.insureTimer[];
    .tst.closeCalls musteq 0;
    .bs.insureDeadline:0Np;
  };
  should["closes insurance once the window has passed"]{
    .tst.closeCalls:0;
    `.bs.closeInsurance mock {.tst.closeCalls+:1};
    .bs.insureDeadline:.z.p-0D00:00:01;
    .bs.insureTimer[];
    .tst.closeCalls musteq 1;
    .bs.insureDeadline:0Np;
  };
 };

.tst.desc[".bs.closeInsurance"]{
  should["treats anyone who didn't answer as declining, then checks for blackjack and starts turns"]{
    `.bs.lg mock {[x]};
    .tst.settleCalls:0;
    .tst.startCalls:0;
    `.bs.settleDeal mock {.tst.settleCalls+:1};
    `.bs.startTurns mock {.tst.startCalls+:1};
    .bs.insuring:1b;
    .bs.insureDeadline:.z.p;
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`7;`10`8);cnt:16 18i;dealer:2#`A;dealerCnt:11 11i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:0n 0f);
    .bs.closeInsurance[];
    (exec insurance from .bs.tab) musteq 0 0f;
    .bs.insuring musteq 0b;
    null[.bs.insureDeadline] musteq 1b;
    .tst.settleCalls musteq 1;
    .tst.startCalls musteq 1;
  };
 };

.tst.desc[".bs.dealer insurance settlement"]{
  should["pays insurance 2:1 when the dealer has blackjack, including even money on a player blackjack"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    `.bs.start mock {};
    .bs.wwch:0b;
    .bs.da:0Ni;
    .bs.dc:`A`K;
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bs.tab:([]round:3#1;player:1 2 3f;name:`p1`p2`p3;handle:0 1 2i;cards:(`9`7;`10`8;`A`Q);cnt:16 18 21i;dealer:3#enlist`A`K;dealerCnt:3#21i;bet:3#10;return:0 0 10f;profit:3#0n;split:000b;double:000b;insurance:5 0 5f);
    .bs.tab:update out:111b,wait:000b,turn:000b from .bs.tab;
    .bs.cp:(0 1 2i)!`p1`p2`p3;
    .bs.dealer[];
    (exec profit from .bs.res) musteq 0 -10 10f;
  };
  should["loses the insurance when the dealer doesn't have blackjack, and even money still nets the bet"]{
    `.bs.pubMsg mock {[x;y]};
    `.bs.sendMsg mock {[x;y]};
    `.bs.start mock {};
    .bs.wwch:0b;
    .bs.da:0Ni;
    .bs.dc:`A`6;
    .bs.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bs.tab:([]round:3#1;player:1 2 3f;name:`p1`p2`p3;handle:0 1 2i;cards:(`10`9;`10`8;`A`Q);cnt:19 18 21i;dealer:3#enlist`A`6;dealerCnt:3#17i;bet:3#10;return:20 20 25f;profit:3#0n;split:000b;double:000b;insurance:5 0 5f);
    .bs.tab:update out:111b,wait:000b,turn:000b from .bs.tab;
    .bs.cp:(0 1 2i)!`p1`p2`p3;
    .bs.dealer[];
    (exec profit from .bs.res) musteq 5 10 10f;
  };
 };
