.tst.desc["avgPlayer3 .stg.help"]{
  before{.utl.load each`:src/players/lib/strategy.q`:src/players/lib/avgPlayer3.q};
  should["never doubles a soft hand"]{
    .stg.help[`A`6`4] musteq`H;
    .stg.help[`A`7`3] musteq`S;
    .stg.help[`A`8`6] musteq`S;
  };
  should["never doubles 9, and hits 11 against an ace"]{
    .stg.help[`5`4`4] musteq`H;
    .stg.help[`6`5`A] musteq`H;
  };
  should["sticks on 16 against a 10"]{
    .stg.help[`10`6`10] musteq`S;
    .stg.help[`9`7`K] musteq`S;
  };
  should["plays 2s, 3s, 4s and 6s by their total instead of splitting"]{
    .stg.help[`2`2`5] musteq`H;
    .stg.help[`3`3`4] musteq`H;
    .stg.help[`4`4`5] musteq`H;
    .stg.help[`6`6`4] musteq`S;
    .stg.help[`6`6`8] musteq`H;
  };
  should["otherwise plays basic strategy"]{
    .stg.help[`A`A`10] musteq`SP;
    .stg.help[`8`8`10] musteq`SP;
    .stg.help[`9`9`6] musteq`SP;
    .stg.help[`6`5`6] musteq`D;
    .stg.help[`10`2`2] musteq`H;
    .stg.help[`10`6`9] musteq`H;
    .stg.help[`A`7`9] musteq`H;
  };
  should["leaves the basic strategy chart alone for the next strategy loaded"]{
    .utl.load`:src/players/lib/strategy.q;
    .stg.help[`A`6`4] musteq`D;
    .stg.help[`10`6`10] musteq`H;
    .stg.help[`2`2`5] musteq`SP;
  };
 };

.tst.desc["avgPlayer3 .stg.insureAmount"]{
  before{
    .utl.load each`:src/players/lib/strategy.q`:src/players/lib/avgPlayer3.q;
    .stg.mh:7i;
  };
  should["takes even money on a blackjack"]{
    .stg.tab:([]handle:7 8i;cards:(`A`K;`9`9);bet:20 40);
    .stg.insureAmount[] musteq 10f;
  };
  should["doesn't insure any other hand, whatever the count"]{
    .stg.tab:([]handle:7 8i;cards:(`9`K;`A`K);bet:20 40);
    .stg.trueCount:10f;
    .stg.insureAmount[] musteq 0f;
  };
 };

.tst.desc["avgPlayer3 .stg.getBet"]{
  before{
    .utl.load each`:src/players/lib/strategy.q`:src/players/lib/avgPlayer3.q;
    .stg.lastChips:1000f;
  };
  should["bets $10 on its first hand"]{
    .stg.lastChips:0n;
    .stg.lastBet:0;
    .stg.chips:1000f;
    .stg.getBet[] musteq 10;
  };
  should["bets $10 more after a loss"]{
    .stg.lastBet:20;
    .stg.chips:980f;
    .stg.getBet[] musteq 30;
  };
  should["bets no more than $50"]{
    .stg.lastBet:50;
    .stg.chips:950f;
    .stg.getBet[] musteq 50;
  };
  should["goes back to $10 after a win"]{
    .stg.lastBet:40;
    .stg.chips:1040f;
    .stg.getBet[] musteq 10;
  };
  should["bets the same again after a push"]{
    .stg.lastBet:30;
    .stg.chips:1000f;
    .stg.getBet[] musteq 30;
  };
 };
