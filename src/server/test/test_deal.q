system"l src/server/bin/blackjack.q";
.bjk.loadLibs[];

.tst.desc["stake[]"]{
  should["refuses a bet under 1"]{
    `.bjk.sendMsg mock {[x;y]};
    .bjk.hd:1b;
    .bjk.stake:([name:();handle:()]bet:());
    stake[0];
    count[.bjk.stake] musteq 0;
  };
  should["refuses when the hand isn't done"]{
    `.bjk.sendMsg mock {[x;y]};
    .bjk.hd:0b;
    .bjk.stake:([name:();handle:()]bet:());
    stake[10];
    count[.bjk.stake] musteq 0;
  };
  should["accepts a valid bet and joins it into .bjk.tab, but doesn't deal while another player is unbet"]{
    `.bjk.user mock {`p1};
    `.bjk.sendMsg mock {[x;y]};
    .tst.dealCalls:0;
    `.bjk.deal mock {.tst.dealCalls+:1};
    .bjk.hd:1b;
    .bjk.bd:0b;
    .bjk.betDeadline:0Np;
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:2#0N;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:0f);
    .bjk.stake:([name:();handle:()]bet:());
    stake[10];
    (exec first bet from .bjk.tab where player=1) musteq 10;
    .bjk.bd musteq 1b;
    .tst.dealCalls musteq 0;
  };
  should["deals once the last unbet player places their bet"]{
    `.bjk.user mock {`p1};
    `.bjk.sendMsg mock {[x;y]};
    .tst.dealCalls:0;
    `.bjk.deal mock {.tst.dealCalls+:1};
    .bjk.hd:1b;
    .bjk.bd:0b;
    .bjk.betDeadline:0Np;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 0N;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.stake:([name:();handle:()]bet:());
    stake[10];
    .tst.dealCalls musteq 1;
  };
  should["refuses a fractional bet, which would stop the round from being recorded"]{
    .tst.sent:();
    `.bjk.sendMsg mock {[x;y].tst.sent,:enlist x};
    .bjk.hd:1b;
    .bjk.stake:([name:();handle:()]bet:`long$());
    stake[10.5];
    count[.bjk.stake] musteq 0;
    .tst.sent mustmatch enlist"Bets are whole dollars";
  };
  should["stores an int or short bet as a long, so it fits the bet column"]{
    `.bjk.user mock {`p1};
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.dealIfReady mock {};
    .bjk.hd:1b;
    .bjk.betDeadline:.z.p;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 0N;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.stake:([name:();handle:()]bet:`long$());
    stake[10i];
    (exec bet from .bjk.stake) mustmatch enlist 10;
    stake[5h];
    (exec bet from .bjk.stake) mustmatch enlist 5;
  };
 };

.tst.desc["stake[] betting clock"]{
  should["starts the clock on the round's first bet and tells the players still to bet"]{
    `.bjk.user mock {`p1};
    .tst.msgs:();
    `.bjk.sendMsg mock {[x;y].tst.msgs,:enlist(x;y)};
    `.bjk.deal mock {};
    .bjk.hd:1b;
    .bjk.bd:0b;
    .bjk.betDeadline:0Np;
    .bjk.betTimeout:0D00:00:15;
    .bjk.tab:([]round:1 1 1;player:1 2 3f;name:`p1`p2`p3;handle:0 1 2i;cards:3#enlist();cnt:3#0Ni;dealer:3#`;dealerCnt:3#0Ni;bet:3#0N;return:3#0n;profit:3#0n;split:000b;double:000b;insurance:0f);
    .bjk.stake:([name:();handle:()]bet:());
    t0:.z.p;
    stake[10];
    (.bjk.betDeadline within t0+.bjk.betTimeout+0D00:00:00 0D00:00:01) musteq 1b;
    .tst.msgs mustmatch (("Betting closes in 15 seconds";1i);("Betting closes in 15 seconds";2i));
  };
  should["doesn't restart the clock on later bets"]{
    `.bjk.user mock {`p2};
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.deal mock {};
    .bjk.hd:1b;
    .bjk.bd:1b;
    deadline:.z.p+0D00:00:05;
    .bjk.betDeadline:deadline;
    .bjk.tab:([]round:1 1 1;player:1 2 3f;name:`p1`p2`p3;handle:0 1 2i;cards:3#enlist();cnt:3#0Ni;dealer:3#`;dealerCnt:3#0Ni;bet:10 0N 0N;return:3#0n;profit:3#0n;split:000b;double:000b;insurance:0f);
    .bjk.stake:([name:enlist`p1;handle:enlist 0i]bet:enlist 10);
    stake[10];
    .bjk.betDeadline musteq deadline;
  };
 };

.tst.desc[".bjk.betTimer"]{
  should["does nothing while no betting clock is running"]{
    .tst.dealCalls:0;
    `.bjk.deal mock {.tst.dealCalls+:1};
    .bjk.betDeadline:0Np;
    .bjk.tab:([]round:1 1 1;player:1 2 3f;name:`p1`p2`p3;handle:0 1 2i;cards:3#enlist();cnt:3#0Ni;dealer:3#`;dealerCnt:3#0Ni;bet:10 0N 0N;return:3#0n;profit:3#0n;split:000b;double:000b;insurance:0f);
    .bjk.betTimer[];
    .tst.dealCalls musteq 0;
  };
  should["does nothing before betting closes"]{
    .tst.dealCalls:0;
    `.bjk.deal mock {.tst.dealCalls+:1};
    .bjk.betDeadline:.z.p+0D00:00:10;
    .bjk.tab:([]round:1 1 1;player:1 2 3f;name:`p1`p2`p3;handle:0 1 2i;cards:3#enlist();cnt:3#0Ni;dealer:3#`;dealerCnt:3#0Ni;bet:10 0N 0N;return:3#0n;profit:3#0n;split:000b;double:000b;insurance:0f);
    .bjk.betTimer[];
    .tst.dealCalls musteq 0;
  };
  should["deals once betting has closed"]{
    .tst.dealCalls:0;
    `.bjk.deal mock {.tst.dealCalls+:1};
    .bjk.betDeadline:.z.p-0D00:00:01;
    .bjk.tab:([]round:1 1 1;player:1 2 3f;name:`p1`p2`p3;handle:0 1 2i;cards:3#enlist();cnt:3#0Ni;dealer:3#`;dealerCnt:3#0Ni;bet:10 0N 0N;return:3#0n;profit:3#0n;split:000b;double:000b;insurance:0f);
    .bjk.betTimer[];
    .tst.dealCalls musteq 1;
  };
  should["stops the clock without dealing when every bettor has since left"]{
    .tst.dealCalls:0;
    `.bjk.deal mock {.tst.dealCalls+:1};
    .bjk.betDeadline:.z.p-0D00:00:01;
    .bjk.tab:([]round:1 1 1;player:1 2 3f;name:`p1`p2`p3;handle:0 1 2i;cards:3#enlist();cnt:3#0Ni;dealer:3#`;dealerCnt:3#0Ni;bet:3#0N;return:3#0n;profit:3#0n;split:000b;double:000b;insurance:0f);
    .bjk.betTimer[];
    .tst.dealCalls musteq 0;
    null[.bjk.betDeadline] musteq 1b;
    count[.bjk.tab] musteq 3;
  };
  should["sits out the players who didn't bet in time and deals the rest"]{
    .tst.msgs:();
    `.bjk.sendMsg mock {[x;y].tst.msgs,:enlist(x;y)};
    .tst.deal0Calls:0;
    `.bjk.deal0 mock {.tst.deal0Calls+:1;.bjk.hd:1b};
    .bjk.hd:1b;
    .bjk.bd:1b;
    .bjk.betDeadline:.z.p-0D00:00:01;
    .bjk.tab:([]round:1 1 1;player:1 2 3f;name:`p1`p2`p3;handle:0 1 2i;cards:3#enlist();cnt:3#0Ni;dealer:3#`;dealerCnt:3#0Ni;bet:10 0N 0N;return:3#0n;profit:3#0n;split:000b;double:000b;insurance:0f);
    .bjk.betTimer[];
    .tst.deal0Calls musteq 1;
    (exec handle from .bjk.tab) musteq enlist 0i;
    .tst.msgs mustmatch (("No bet placed, please wait until the next hand";1i);("No bet placed, please wait until the next hand";2i));
    null[.bjk.betDeadline] musteq 1b;
  };
 };

.tst.desc[".bjk.deal0"]{
  should["does nothing when no players are seated"]{
    `.bjk.pubMsg mock {[x;y]};
    .tst.getCardCalls:0;
    `.bjk.getCard mock {.tst.getCardCalls+:1;`5};
    .bjk.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!();
    .bjk.deal0[];
    .tst.getCardCalls musteq 0;
  };
  should["rebuilds the deck when fewer than 78 cards remain"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    .tst.buildCalls:0;
    .tst.shuffleCalls:0;
    `.bjk.buildDeck mock {.tst.buildCalls+:1};
    `.bjk.shuffle mock {.tst.shuffleCalls+:1};
    `.bjk.getCard mock {`5};
    .bjk.deck:5#`2;
    .bjk.rnd:0;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.deal0[];
    .tst.buildCalls musteq 1;
    .tst.shuffleCalls musteq 1;
  };
  should["deals two cards to every player and two to the dealer, computing counts"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    .bjk.deck:200#`2;
    .tst.cardseq:`7`8`5`3;                                                                         / p1's 1st, dealer's 1st (up-card), p1's 2nd, dealer's 2nd (hole card)
    `.bjk.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bjk.rnd:0;
    .bjk.hd:1b;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.deal0[];
    (exec first cards from .bjk.tab) mustmatch`7`5;
    (exec first cnt from .bjk.tab) musteq 12i;
    .bjk.dc mustmatch`8`3;
    .bjk.hd musteq 0b;
  };
  should["deals each player's first card in seating order before either gets a second, with multiple players"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    .bjk.deck:200#`2;
    .tst.cardseq:`2`9`5`3`8`6;                                                                     / p1's 1st, p2's 1st, dealer's up-card, p1's 2nd, p2's 2nd, dealer's hole card
    `.bjk.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bjk.rnd:0;
    .bjk.hd:1b;
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:0f);
    .bjk.deal0[];
    (exec first cards from .bjk.tab where player=1) mustmatch`2`3;
    (exec first cards from .bjk.tab where player=2) mustmatch`9`8;
    (exec first cnt from .bjk.tab where player=1) musteq 5i;
    (exec first cnt from .bjk.tab where player=2) musteq 17i;
    .bjk.dc mustmatch`5`6;
    .bjk.hd musteq 0b;
  };
  should["an immediate player blackjack against a dealer up-card under 10 pays out and calls .bjk.dealer[] when no one else is left to act"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    .bjk.deck:200#`2;
    .tst.cardseq:`A`5`K`3;                                                                         / p1: A,K = 21; dealer up-card 5 (<10)
    `.bjk.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .tst.stickCalls:0;
    `stick mock {.tst.stickCalls+:1};
    .tst.dealerCalls:0;
    `.bjk.dealer mock {.tst.dealerCalls+:1};
    .bjk.rnd:0;
    .bjk.hd:1b;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.deal0[];
    (exec first return from .bjk.tab) musteq 25f;
    (exec first out from .bjk.tab) musteq 1b;
    .tst.stickCalls musteq 0;
    .tst.dealerCalls musteq 1;
    .bjk.hd musteq 1b;
  };
  should["pays a player blackjack immediately against a dealer 10 up-card once the dealer has peeked and has no blackjack"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    .bjk.deck:200#`2;
    .tst.cardseq:`A`K`K`3;                                                                         / p1: A,K = 21; dealer K up, 3 in the hole (no dealer blackjack)
    `.bjk.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .tst.stickCalls:0;
    `stick mock {.tst.stickCalls+:1};
    .tst.dealerCalls:0;
    `.bjk.dealer mock {.tst.dealerCalls+:1};
    .bjk.rnd:0;
    .bjk.hd:1b;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.deal0[];
    (exec first return from .bjk.tab) musteq 25f;
    (exec first out from .bjk.tab) musteq 1b;
    .tst.stickCalls musteq 0;
    .tst.dealerCalls musteq 1;
  };
  should["ends the hand via .bjk.dealerPeek before anyone acts when the dealer has blackjack"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    .bjk.deck:200#`2;
    .tst.cardseq:`6`K`5`A;                                                                         / p1: 6,5 = 11; dealer K up, A in the hole (blackjack)
    `.bjk.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .tst.peekCalls:0;
    `.bjk.dealerPeek mock {.tst.peekCalls+:1};
    .tst.deal1Calls:0;
    `.bjk.deal1 mock {[h].tst.deal1Calls+:1};
    .bjk.rnd:0;
    .bjk.hd:1b;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.deal0[];
    .tst.peekCalls musteq 1;
    .tst.deal1Calls musteq 0;
    (exec first cnt from .bjk.tab) musteq 11i;
  };
  should["pays out one player's immediate blackjack but doesn't call .bjk.dealer[] while another player still needs to act"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    .bjk.deck:200#`2;
    .tst.cardseq:`A`9`5`K`8`3;                                                                     / p1: A,K = 21 (blackjack); p2: 9,8 = 17 (no blackjack); dealer up-card 5 (<10)
    `.bjk.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .tst.dealerCalls:0;
    `.bjk.dealer mock {.tst.dealerCalls+:1};
    .bjk.rnd:0;
    .bjk.hd:1b;
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:0f);
    .bjk.deal0[];
    (exec first return from .bjk.tab where player=1) musteq 25f;
    (exec first out from .bjk.tab where player=1) musteq 1b;
    (exec first cnt from .bjk.tab where player=2) musteq 17i;
    (exec first out from .bjk.tab where player=2) musteq 0b;
    .tst.dealerCalls musteq 0;
    .bjk.hd musteq 0b;
  };
  should["calls .bjk.dealer[] exactly once, after the last player's immediate blackjack leaves nobody still in"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    .bjk.deck:200#`2;
    .tst.cardseq:`A`A`5`K`Q`3;                                                                     / p1: A,K = 21 (blackjack); p2: A,Q = 21 (blackjack); dealer up-card 5 (<10)
    `.bjk.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .tst.dealerCalls:0;
    `.bjk.dealer mock {.tst.dealerCalls+:1};
    .bjk.rnd:0;
    .bjk.hd:1b;
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:0f);
    .bjk.deal0[];
    (exec first return from .bjk.tab where player=1) musteq 25f;
    (exec first return from .bjk.tab where player=2) musteq 25f;
    (exec out from .bjk.tab) musteq 11b;
    .tst.dealerCalls musteq 1;
    .bjk.hd musteq 1b;
  };
 };

.tst.desc[".bjk.dealerPeek"]{
  should["sends every player straight to settlement and runs the dealer"]{
    `.bjk.pubMsg mock {[x;y]};
    .tst.dealerCalls:0;
    `.bjk.dealer mock {.tst.dealerCalls+:1};
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`A`K;`6`5);cnt:21 11i;dealer:(`A;`A);dealerCnt:11 11i;bet:10 10;return:0n 0n;profit:0n 0n;split:00b;double:00b;insurance:0f);
    .bjk.tab:update out:00b,wait:00b,turn:00b from .bjk.tab;
    .bjk.cp:0 1i!`p1`p2;
    .bjk.dealerPeek[];
    (exec wait from .bjk.tab) musteq 11b;
    .tst.dealerCalls musteq 1;
  };
 };

.tst.desc[".bjk.deal"]{
  should["refuses to deal before the previous hand is done"]{
    .tst.deal0Calls:0;
    `.bjk.deal0 mock {.tst.deal0Calls+:1};
    .bjk.hd:0b;
    .bjk.bd:1b;
    .bjk.deal[];
    .tst.deal0Calls musteq 0;
  };
  should["refuses to deal until bets are placed"]{
    .tst.deal0Calls:0;
    `.bjk.deal0 mock {.tst.deal0Calls+:1};
    .bjk.hd:1b;
    .bjk.bd:0b;
    .bjk.deal[];
    .tst.deal0Calls musteq 0;
  };
  should["drops any player left with a null bet before dealing"]{
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.deal0 mock {.bjk.hd:1b};
    .bjk.hd:1b;
    .bjk.bd:1b;
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:10 0N;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:0f);
    .bjk.deal[];
    count[.bjk.tab] musteq 1;
    (exec first name from .bjk.tab) musteq`p1;
  };
  should["clears the betting clock"]{
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.deal0 mock {.bjk.hd:1b};
    .bjk.hd:1b;
    .bjk.bd:1b;
    .bjk.betDeadline:.z.p+0D00:00:10;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.deal[];
    null[.bjk.betDeadline] musteq 1b;
  };
  should["sets the first player's turn, rebuilds .bjk.turn and prompts them, when the hand isn't already decided"]{
    .tst.excFuncCalls:();
    `.bjk.excFunc mock {[x;y;z].tst.excFuncCalls,:enlist(x;z)};
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.deal0 mock {.bjk.hd:0b};
    .bjk.hd:1b;
    .bjk.bd:1b;
    .bjk.insuring:0b;
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(enlist`7;enlist`8);cnt:7 8i;dealer:2#`5;dealerCnt:2#5i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:0f);
    .bjk.tab:update out:00b,wait:00b from .bjk.tab;
    .bjk.cp:0 1i!`p1`p2;
    .bjk.deal[];
    (exec first turn from .bjk.tab where player=1) musteq 1b;
    (exec first turn from .bjk.tab where player=2) musteq 0b;
    (exec turn from .bjk.turn) musteq 10b;
    .tst.excFuncCalls mustmatch enlist(`.plr.play;0i);
  };
  should["leaves the turn untouched when .bjk.deal0 already decided the hand"]{
    .tst.excFuncCalls:();
    `.bjk.excFunc mock {[x;y;z].tst.excFuncCalls,:enlist(x;z)};
    `.bjk.deal0 mock {.bjk.hd:1b};
    .bjk.hd:1b;
    .bjk.bd:1b;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`K;cnt:enlist 21i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10;return:enlist 25f;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.tab:update out:enlist 1b,wait:enlist 0b from .bjk.tab;
    .bjk.cp:enlist[0i]!enlist`p1;
    .bjk.deal[];
    .tst.excFuncCalls mustmatch();
  };
 };

.tst.desc[".bjk.dealer0"]{
  should["doesn't draw when the dealer already has 17 or more"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.dc:`K`8;
    .tst.getCardCalls:0;
    `.bjk.getCard mock {.tst.getCardCalls+:1;`5};
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K;dealerCnt:enlist 10i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.dealer0[];
    .tst.getCardCalls musteq 0;
    (exec first dealerCnt from .bjk.tab) musteq 18i;
  };
  should["hits until the dealer reaches 17 or more"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.dc:`6`5;
    .tst.cardseq:`4`2`2`2`2;
    `.bjk.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`6;dealerCnt:enlist 6i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.dealer0[];
    (exec first dealer from .bjk.tab) mustmatch`6`5`4`2;
    (exec first dealerCnt from .bjk.tab) musteq 17i;
  };
  should["reduces a newly-drawn ace by 10 to avoid busting"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.dc:`6`9;
    .tst.cardseq:`A`3`2`2`2;
    `.bjk.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`6;dealerCnt:enlist 6i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.dealer0[];
    (exec first dealerCnt from .bjk.tab) musteq 19i;
  };
  should["drops an ace drawn earlier to 1 when a later card would otherwise bust the dealer"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.dc:`3`2;
    .tst.cardseq:`A`10`2;                                                                          / 3,2,A = soft 16; +10 = hard 16 (not 26); +2 = 18
    `.bjk.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`3;dealerCnt:enlist 3i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.dealer0[];
    (exec first dealer from .bjk.tab) mustmatch`3`2`A`10`2;
    (exec first dealerCnt from .bjk.tab) musteq 18i;
  };
 };

.tst.desc[".bjk.dealerDraws"]{
  should["draws below 17 and stands on hard 17 under either rule"]{
    .bjk.hitSoft17:0b;
    .bjk.dealerDraws[`K`6] musteq 1b;
    .bjk.dealerDraws[`K`7] musteq 0b;
    .bjk.hitSoft17:1b;
    .bjk.dealerDraws[`K`6] musteq 1b;
    .bjk.dealerDraws[`K`7] musteq 0b;
  };
  should["stands on soft 17 when the table stands on all 17s"]{
    .bjk.hitSoft17:0b;
    .bjk.dealerDraws[`A`6] musteq 0b;
  };
  should["draws on soft 17 when the table hits soft 17, but stands on soft 18"]{
    .bjk.hitSoft17:1b;
    .bjk.dealerDraws[`A`6] musteq 1b;
    .bjk.dealerDraws[`A`A`5] musteq 1b;
    .bjk.dealerDraws[`A`7] musteq 0b;
  };
 };

.tst.desc[".bjk.dealer0 soft 17"]{
  should["stands on A,6 when the table stands on all 17s"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.hitSoft17:0b;
    .bjk.dc:`A`6;
    .tst.getCardCalls:0;
    `.bjk.getCard mock {.tst.getCardCalls+:1;`2};
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`A;dealerCnt:enlist 11i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.dealer0[];
    .tst.getCardCalls musteq 0;
    .bjk.dealerCount musteq 17i;
  };
  should["draws on A,6 when the table hits soft 17"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.hitSoft17:1b;
    .bjk.dc:`A`6;
    `.bjk.getCard mock {`2};
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`A;dealerCnt:enlist 11i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.dealer0[];
    (exec first dealer from .bjk.tab) mustmatch`A`6`2;
    .bjk.dealerCount musteq 19i;
  };
 };

.tst.desc[".bjk.dealer1"]{
  should["pays double the bet when the dealer busts and the player is 21 or under"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.dealerCount:24;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K;dealerCnt:enlist 24i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.dealer1[1f];
    (exec first return from .bjk.tab) musteq 20f;
  };
  should["pays nothing when both the dealer and the player bust"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.dealerCount:24;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`K`Q`5;cnt:enlist 25i;dealer:enlist`K;dealerCnt:enlist 24i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.dealer1[1f];
    (exec first return from .bjk.tab) musteq 0f;
  };
  should["pushes (returns the bet) when the counts are equal and both are 21 or under"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.dealerCount:18;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`9;cnt:enlist 18i;dealer:enlist`K;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.dealer1[1f];
    (exec first return from .bjk.tab) musteq 10f;
  };
  should["pays nothing when the dealer is under 21 and beats the player"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.dealerCount:19;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K;dealerCnt:enlist 19i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.dealer1[1f];
    (exec first return from .bjk.tab) musteq 0f;
  };
  should["pays nothing when the dealer is under 21 but the player busted"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.dealerCount:18;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`K`Q`5;cnt:enlist 25i;dealer:enlist`K;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.dealer1[1f];
    (exec first return from .bjk.tab) musteq 0f;
  };
  should["pays double the bet for a plain win when the player beats an under-21 dealer without blackjack"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.dealerCount:18;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`9`1;cnt:enlist 19i;dealer:enlist`K`3`4;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.dealer1[1f];
    (exec first return from .bjk.tab) musteq 20f;
  };
  should["pays 1.5x plus the bet for a two-card 21 (blackjack) against an under-21 dealer"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.dealerCount:19;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`K;cnt:enlist 21i;dealer:enlist`K`3`6;dealerCnt:enlist 19i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.dealer1[1f];
    (exec first return from .bjk.tab) musteq 25f;
  };
  should["pays nothing when the dealer has exactly 21 and the player doesn't"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.dealerCount:21;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K`Q`A;dealerCnt:enlist 21i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.dealer1[1f];
    (exec first return from .bjk.tab) musteq 0f;
  };
  should["pays 1.5x plus the bet for a blackjack when the dealer stands on two cards"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.dealerCount:17;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`K;cnt:enlist 21i;dealer:enlist`K`7;dealerCnt:enlist 17i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.dealer1[1f];
    (exec first return from .bjk.tab) musteq 25f;
  };
  should["pays 1.5x plus the bet for a blackjack when the dealer busts"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.dealerCount:24;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`K;cnt:enlist 21i;dealer:enlist`K`4`K;dealerCnt:enlist 24i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.dealer1[1f];
    (exec first return from .bjk.tab) musteq 25f;
  };
  should["pays 1.5x plus the bet for a blackjack against a dealer's three-card 21"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.dealerCount:21;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`K;cnt:enlist 21i;dealer:enlist`K`4`7;dealerCnt:enlist 21i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.dealer1[1f];
    (exec first return from .bjk.tab) musteq 25f;
  };
  should["pays nothing when the dealer has blackjack and the player has a three-card 21"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.dealerCount:21;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`5`6`10;cnt:enlist 21i;dealer:enlist`A`K;dealerCnt:enlist 21i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.dealer1[1f];
    (exec first return from .bjk.tab) musteq 0f;
  };
  should["pushes when both the dealer and the player have blackjack"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.dealerCount:21;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`Q;cnt:enlist 21i;dealer:enlist`A`K;dealerCnt:enlist 21i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.dealer1[1f];
    (exec first return from .bjk.tab) musteq 10f;
  };
  should["pays a two-card 21 on a split hand as a plain win, not a blackjack"]{
    `.bjk.pubMsg mock {[x;y]};
    .bjk.dealerCount:18;
    .bjk.tab:([]round:enlist 1;player:enlist 1.01;name:enlist`p1;handle:enlist 0i;cards:enlist`A`K;cnt:enlist 21i;dealer:enlist`K`8;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 1b;double:enlist 0b;insurance:0f);
    .bjk.dealer1[1.01];
    (exec first return from .bjk.tab) musteq 20f;
  };
 };

.tst.desc[".bjk.dealer"]{
  should["skips .bjk.dealer0/.bjk.dealer1 when every player is already out, but still records the result"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    .bjk.wwch:0b;
    .bjk.pit:0Ni;
    .bjk.dc:`K`5;
    .tst.dealer0Calls:0;
    .tst.dealer1Calls:0;
    `.bjk.dealer0 mock {.tst.dealer0Calls+:1};
    `.bjk.dealer1 mock {[p].tst.dealer1Calls+:1};
    .tst.startCalls:0;
    `.bjk.start mock {.tst.startCalls+:1};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K`Q`5;dealerCnt:enlist 25i;bet:enlist 10;return:enlist 0f;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.tab:update out:enlist 1b,wait:enlist 0b,turn:enlist 0b from .bjk.tab;
    .bjk.cp:enlist[0i]!enlist`p1;
    .bjk.dealer[];
    .tst.dealer0Calls musteq 0;
    .tst.dealer1Calls musteq 0;
    (exec last round from .bjk.res) musteq 1;
    .bjk.bd musteq 0b;
    .bjk.hd musteq 1b;
  };
  should["resolves every waiting player through .bjk.dealer0/.bjk.dealer1 and marks them out"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    .bjk.wwch:0b;
    .bjk.pit:0Ni;
    .tst.dealer0Calls:0;
    .tst.dealer1Args:();
    `.bjk.dealer0 mock {.tst.dealer0Calls+:1};
    `.bjk.dealer1 mock {[p].tst.dealer1Args,:p};
    .tst.startCalls:0;
    `.bjk.start mock {.tst.startCalls+:1};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`8;`K`7);cnt:17 17i;dealer:(`K`Q`5;`K`Q`5);dealerCnt:25 25i;bet:10 10;return:0 0f;profit:2#0n;split:00b;double:00b;insurance:0f);
    .bjk.tab:update out:00b,wait:11b,turn:00b from .bjk.tab;
    .bjk.cp:0 1i!`p1`p2;
    .bjk.dealer[];
    .tst.dealer0Calls musteq 1;
    .tst.dealer1Args musteq 1 2f;
    (exec out from .bjk.tab) musteq 11b;
    (exec wait from .bjk.tab) musteq 00b;
  };
  should["notifies pitboss with the round's results when it's connected"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    .bjk.wwch:0b;
    .bjk.pit:99i;
    .bjk.dc:`K`5;
    `.bjk.start mock {};
    .tst.excFuncCalls:();
    `.bjk.excFunc mock {[x;y;z].tst.excFuncCalls,:enlist(x;z)};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K`Q`5;dealerCnt:enlist 25i;bet:enlist 10;return:enlist 0f;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.tab:update out:enlist 1b,wait:enlist 0b,turn:enlist 0b from .bjk.tab;
    .bjk.cp:enlist[0i]!enlist`p1;
    .bjk.dealer[];
    .tst.excFuncCalls mustmatch enlist(`.pit.gameover;99i);
  };
  should["sends the detection algo the shoe's results and the round just played"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    .bjk.wwch:0b;
    .bjk.pit:99i;
    .bjk.dc:`K`5;
    .bjk.rnd:4;
    `.bjk.start mock {};
    .tst.sent:();
    `.bjk.excFunc mock {[x;y;z].tst.sent,:enlist(x;y;z)};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bjk.tab:([]round:enlist 4;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K`Q`5;dealerCnt:enlist 25i;bet:enlist 10;return:enlist 0f;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.tab:update out:enlist 1b,wait:enlist 0b,turn:enlist 0b from .bjk.tab;
    .bjk.cp:enlist[0i]!enlist`p1;
    .bjk.dealer[];
    (.tst.sent[0;1]`rnd) musteq 4;
    (.tst.sent[0;1]`res) mustmatch .bjk.res;
  };
  should["records each hand's net profit - return minus bet - in .bjk.res"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.start mock {};
    .bjk.wwch:0b;
    .bjk.pit:0Ni;
    .bjk.dc:`K`5;
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bjk.tab:([]round:5#1;player:1 2 3 4 5f;name:`p1`p2`p3`p4`p5;handle:0 1 2 3 4i;cards:(`K`9;`K`6;`K`8;`A`K;`5`6`K);cnt:19 16 18 21 21i;dealer:5#`K;dealerCnt:5#18i;bet:10 10 10 10 20;return:20 0 10 25 40f;profit:5#0n;split:00000b;double:00001b;insurance:0f);
    .bjk.tab:update out:11111b,wait:00000b,turn:00000b from .bjk.tab;
    .bjk.cp:(0 1 2 3 4i)!`p1`p2`p3`p4`p5;
    .bjk.dealer[];
    (exec profit from .bjk.res) musteq 10 -10 0 15 20f;
  };
  should["doesn't carry a running total into a player's later hands"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.start mock {};
    .bjk.wwch:0b;
    .bjk.pit:0Ni;
    .bjk.dc:`K`5;
    .bjk.res:([]round:enlist 1;player:enlist 1;name:enlist`p1;handle:enlist 0i;cards:enlist`K`9;cnt:enlist 19i;dealer:enlist`K`8;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 20f;profit:enlist 10f;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.tab:([]round:enlist 2;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`K`6`K;cnt:enlist 26i;dealer:enlist`K;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 0f;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.tab:update out:enlist 1b,wait:enlist 0b,turn:enlist 0b from .bjk.tab;
    .bjk.cp:enlist[0i]!enlist`p1;
    .bjk.dealer[];
    (exec profit from .bjk.res) musteq 10 -10f;
  };
  should["clears the round's bets before starting the next hand"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    .bjk.wwch:0b;
    .bjk.pit:0Ni;
    .bjk.dc:`K`5;
    .tst.stakeAtStart:-1;
    `.bjk.start mock {.tst.stakeAtStart:count .bjk.stake};
    .bjk.stake:([name:enlist`p1;handle:enlist 0i]bet:enlist 10);
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K`Q`5;dealerCnt:enlist 25i;bet:enlist 10;return:enlist 0f;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.tab:update out:enlist 1b,wait:enlist 0b,turn:enlist 0b from .bjk.tab;
    .bjk.cp:enlist[0i]!enlist`p1;
    .bjk.dealer[];
    .tst.stakeAtStart musteq 0;
  };
  should["always starts the next hand - the server has no round-count cap of its own"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    .bjk.wwch:0b;
    .bjk.pit:0Ni;
    .bjk.dc:`K`5;
    .tst.startCalls:0;
    `.bjk.start mock {.tst.startCalls+:1};
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K`Q`5;dealerCnt:enlist 25i;bet:enlist 10;return:enlist 0f;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.tab:update out:enlist 1b,wait:enlist 0b,turn:enlist 0b from .bjk.tab;
    .bjk.cp:enlist[0i]!enlist`p1;
    .bjk.dealer[];
    .tst.startCalls musteq 1;
  };
 };

.tst.desc[".bjk.deal0 insurance offer"]{
  should["offers insurance before the dealer checks for blackjack when the up-card is an ace"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    .tst.sent:();
    `.bjk.excFunc mock {[x;y;z].tst.sent,:enlist(x;z)};
    .tst.peekCalls:0;
    .tst.deal1Calls:0;
    `.bjk.dealerPeek mock {.tst.peekCalls+:1};
    `.bjk.deal1 mock {[h].tst.deal1Calls+:1};
    .bjk.deck:200#`2;
    .tst.cardseq:`9`A`7`K;
    `.bjk.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bjk.rnd:0;
    .bjk.hd:1b;
    .bjk.insuring:0b;
    .bjk.insureDeadline:0Np;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.cp:enlist[0i]!enlist`p1;
    .bjk.deal0[];
    .bjk.insuring musteq 1b;
    null[.bjk.insureDeadline] musteq 0b;
    (exec first null insurance from .bjk.tab) musteq 1b;
    .tst.sent mustmatch enlist(`.plr.insure;0i);
    .tst.peekCalls musteq 0;
    .tst.deal1Calls musteq 0;
  };
  should["doesn't offer insurance under any other up-card"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    .tst.sent:();
    `.bjk.excFunc mock {[x;y;z].tst.sent,:enlist(x;z)};
    `.bjk.deal1 mock {[h]};
    .bjk.deck:200#`2;
    .tst.cardseq:`9`K`7`6;
    `.bjk.getCard mock {c:first .tst.cardseq;.tst.cardseq:1_.tst.cardseq;c};
    .bjk.rnd:0;
    .bjk.hd:1b;
    .bjk.insuring:0b;
    .bjk.tab:([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b;insurance:0f);
    .bjk.cp:enlist[0i]!enlist`p1;
    .bjk.deal0[];
    .bjk.insuring musteq 0b;
    count[.tst.sent] musteq 0;
  };
 };

.tst.desc[".bjk.deal while insurance is open"]{
  should["doesn't start anyone's turn until insurance closes"]{
    `.bjk.sendMsg mock {[x;y]};
    .tst.startCalls:0;
    `.bjk.startTurns mock {.tst.startCalls+:1};
    `.bjk.deal0 mock {.bjk.hd:0b;.bjk.insuring:1b};
    .bjk.hd:1b;
    .bjk.bd:1b;
    .bjk.insuring:0b;
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`7;`10`8);cnt:16 18i;dealer:2#`A;dealerCnt:11 11i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:2#0n);
    .bjk.deal[];
    .tst.startCalls musteq 0;
    .bjk.insuring:0b;
  };
 };

.tst.desc["insure[]"]{
  should["records the side bet"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.closeInsurance mock {};
    .bjk.insuring:1b;
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`7;`10`8);cnt:16 18i;dealer:2#`A;dealerCnt:11 11i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:2#0n);
    insure[5];
    (exec first insurance from .bjk.tab where handle=0i) musteq 5f;
    (exec first null insurance from .bjk.tab where handle=1i) musteq 1b;
    .bjk.insuring:0b;
  };
  should["records a decline as zero"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.closeInsurance mock {};
    .bjk.insuring:1b;
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`7;`10`8);cnt:16 18i;dealer:2#`A;dealerCnt:11 11i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:2#0n);
    insure[0];
    (exec first insurance from .bjk.tab where handle=0i) musteq 0f;
    .bjk.insuring:0b;
  };
  should["refuses more than half the bet"]{
    `.bjk.sendMsg mock {[x;y]};
    .bjk.insuring:1b;
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`7;`10`8);cnt:16 18i;dealer:2#`A;dealerCnt:11 11i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:2#0n);
    insure[6];
    (exec first null insurance from .bjk.tab where handle=0i) musteq 1b;
    .bjk.insuring:0b;
  };
  should["refuses a second answer"]{
    `.bjk.sendMsg mock {[x;y]};
    .bjk.insuring:1b;
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`7;`10`8);cnt:16 18i;dealer:2#`A;dealerCnt:11 11i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:0 0n);
    insure[5];
    (exec first insurance from .bjk.tab where handle=0i) musteq 0f;
    .bjk.insuring:0b;
  };
  should["refuses when insurance isn't on offer"]{
    `.bjk.sendMsg mock {[x;y]};
    .bjk.insuring:0b;
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`7;`10`8);cnt:16 18i;dealer:2#`A;dealerCnt:11 11i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:2#0n);
    insure[5];
    (exec first null insurance from .bjk.tab where handle=0i) musteq 1b;
  };
  should["closes insurance once the last player answers"]{
    `.bjk.pubMsg mock {[x;y]};
    .tst.closeCalls:0;
    `.bjk.closeInsurance mock {.tst.closeCalls+:1};
    .bjk.insuring:1b;
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`7;`10`8);cnt:16 18i;dealer:2#`A;dealerCnt:11 11i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:0n 0f);
    insure[5];
    .tst.closeCalls musteq 1;
    .bjk.insuring:0b;
  };
 };

.tst.desc[".bjk.insureTimer"]{
  should["does nothing before the window closes"]{
    .tst.closeCalls:0;
    `.bjk.closeInsurance mock {.tst.closeCalls+:1};
    .bjk.insureDeadline:.z.p+0D00:00:10;
    .bjk.insureTimer[];
    .tst.closeCalls musteq 0;
    .bjk.insureDeadline:0Np;
  };
  should["closes insurance once the window has passed"]{
    .tst.closeCalls:0;
    `.bjk.closeInsurance mock {.tst.closeCalls+:1};
    .bjk.insureDeadline:.z.p-0D00:00:01;
    .bjk.insureTimer[];
    .tst.closeCalls musteq 1;
    .bjk.insureDeadline:0Np;
  };
 };

.tst.desc[".bjk.closeInsurance"]{
  should["treats anyone who didn't answer as declining, then checks for blackjack and starts turns"]{
    `.bjk.lg mock {[x]};
    .tst.settleCalls:0;
    .tst.startCalls:0;
    `.bjk.settleDeal mock {.tst.settleCalls+:1};
    `.bjk.startTurns mock {.tst.startCalls+:1};
    .bjk.insuring:1b;
    .bjk.insureDeadline:.z.p;
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`7;`10`8);cnt:16 18i;dealer:2#`A;dealerCnt:11 11i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b;insurance:0n 0f);
    .bjk.closeInsurance[];
    (exec insurance from .bjk.tab) musteq 0 0f;
    .bjk.insuring musteq 0b;
    null[.bjk.insureDeadline] musteq 1b;
    .tst.settleCalls musteq 1;
    .tst.startCalls musteq 1;
  };
 };

.tst.desc[".bjk.dealer insurance settlement"]{
  should["pays insurance 2:1 when the dealer has blackjack, including even money on a player blackjack"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.start mock {};
    .bjk.wwch:0b;
    .bjk.pit:0Ni;
    .bjk.dc:`A`K;
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bjk.tab:([]round:3#1;player:1 2 3f;name:`p1`p2`p3;handle:0 1 2i;cards:(`9`7;`10`8;`A`Q);cnt:16 18 21i;dealer:3#enlist`A`K;dealerCnt:3#21i;bet:3#10;return:0 0 10f;profit:3#0n;split:000b;double:000b;insurance:5 0 5f);
    .bjk.tab:update out:111b,wait:000b,turn:000b from .bjk.tab;
    .bjk.cp:(0 1 2i)!`p1`p2`p3;
    .bjk.dealer[];
    (exec profit from .bjk.res) musteq 0 -10 10f;
  };
  should["loses the insurance when the dealer doesn't have blackjack, and even money still nets the bet"]{
    `.bjk.pubMsg mock {[x;y]};
    `.bjk.sendMsg mock {[x;y]};
    `.bjk.start mock {};
    .bjk.wwch:0b;
    .bjk.pit:0Ni;
    .bjk.dc:`A`6;
    .bjk.res:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .bjk.tab:([]round:3#1;player:1 2 3f;name:`p1`p2`p3;handle:0 1 2i;cards:(`10`9;`10`8;`A`Q);cnt:19 18 21i;dealer:3#enlist`A`6;dealerCnt:3#17i;bet:3#10;return:20 20 25f;profit:3#0n;split:000b;double:000b;insurance:5 0 5f);
    .bjk.tab:update out:111b,wait:000b,turn:000b from .bjk.tab;
    .bjk.cp:(0 1 2i)!`p1`p2`p3;
    .bjk.dealer[];
    (exec profit from .bjk.res) musteq 5 10 10f;
  };
 };
