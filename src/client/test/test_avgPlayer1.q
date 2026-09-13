system "l src/client/lib/playerCore.q";

.tst.desc["avgPlayer1.Help ace handling"]{
  should["A,9,5 is a hittable soft 15, not a bust"]{
    system "l src/client/lib/avgPlayer1.q";
    Help[`A`9`5`2] musteq `H;
    };
  should["still correctly hits a plain hard 12"]{
    system "l src/client/lib/avgPlayer1.q";
    Help[`10`2`10] musteq `H;
    };
 };
