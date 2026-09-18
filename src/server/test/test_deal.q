system "l src/server/bin/blackjackServer.q";

.tst.desc["stake[]"]{
  should["refuses a bet under 1"]{
    `sendMsg mock {[x;y]};
    .bs.hd::1b;
    .bs.stake::([name:();handle:()]bet:());
    stake[0];
    (count .bs.stake) musteq 0;
    };
  should["refuses when the hand isn't done"]{
    `sendMsg mock {[x;y]};
    .bs.hd::0b;
    .bs.stake::([name:();handle:()]bet:());
    stake[10];
    (count .bs.stake) musteq 0;
    };
  should["accepts a valid bet and joins it into .bs.tab, but doesn't deal while another player is unbet"]{
    `user mock {`p1};
    dealCalls::0;
    `.bs.deal mock {dealCalls+::1};
    .bs.hd::1b; .bs.bd::0b;
    .bs.tab::([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:2#0N;return:2#0n;profit:2#0n;split:00b;double:00b);
    .bs.stake::([name:();handle:()]bet:());
    stake[10];
    (exec first bet from .bs.tab where player=1) musteq 10;
    .bs.bd musteq 1b;
    dealCalls musteq 0;
    };
  should["deals once the last unbet player places their bet"]{
    `user mock {`p1};
    dealCalls::0;
    `.bs.deal mock {dealCalls+::1};
    .bs.hd::1b; .bs.bd::0b;
    .bs.tab::([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 0N;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.stake::([name:();handle:()]bet:());
    stake[10];
    dealCalls musteq 1;
    };
 };

.tst.desc[".bs.deal0"]{
  should["does nothing when no players are seated"]{
    `pubMsg mock {[x;y]};
    getCardCalls::0;
    `getCard mock {getCardCalls+::1;`5};
    .bs.tab::flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!();
    .bs.deal0[];
    getCardCalls musteq 0;
    };
  should["rebuilds the deck when fewer than 78 cards remain"]{
    `pubMsg mock {[x;y]};
    `sendMsg mock {[x;y]};
    buildCalls::0; shuffleCalls::0;
    `buildDeck mock {buildCalls+::1};
    `shuffle mock {shuffleCalls+::1};
    `getCard mock {`5};
    .bs.deck::5#`2;
    .bs.rnd::0;
    .bs.tab::([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.deal0[];
    buildCalls musteq 1;
    shuffleCalls musteq 1;
    };
  should["deals two cards to every player and two to the dealer, computing counts"]{
    `pubMsg mock {[x;y]};
    `sendMsg mock {[x;y]};
    .bs.deck::200#`2;
    cardseq::`7`8`5`3;  / p1's 1st, dealer's 1st (up-card), p1's 2nd, dealer's 2nd (hole card)
    `getCard mock {c:first cardseq;cardseq::1_cardseq;c};
    .bs.rnd::0;
    .bs.hd::1b;
    .bs.tab::([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.deal0[];
    (exec first cards from .bs.tab) mustmatch `7`5;
    (exec first cnt from .bs.tab) musteq 12i;
    DC mustmatch `8`3;
    .bs.hd musteq 0b;
    };
  should["an immediate player blackjack against a dealer up-card under 10 pays out and calls .bs.dealer[] when no one else is left to act"]{
    `pubMsg mock {[x;y]};
    `sendMsg mock {[x;y]};
    .bs.deck::200#`2;
    cardseq::`A`5`K`3;  / p1: A,K = 21; dealer up-card 5 (<10)
    `getCard mock {c:first cardseq;cardseq::1_cardseq;c};
    stickCalls::0;
    `stick mock {stickCalls+::1};
    dealerCalls::0;
    `.bs.dealer mock {dealerCalls+::1};
    .bs.rnd::0;
    .bs.hd::1b;
    .bs.tab::([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.deal0[];
    (exec first return from .bs.tab) musteq 25f;
    (exec first out from .bs.tab) musteq 1b;
    stickCalls musteq 0;
    dealerCalls musteq 1;
    .bs.hd musteq 1b;
    };
  should["an immediate player blackjack against a dealer up-card of 10 or more defers to stick[] instead of paying out"]{
    `pubMsg mock {[x;y]};
    `sendMsg mock {[x;y]};
    .bs.deck::200#`2;
    cardseq::`A`K`K`3;  / p1: A,K = 21; dealer up-card K (>=10)
    `getCard mock {c:first cardseq;cardseq::1_cardseq;c};
    stickCalls::0;
    `stick mock {stickCalls+::1};
    dealerCalls::0;
    `.bs.dealer mock {dealerCalls+::1};
    .bs.rnd::0;
    .bs.hd::1b;
    .bs.tab::([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist();cnt:enlist 0Ni;dealer:enlist`;dealerCnt:enlist 0Ni;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.deal0[];
    (exec first return from .bs.tab) mustmatch 0n;
    (exec first out from .bs.tab) musteq 0b;
    stickCalls musteq 1;
    dealerCalls musteq 0;
    };
 };

.tst.desc[".bs.deal"]{
  should["refuses to deal before the previous hand is done"]{
    deal0Calls::0;
    `.bs.deal0 mock {deal0Calls+::1};
    .bs.hd::0b; .bs.bd::1b;
    .bs.deal[];
    deal0Calls musteq 0;
    };
  should["refuses to deal until bets are placed"]{
    deal0Calls::0;
    `.bs.deal0 mock {deal0Calls+::1};
    .bs.hd::1b; .bs.bd::0b;
    .bs.deal[];
    deal0Calls musteq 0;
    };
  should["drops any player left with a null bet before dealing"]{
    `sendMsg mock {[x;y]};
    `.bs.deal0 mock {.bs.hd::1b};
    .bs.hd::1b; .bs.bd::1b;
    .bs.tab::([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:10 0N;return:2#0n;profit:2#0n;split:00b;double:00b);
    .bs.deal[];
    (count .bs.tab) musteq 1;
    (exec first name from .bs.tab) musteq `p1;
    };
  should["sets the first player's turn, rebuilds .bs.turn and prompts them, when the hand isn't already decided"]{
    excFuncCalls::();
    `excFunc mock {[x;y;z] excFuncCalls,:enlist(x;z)};
    `sendMsg mock {[x;y]};
    `.bs.deal0 mock {.bs.hd::0b};
    .bs.hd::1b; .bs.bd::1b; .bs.count::0f;
    .bs.tab::([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(enlist`7;enlist`8);cnt:7 8i;dealer:2#`5;dealerCnt:2#5i;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b);
    .bs.tab::update out:00b,wait:00b from .bs.tab;
    cp::0 1i!`p1`p2;
    .bs.deal[];
    (exec first turn from .bs.tab where player=1) musteq 1b;
    (exec first turn from .bs.tab where player=2) musteq 0b;
    (exec turn from .bs.turn) musteq 10b;
    excFuncCalls mustmatch enlist(`.mc.play;0i);
    };
  should["leaves the turn untouched when .bs.deal0 already decided the hand"]{
    excFuncCalls::();
    `excFunc mock {[x;y;z] excFuncCalls,:enlist(x;z)};
    `.bs.deal0 mock {.bs.hd::1b};
    .bs.hd::1b; .bs.bd::1b;
    .bs.tab::([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`K;cnt:enlist 21i;dealer:enlist`5;dealerCnt:enlist 5i;bet:enlist 10;return:enlist 25f;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab::update out:enlist 1b,wait:enlist 0b from .bs.tab;
    cp::enlist[0i]!enlist`p1;
    .bs.deal[];
    excFuncCalls musteq ();
    };
 };

.tst.desc[".bs.dealer0"]{
  should["doesn't draw when the dealer already has 17 or more"]{
    `pubMsg mock {[x;y]};
    DC::`K`8;
    acelowD::0b;
    getCardCalls::0;
    `getCard mock {getCardCalls+::1;`5};
    .bs.tab::([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K;dealerCnt:enlist 10i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer0[];
    getCardCalls musteq 0;
    (exec first dealerCnt from .bs.tab) musteq 18i;
    };
  should["hits until the dealer reaches 17 or more"]{
    `pubMsg mock {[x;y]};
    DC::`6`5;
    acelowD::0b;
    cardseq::`4`2`2`2`2;
    `getCard mock {c:first cardseq;cardseq::1_cardseq;c};
    .bs.tab::([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`6;dealerCnt:enlist 6i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer0[];
    (exec first dealer from .bs.tab) mustmatch `6`5`4`2;
    (exec first dealerCnt from .bs.tab) musteq 17i;
    };
  should["reduces a newly-drawn ace by 10 to avoid busting, without setting acelowD"]{
    `pubMsg mock {[x;y]};
    DC::`6`9;
    acelowD::0b;
    cardseq::`A`3`2`2`2;
    `getCard mock {c:first cardseq;cardseq::1_cardseq;c};
    .bs.tab::([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`6;dealerCnt:enlist 6i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer0[];
    (exec first dealerCnt from .bs.tab) musteq 19i;
    acelowD musteq 0b;
    };
 };

.tst.desc[".bs.dealer1"]{
  should["pays double the bet when the dealer busts and the player is 21 or under"]{
    `pubMsg mock {[x;y]};
    DCount::24;
    .bs.tab::([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K;dealerCnt:enlist 24i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 20f;
    };
  should["pays nothing when both the dealer and the player bust"]{
    `pubMsg mock {[x;y]};
    DCount::24;
    .bs.tab::([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`K`Q`5;cnt:enlist 25i;dealer:enlist`K;dealerCnt:enlist 24i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 0f;
    };
  should["pushes (returns the bet) when the counts are equal and both are 21 or under"]{
    `pubMsg mock {[x;y]};
    DCount::18;
    .bs.tab::([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`9;cnt:enlist 18i;dealer:enlist`K;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 10f;
    };
  should["pays nothing when the dealer is under 21 and beats the player"]{
    `pubMsg mock {[x;y]};
    DCount::19;
    .bs.tab::([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K;dealerCnt:enlist 19i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 0f;
    };
  should["pays nothing when the dealer is under 21 but the player busted"]{
    `pubMsg mock {[x;y]};
    DCount::18;
    .bs.tab::([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`K`Q`5;cnt:enlist 25i;dealer:enlist`K;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 0f;
    };
  should["pays double the bet for a plain win when the player beats an under-21 dealer without blackjack"]{
    `pubMsg mock {[x;y]};
    DCount::18;
    .bs.tab::([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`9`1;cnt:enlist 19i;dealer:enlist`K`3`4;dealerCnt:enlist 18i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 20f;
    };
  should["pays 1.5x plus the bet for a two-card 21 (blackjack) against an under-21 dealer"]{
    `pubMsg mock {[x;y]};
    DCount::19;
    .bs.tab::([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`A`K;cnt:enlist 21i;dealer:enlist`K`3`6;dealerCnt:enlist 19i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 25f;
    };
  should["pays nothing when the dealer has exactly 21 and the player doesn't"]{
    `pubMsg mock {[x;y]};
    DCount::21;
    .bs.tab::([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K`Q`A;dealerCnt:enlist 21i;bet:enlist 10;return:enlist 0n;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.dealer1[1f];
    (exec first return from .bs.tab) musteq 0f;
    };
 };

.tst.desc[".bs.dealer"]{
  should["skips .bs.dealer0/.bs.dealer1 when every player is already out, but still records the result"]{
    `pubMsg mock {[x;y]};
    `sendMsg mock {[x;y]};
    wwch::0b; DA::0Ni; DC::`K`5;
    dealer0Calls::0; dealer1Calls::0;
    `.bs.dealer0 mock {dealer0Calls+::1};
    `.bs.dealer1 mock {[p]dealer1Calls+::1};
    startCalls::0;
    `.bs.start mock {startCalls+::1};
    .bs.res::flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(();();();();();();();();`long$();();();();());
    .bs.tab::([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K`Q`5;dealerCnt:enlist 25i;bet:enlist 10;return:enlist 0f;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab::update out:enlist 1b,wait:enlist 0b,turn:enlist 0b from .bs.tab;
    cp::enlist[0i]!enlist`p1;
    .bs.dealer[];
    dealer0Calls musteq 0;
    dealer1Calls musteq 0;
    (exec last round from .bs.res) musteq 1;
    .bs.bd musteq 0b;
    .bs.hd musteq 1b;
    };
  should["resolves every waiting player through .bs.dealer0/.bs.dealer1 and marks them out"]{
    `pubMsg mock {[x;y]};
    `sendMsg mock {[x;y]};
    wwch::0b; DA::0Ni;
    dealer0Calls::0; dealer1Args::();
    `.bs.dealer0 mock {dealer0Calls+::1};
    `.bs.dealer1 mock {[p]dealer1Args,::p};
    startCalls::0;
    `.bs.start mock {startCalls+::1};
    .bs.res::flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(();();();();();();();();`long$();();();();());
    .bs.tab::([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:(`9`8;`K`7);cnt:17 17i;dealer:(`K`Q`5;`K`Q`5);dealerCnt:25 25i;bet:10 10;return:0 0f;profit:2#0n;split:00b;double:00b);
    .bs.tab::update out:00b,wait:11b,turn:00b from .bs.tab;
    cp::0 1i!`p1`p2;
    .bs.dealer[];
    dealer0Calls musteq 1;
    dealer1Args musteq 1 2f;
    (exec out from .bs.tab) musteq 11b;
    (exec wait from .bs.tab) musteq 00b;
    };
  should["notifies the detection algo with the round's results when DA is connected"]{
    `pubMsg mock {[x;y]};
    `sendMsg mock {[x;y]};
    wwch::0b; DA::99i; DC::`K`5;
    `.bs.start mock {};
    excFuncCalls::();
    `excFunc mock {[x;y;z] excFuncCalls,:enlist(x;z)};
    .bs.res::flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(();();();();();();();();`long$();();();();());
    .bs.tab::([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K`Q`5;dealerCnt:enlist 25i;bet:enlist 10;return:enlist 0f;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab::update out:enlist 1b,wait:enlist 0b,turn:enlist 0b from .bs.tab;
    cp::enlist[0i]!enlist`p1;
    .bs.dealer[];
    excFuncCalls mustmatch enlist(`gameover;99i);
    };
  should["always starts the next hand - the server has no round-count cap of its own"]{
    `pubMsg mock {[x;y]};
    `sendMsg mock {[x;y]};
    wwch::0b; DA::0Ni; DC::`K`5;
    startCalls::0;
    `.bs.start mock {startCalls+::1};
    .bs.res::flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(();();();();();();();();`long$();();();();());
    .bs.tab::([]round:enlist 1;player:enlist 1f;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;cnt:enlist 17i;dealer:enlist`K`Q`5;dealerCnt:enlist 25i;bet:enlist 10;return:enlist 0f;profit:enlist 0n;split:enlist 0b;double:enlist 0b);
    .bs.tab::update out:enlist 1b,wait:enlist 0b,turn:enlist 0b from .bs.tab;
    cp::enlist[0i]!enlist`p1;
    .bs.dealer[];
    startCalls musteq 1;
    };
 };
