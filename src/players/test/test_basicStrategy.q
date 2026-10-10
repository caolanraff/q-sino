.tst.desc["basicStrategy .stg.help"]{
  before{.utl.load each`:src/players/lib/strategy.q`:src/players/lib/basicStrategy.q};
  should["plays the basic strategy chart"]{
    .stg.help[`A`7`2] musteq`D;
    .stg.help[`6`5`A] musteq`D;
    .stg.help[`10`6`10] musteq`H;
    .stg.help[`10`2`2] musteq`H;
    .stg.help[`2`2`5] musteq`SP;
    .stg.help[`9`9`7] musteq`S;
  };
 };

.tst.desc["basicStrategy .stg.getBet"]{
  before{.utl.load each`:src/players/lib/strategy.q`:src/players/lib/basicStrategy.q};
  should["bets $10 whatever the count"]{
    .stg.trueCount:-5f;
    .stg.getBet[] musteq 10;
    .stg.trueCount:8f;
    .stg.getBet[] musteq 10;
  };
 };

.tst.desc["basicStrategy .stg.insureAmount"]{
  should["never insures, whatever the count"]{
    .utl.load each`:src/players/lib/strategy.q`:src/players/lib/basicStrategy.q;
    .stg.mh:7i;
    .stg.tab:([]handle:enlist 7i;cards:enlist`A`K;bet:10);
    .stg.trueCount:10f;
    .stg.insureAmount[] musteq 0f;
  };
 };
