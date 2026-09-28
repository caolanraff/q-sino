.tst.desc["avgPlayer3 help: ace handling"]{
  should["A,9,5 is a hittable soft 15, not a bust"]{
    .utl.load each`:src/client/lib/strategy.q`:src/client/lib/avgPlayer3.q;
    .stg.help[`A`9`5`2] musteq`H;
  };
 };

.tst.desc["avgPlayer3 .stg.getBet"]{
  before{.utl.load each`:src/client/lib/strategy.q`:src/client/lib/avgPlayer3.q};
  should["bets 10 before any hand has been played, when the pushed results are still untyped"]{
    .stg.res:flip`round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .stg.getBet[] musteq 10;
  };
  should["bets 20 after every 5th round"]{
    .stg.res:([]round:4 5;handle:5 5i;profit:10 -10f);
    .stg.getBet[] musteq 20;
  };
  should["bets 10 otherwise"]{
    .stg.res:([]round:5 6;handle:5 5i;profit:10 -10f);
    .stg.getBet[] musteq 10;
  };
 };
