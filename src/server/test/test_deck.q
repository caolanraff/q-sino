.utl.load`:src/server/bin/blackjack.q;
.utl.load each .bjk.libs;

.tst.desc[".bjk.buildDeck"]{
  should["builds N decks worth of cards (4 of each rank per deck) when given a count"]{
    .bjk.buildDeck[2];
    count[.bjk.deck] musteq 104;
    count[distinct .bjk.deck] musteq 13;
    all[8=value count each group .bjk.deck] musteq 1b;
  };
  should["defaults to the table's deckCnt decks when no count is given"]{
    .bjk.buildDeck[];
    count[.bjk.deck] musteq 52*.bjk.rules`deckCnt;
    all[(4*.bjk.rules`deckCnt)=value count each group .bjk.deck] musteq 1b;
  };
 };

.tst.desc[".bjk.shuffle"]{
  should["refuses to reshuffle before the hand is done"]{
    .bjk.hd:0b;
    .bjk.deck:`A`K`Q;
    .bjk.shuffleCnt:0;
    .bjk.shuffle[];
    .bjk.deck mustmatch`A`K`Q;
    .bjk.shuffleCnt musteq 0;
  };
  should["reorders the deck without changing its composition, archives .bjk.res into .bjk.hist, and resets shuffle state"]{
    `.bjk.excFunc mock {[x;y;z]};
    .bjk.hd:1b;
    .bjk.deck:100?`A`K`Q`J`10`9`8`7`6`5`4`3`2;
    .tst.origDeck:.bjk.deck;
    .bjk.hist:0#([]round:enlist 1);
    .bjk.res:([]round:enlist 1);
    .bjk.shuffleCnt:0;
    .bjk.pit:0Ni;
    .bjk.cp:()!();
    .bjk.shuffle[];
    asc[.bjk.deck] mustmatch asc .tst.origDeck;
    count[.bjk.hist] musteq 1;
    count[.bjk.res] musteq 0;
    .bjk.shuffleCnt musteq 1;
  };
  should["unconditionally notifies every connected client's .plr.shuffle"]{
    .tst.excCalls:();
    `.bjk.excFunc mock {.tst.excCalls,:enlist(x;z)};
    .bjk.hd:1b;
    .bjk.deck:20?`A`K;
    .bjk.hist:0#([]round:enlist 1);
    .bjk.res:0#([]round:enlist 1);
    .bjk.shuffleCnt:0;
    .bjk.pit:0Ni;
    .bjk.cp:0 1i!`p1`p2;
    .bjk.shuffle[];
    asc[.tst.excCalls] mustmatch asc((`.plr.shuffle;0i);(`.plr.shuffle;1i));
  };
  should["does not notify the detection algo on the very first shuffle, even when it's connected"]{
    .tst.excCalls:();
    `.bjk.excFunc mock {.tst.excCalls,:enlist(x;z)};
    .bjk.hd:1b;
    .bjk.deck:20?`A`K;
    .bjk.hist:0#([]round:enlist 1);
    .bjk.res:0#([]round:enlist 1);
    .bjk.shuffleCnt:0;
    .bjk.pit:99i;
    .bjk.cp:()!();
    .bjk.shuffle[];
    .tst.excCalls mustmatch();
  };
  should["notifies the detection algo on subsequent shuffles when it's connected"]{
    .tst.excCalls:();
    `.bjk.excFunc mock {.tst.excCalls,:enlist(x;z)};
    .bjk.hd:1b;
    .bjk.deck:20?`A`K;
    .bjk.hist:0#([]round:enlist 1);
    .bjk.res:0#([]round:enlist 1);
    .bjk.shuffleCnt:1;
    .bjk.pit:99i;
    .bjk.cp:()!();
    .bjk.shuffle[];
    .tst.excCalls mustmatch enlist(`.pit.shuffle;99i);
  };
 };

.tst.desc[".bjk.getCard"]{
  should["draws a card from the deck and removes exactly one instance of it"]{
    .bjk.deck:`A`A`K`Q`Q`Q;
    .tst.origDeck:.bjk.deck;
    .tst.c:.bjk.getCard[];
    (.tst.c in .tst.origDeck) musteq 1b;
    count[.bjk.deck] musteq -1+count .tst.origDeck;
    sum[.bjk.deck=.tst.c] musteq -1+sum .tst.origDeck=.tst.c;
    sum[.bjk.deck<>.tst.c] musteq sum .tst.origDeck<>.tst.c;
  };
 };

.tst.desc[".bjk.dealCard"]{
  should["deals exactly one card to the given row's player only"]{
    `.bjk.sendMsg mock {[x;y]};
    .tst.getCardCalls:0;
    `.bjk.getCard mock {.tst.getCardCalls+:1;`7};
    .bjk.tab:([]round:1 1;player:1 2f;name:`p1`p2;handle:0 1i;cards:2#enlist();cnt:2#0Ni;dealer:2#`;dealerCnt:2#0Ni;bet:10 10;return:2#0n;profit:2#0n;split:00b;double:00b);
    .bjk.dealCard first select from .bjk.tab where player=1;
    .tst.getCardCalls musteq 1;
    (exec first cards from .bjk.tab where player=1) mustmatch enlist`7;
    (exec first cards from .bjk.tab where player=2) mustmatch();
  };
 };

.tst.desc[".bjk.handCount"]{
  should["totals a hand with no aces at face value"]{
    .bjk.handCount[`K`7] musteq 17i;
    .bjk.handCount[`K`7`9] musteq 26i;
  };
  should["counts an ace as 11 when that doesn't bust the hand"]{
    .bjk.handCount[`A`6] musteq 17i;
    .bjk.handCount[`3`2`A] musteq 16i;
  };
  should["drops an ace to 1 once a later card would otherwise bust the hand, wherever the ace was dealt"]{
    .bjk.handCount[`A`5`10] musteq 16i;
    .bjk.handCount[`3`2`A`10] musteq 16i;
  };
  should["only drops as many aces to 1 as needed"]{
    .bjk.handCount[`A`A] musteq 12i;
    .bjk.handCount[`A`5`A`10] musteq 17i;
    .bjk.handCount[`A`A`A`A`7] musteq 21i;
  };
 };

.tst.desc[".bjk.isBJ"]{
  should["is true only for a two-card 21"]{
    .bjk.isBJ[`A`K] musteq 1b;
    .bjk.isBJ[`10`A] musteq 1b;
    .bjk.isBJ[`7`7`7] musteq 0b;
    .bjk.isBJ[`A`9] musteq 0b;
  };
 };

.tst.desc[".bjk.isSoft"]{
  should["is true while an ace is still counted as 11"]{
    .bjk.isSoft[`A`6] musteq 1b;
    .bjk.isSoft[`A`A`5] musteq 1b;
  };
  should["is false once every ace has dropped to 1, or with no ace at all"]{
    .bjk.isSoft[`A`6`10] musteq 0b;
    .bjk.isSoft[`A`5`A`10] musteq 0b;
    .bjk.isSoft[`K`7] musteq 0b;
  };
 };

.tst.desc[".bjk.showHand"]{
  should["shows the cards and the count, marking a soft count"]{
    .bjk.showHand[`3`5] mustmatch "3,5 (8)";
    .bjk.showHand[`A`6] mustmatch "A,6 (soft 17)";
    .bjk.showHand[`A`6`K] mustmatch "A,6,K (17)";
  };
 };
