.tst.desc["avgPlayer1.Help ace handling"]{
  before{system "l src/client/lib/playerCore.q";system "l src/client/lib/avgPlayer1.q"};
  should["A,9,5 is a hittable soft 15, not a bust"]{
    Help[`A`9`5`2] musteq `H;
    };
  should["still correctly hits a plain hard 12"]{
    Help[`10`2`10] musteq `H;
    };
 };
