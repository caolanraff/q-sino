.tst.desc["avgPlayer3 .stg.help"]{
  before{.utl.load each`:src/players/lib/strategy.q`:src/players/lib/avgPlayer3.q};
  should["splits aces and 8s, and plays other pairs by their total"]{
    .stg.help[`A`A`6] musteq`SP;
    .stg.help[`8`8`10] musteq`SP;
    .stg.help[`9`9`6] musteq`S;
    .stg.help[`2`2`6] musteq`H;
  };
  should["doubles a two-card 10 or 11 unless the dealer shows a 10 or an ace"]{
    .stg.help[`5`6`9] musteq`D;
    .stg.help[`6`4`2] musteq`D;
    .stg.help[`6`4`K] musteq`H;
    .stg.help[`6`5`A] musteq`H;
    .stg.help[`2`3`5`6] musteq`H;
  };
  should["sticks on 12 to 16 against 2 to 6, and hits it against 7 or more"]{
    .stg.help[`10`2`2] musteq`S;
    .stg.help[`10`6`6] musteq`S;
    .stg.help[`10`6`7] musteq`H;
    .stg.help[`10`2`A] musteq`H;
  };
  should["hits a soft hand to 17 and sticks from 18, never doubling"]{
    .stg.help[`A`6`5] musteq`H;
    .stg.help[`A`7`3] musteq`S;
    .stg.help[`A`7`9] musteq`S;
  };
  should["counts an ace as 1 where 11 would bust"]{
    .stg.help[`A`9`5`2] musteq`S;
    .stg.help[`A`9`5`7] musteq`H;
  };
  should["sticks on 16 against a 10, but not on 15 or against a 9"]{
    .stg.help[`10`6`K] musteq`S;
    .stg.help[`9`7`10] musteq`S;
    .stg.help[`10`5`10] musteq`H;
    .stg.help[`10`6`9] musteq`H;
  };
  should["sticks on 17 or more"]{
    .stg.help[`10`7`A] musteq`S;
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
