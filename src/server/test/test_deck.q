system "l src/server/bin/blackjackServer.q";

.tst.desc[".bs.buildDeck"]{
  should["builds N decks worth of cards (4 of each rank per deck) when given a count"]{
    .bs.buildDeck[2];
    (count .bs.deck) musteq 104;
    (count distinct .bs.deck) musteq 13;
    (all 8 = value count each group .bs.deck) musteq 1b;
    };
  should["defaults to .bs.deckCnt decks when no count is given"]{
    .bs.buildDeck[];
    (count .bs.deck) musteq .bs.deckCnt*52;
    (all (.bs.deckCnt*4) = value count each group .bs.deck) musteq 1b;
    };
 };

.tst.desc[".bs.shuffle"]{
  should["refuses to reshuffle before the hand is done"]{
    .bs.hd:0b;
    .bs.deck:`A`K`Q;
    origDeck::`A`K`Q;
    .bs.shuffleCnt:0;
    .bs.shuffle[];
    (.bs.deck~origDeck) musteq 1b;
    .bs.shuffleCnt musteq 0;
    };
  should["reorders the deck without changing its composition, archives .bs.res into .bs.hist, and resets shuffle state"]{
    `.bs.excFunc mock {[x;y;z]};
    .bs.hd:1b;
    .bs.deck:100?`A`K`Q`J`10`9`8`7`6`5`4`3`2;
    origDeck::.bs.deck;
    .bs.hist:0#([]round:enlist 1);
    .bs.res:([]round:enlist 1);
    .bs.shuffleCnt:0;
    .bs.da:0Ni;
    .bs.cp:()!();
    .bs.shuffle[];
    ((asc .bs.deck)~(asc origDeck)) musteq 1b;
    (count .bs.hist) musteq 1;
    (count .bs.res) musteq 0;
    .bs.shuffleCnt musteq 1;
    .bs.count musteq 0f;
    };
  should["unconditionally notifies every connected client's .mc.shuffle"]{
    excCalls::();
    `.bs.excFunc mock {[x;y;z] excCalls,:enlist(x;z)};
    .bs.hd:1b;
    .bs.deck:20?`A`K;
    .bs.hist:0#([]round:enlist 1);
    .bs.res:0#([]round:enlist 1);
    .bs.shuffleCnt:0;
    .bs.da:0Ni;
    .bs.cp:0 1i!`p1`p2;
    .bs.shuffle[];
    (asc excCalls) mustmatch asc (enlist(`.mc.shuffle;0i)),enlist(`.mc.shuffle;1i);
    };
  should["does not notify the detection algo on the very first shuffle, even when it's connected"]{
    excCalls::();
    `.bs.excFunc mock {[x;y;z] excCalls,:enlist(x;z)};
    .bs.hd:1b;
    .bs.deck:20?`A`K;
    .bs.hist:0#([]round:enlist 1);
    .bs.res:0#([]round:enlist 1);
    .bs.shuffleCnt:0;
    .bs.da:99i;
    .bs.cp:()!();
    .bs.shuffle[];
    excCalls musteq ();
    };
  should["notifies the detection algo on subsequent shuffles when it's connected"]{
    excCalls::();
    `.bs.excFunc mock {[x;y;z] excCalls,:enlist(x;z)};
    .bs.hd:1b;
    .bs.deck:20?`A`K;
    .bs.hist:0#([]round:enlist 1);
    .bs.res:0#([]round:enlist 1);
    .bs.shuffleCnt:1;
    .bs.da:99i;
    .bs.cp:()!();
    .bs.shuffle[];
    excCalls mustmatch enlist(`.da.shuffle;99i);
    };
 };

.tst.desc["getCard"]{
  should["draws a card from the deck and removes exactly one instance of it"]{
    .bs.deck:`A`A`K`Q`Q`Q;
    origDeck::.bs.deck;
    c::.bs.getCard[];
    (c in origDeck) musteq 1b;
    (count .bs.deck) musteq (count origDeck)-1;
    (count .bs.deck where .bs.deck=c) musteq (count origDeck where origDeck=c)-1;
    (count .bs.deck where not .bs.deck=c) musteq count origDeck where not origDeck=c;
    };
 };

.tst.desc["dealCard"]{
  should["deals exactly one card to the given row's player only"]{
    `.bs.sendMsg mock {[x;y]};
    getCardCalls::0;
    `.bs.getCard mock {getCardCalls+::1;`7};
    .bs.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b);
    row::first select from .bs.tab where player=1;
    .bs.dealCard[row];
    getCardCalls musteq 1;
    (exec first cards from .bs.tab where player=1) mustmatch enlist`7;
    (exec first cards from .bs.tab where player=2) mustmatch ();
    };
 };

.tst.desc[".bs.handCount"]{
  should["totals a hand with no aces at face value"]{
    (.bs.handCount `K`7) musteq 17i;
    (.bs.handCount `K`7`9) musteq 26i;
    };
  should["counts an ace as 11 when that doesn't bust the hand"]{
    (.bs.handCount `A`6) musteq 17i;
    (.bs.handCount `3`2`A) musteq 16i;
    };
  should["drops an ace to 1 once a later card would otherwise bust the hand, wherever the ace was dealt"]{
    (.bs.handCount `A`5`10) musteq 16i;
    (.bs.handCount `3`2`A`10) musteq 16i;
    };
  should["only drops as many aces to 1 as needed"]{
    (.bs.handCount `A`A) musteq 12i;
    (.bs.handCount `A`5`A`10) musteq 17i;
    (.bs.handCount `A`A`A`A`7) musteq 21i;
    };
 };

.tst.desc[".bs.isBJ"]{
  should["is true only for a two-card 21"]{
    (.bs.isBJ `A`K) musteq 1b;
    (.bs.isBJ `10`A) musteq 1b;
    (.bs.isBJ `7`7`7) musteq 0b;
    (.bs.isBJ `A`9) musteq 0b;
    };
 };

.tst.desc[".bs.isSoft"]{
  should["is true while an ace is still counted as 11"]{
    (.bs.isSoft `A`6) musteq 1b;
    (.bs.isSoft `A`A`5) musteq 1b;
    };
  should["is false once every ace has dropped to 1, or with no ace at all"]{
    (.bs.isSoft `A`6`10) musteq 0b;
    (.bs.isSoft `A`5`A`10) musteq 0b;
    (.bs.isSoft `K`7) musteq 0b;
    };
 };
