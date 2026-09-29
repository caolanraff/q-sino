.tst.desc["avgPlayer1 help: ace handling"]{
  before{.utl.load each`:src/client/lib/strategy.q`:src/client/lib/avgPlayer1.q};
  should["A,9,5 is a hittable soft 15, not a bust"]{
    .stg.help[`A`9`5`2] musteq`H;
  };
  should["still correctly hits a plain hard 12"]{
    .stg.help[`10`2`10] musteq`H;
  };
 };
