.tst.desc["avgPlayer2 .stg.help"]{
  before{.utl.load each`:src/players/lib/strategy.q`:src/players/lib/avgPlayer2.q};
  should["splits only aces, playing other pairs by their total"]{
    .stg.help[`A`A`6] musteq`SP;
    .stg.help[`8`8`10] musteq`S;
    .stg.help[`2`2`6] musteq`H;
  };
  should["sticks on any hard 12 or more, whatever the dealer shows"]{
    .stg.help[`10`2`A] musteq`S;
    .stg.help[`10`6`7] musteq`S;
    .stg.help[`A`9`5`10] musteq`S;
    .stg.help[`5`4`3] musteq`H;
  };
  should["doubles only a two-card 11"]{
    .stg.help[`6`5`A] musteq`D;
    .stg.help[`6`4`6] musteq`H;
    .stg.help[`5`4`5] musteq`H;
    .stg.help[`2`3`6`6] musteq`H;
  };
  should["hits a soft hand to 16 and sticks from 17, never doubling"]{
    .stg.help[`A`5`6] musteq`H;
    .stg.help[`A`6`10] musteq`S;
    .stg.help[`A`6`4] musteq`S;
  };
 };

.tst.desc["avgPlayer2 .stg.insureAmount"]{
  before{
    .utl.load each`:src/players/lib/strategy.q`:src/players/lib/avgPlayer2.q;
    .stg.mh:7i;
  };
  should["insures half the bet on a 20 or a blackjack"]{
    .stg.tab:([]handle:7 8i;cards:(`10`K;`9`9);bet:20 40);
    .stg.insureAmount[] musteq 10f;
    .stg.tab:([]handle:7 8i;cards:(`A`K;`9`9);bet:20 40);
    .stg.insureAmount[] musteq 10f;
  };
  should["doesn't insure anything less, whatever the count"]{
    .stg.tab:([]handle:7 8i;cards:(`10`9;`A`K);bet:20 40);
    .stg.trueCount:10f;
    .stg.insureAmount[] musteq 0f;
  };
 };

.tst.desc["avgPlayer2 .stg.getBet"]{
  before{
    .utl.load each`:src/players/lib/strategy.q`:src/players/lib/avgPlayer2.q;
    .stg.lastChips:1000f;
  };
  should["bets $10 on its first hand"]{
    .stg.lastChips:0n;
    .stg.lastBet:0;
    .stg.chips:1000f;
    .stg.getBet[] musteq 10;
  };
  should["adds a win to its last bet"]{
    .stg.lastBet:10;
    .stg.chips:1015f;
    .stg.wins:0;
    .stg.getBet[] musteq 25;
    .stg.wins musteq 1;
  };
  should["pockets the third win in a row and goes back to $10"]{
    .stg.lastBet:40;
    .stg.chips:1040f;
    .stg.wins:2;
    .stg.getBet[] musteq 10;
    .stg.wins musteq 0;
  };
  should["goes back to $10 after a loss"]{
    .stg.lastBet:20;
    .stg.chips:980f;
    .stg.wins:1;
    .stg.getBet[] musteq 10;
    .stg.wins musteq 0;
  };
  should["bets the same again after a push"]{
    .stg.lastBet:20;
    .stg.chips:1000f;
    .stg.wins:1;
    .stg.getBet[] musteq 20;
    .stg.wins musteq 1;
  };
 };
