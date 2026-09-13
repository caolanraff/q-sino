.tst.desc["playerCore.Help"]{
  before{system "l src/client/lib/playerCore.q"};
  should["A,A,9 vs dealer 6 is a made soft 21 and should Stand"]{
    Help[`A`A`9`6] musteq `S;
    };
  should["A,9,+hit A vs dealer 2 is a soft 21 and should Stand"]{
    Help[`A`9`A`2] musteq `S;
    };
  should["still correctly recommends Stand on a plain made 20"]{
    Help[`10`Q`6] musteq `S;
    };
  should["still correctly recommends Hit on a hard 12 vs a strong dealer up-card"]{
    Help[`10`2`10] musteq `H;
    };
 };
