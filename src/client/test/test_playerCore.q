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

.tst.desc[".mc.decide"]{
  before{system "l src/client/lib/playerCore.q"};
  should["passes Help's split through while the player is under the hand cap"]{
    .mc.decide[`8`8`10;3] musteq `SP;
    };
  should["plays a pair as its hard total once the player is at the hand cap"]{
    .mc.decide[`8`8`10;4] musteq `H;   / hard 16 vs 10
    .mc.decide[`10`10`6;4] musteq `S;  / hard 20 vs 6
    };
  should["leaves non-split decisions alone at the hand cap"]{
    .mc.decide[`5`6`6;4] musteq `D;
    };
 };

.tst.desc[".mc.Count"]{
  before{system "l src/client/lib/playerCore.q"};
  should["counts the dealer's cards once per round, not once per player row"]{
    `.mc.getRes mock {.mc.res::([]round:1 1;cards:(`K`5;`2`3`4);dealer:(`10`8;`10`8))};
    `.mc.getTab mock {.mc.tab::([]round:0N 0N;cards:(();());dealer:``)};
    startCards::312;
    .mc.Count[];
    theCount musteq 2%(312-7)%52;  / basic: K5 234 = +3, dealer 10 8 once = -1; 7 cards seen
    };
 };
