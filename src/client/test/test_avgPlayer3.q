system "l src/client/lib/playerCore.q";

.tst.desc["avgPlayer3.Help ace handling"]{
  should["A,9,5 is a hittable soft 15, not a bust"]{
    system "l src/client/lib/avgPlayer3.q";
    Help[`A`9`5`2] musteq `H;
    };
 };
