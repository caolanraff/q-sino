system "l src/client/lib/playerCore.q";

.tst.desc["avgPlayer2.Help ace handling"]{
  should["A,9,5 is a hittable soft 15, not a bust"]{
    system "l src/client/lib/avgPlayer2.q";
    Help[`A`9`5`2] musteq `H;
    };
 };
