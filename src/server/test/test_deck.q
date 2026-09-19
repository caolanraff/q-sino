system "l src/server/bin/blackjackServer.q";

.tst.desc["buildDeck"]{
  should["builds N decks worth of cards (4 of each rank per deck) when given a count"]{
    buildDeck[2];
    (count .bs.deck) musteq 104;
    (count distinct .bs.deck) musteq 13;
    (all 8 = value count each group .bs.deck) musteq 1b;
    };
  should["defaults to deckCnt decks when no count is given"]{
    buildDeck[];
    (count .bs.deck) musteq deckCnt*52;
    (all (deckCnt*4) = value count each group .bs.deck) musteq 1b;
    };
 };

.tst.desc["shuffle"]{
  should["refuses to reshuffle before the hand is done"]{
    .bs.hd::0b;
    .bs.deck::`A`K`Q;
    origDeck::`A`K`Q;
    shufflecnt::0;
    shuffle[];
    (.bs.deck~origDeck) musteq 1b;
    shufflecnt musteq 0;
    };
  should["reorders the deck without changing its composition, archives .bs.res into .bs.hist, and resets shuffle state"]{
    `excFunc mock {[x;y;z]};
    .bs.hd::1b;
    .bs.deck::100?`A`K`Q`J`10`9`8`7`6`5`4`3`2;
    origDeck::.bs.deck;
    .bs.hist::0#([]round:enlist 1);
    .bs.res::([]round:enlist 1);
    shufflecnt::0;
    DA::0Ni;
    cp::()!();
    shuffle[];
    ((asc .bs.deck)~(asc origDeck)) musteq 1b;
    (count .bs.hist) musteq 1;
    (count .bs.res) musteq 0;
    shufflecnt musteq 1;
    .bs.count musteq 0f;
    };
  should["unconditionally notifies every connected client's .mc.shuffle"]{
    excCalls::();
    `excFunc mock {[x;y;z] excCalls,:enlist(x;z)};
    .bs.hd::1b;
    .bs.deck::20?`A`K;
    .bs.hist::0#([]round:enlist 1);
    .bs.res::0#([]round:enlist 1);
    shufflecnt::0;
    DA::0Ni;
    cp::0 1i!`p1`p2;
    shuffle[];
    (asc excCalls) mustmatch asc (enlist(`.mc.shuffle;0i)),enlist(`.mc.shuffle;1i);
    };
  should["does not notify the detection algo on the very first shuffle, even when it's connected"]{
    excCalls::();
    `excFunc mock {[x;y;z] excCalls,:enlist(x;z)};
    .bs.hd::1b;
    .bs.deck::20?`A`K;
    .bs.hist::0#([]round:enlist 1);
    .bs.res::0#([]round:enlist 1);
    shufflecnt::0;
    DA::99i;
    cp::()!();
    shuffle[];
    excCalls musteq ();
    };
  should["notifies the detection algo on subsequent shuffles when it's connected"]{
    excCalls::();
    `excFunc mock {[x;y;z] excCalls,:enlist(x;z)};
    .bs.hd::1b;
    .bs.deck::20?`A`K;
    .bs.hist::0#([]round:enlist 1);
    .bs.res::0#([]round:enlist 1);
    shufflecnt::1;
    DA::99i;
    cp::()!();
    shuffle[];
    excCalls mustmatch enlist(`shuffle;99i);
    };
 };

.tst.desc["getCard"]{
  should["draws a card from the deck and removes exactly one instance of it"]{
    .bs.deck::`A`A`K`Q`Q`Q;
    origDeck::.bs.deck;
    c::getCard[];
    (c in origDeck) musteq 1b;
    (count .bs.deck) musteq (count origDeck)-1;
    (count .bs.deck where .bs.deck=c) musteq (count origDeck where origDeck=c)-1;
    (count .bs.deck where not .bs.deck=c) musteq count origDeck where not origDeck=c;
    };
 };

.tst.desc["dealCard"]{
  should["deals exactly one card to the given row's player only"]{
    `sendMsg mock {[x;y]};
    getCardCalls::0;
    `getCard mock {getCardCalls+::1;`7};
    .bs.tab::([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b);
    row::first select from .bs.tab where player=1;
    dealCard[row];
    getCardCalls musteq 1;
    (exec first cards from .bs.tab where player=1) mustmatch enlist`7;
    (exec first cards from .bs.tab where player=2) mustmatch ();
    };
 };
