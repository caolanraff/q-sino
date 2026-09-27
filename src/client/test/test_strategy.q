.tst.desc["strategy Help"]{
  before{system "l src/client/lib/strategy.q"};
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

.tst.desc[".stg.decide"]{
  before{system "l src/client/lib/strategy.q"};
  should["passes Help's split through while the player is under the hand cap"]{
    .stg.decide[`8`8`10;3] musteq `SP;
    };
  should["plays a pair as its hard total once the player is at the hand cap"]{
    .stg.decide[`8`8`10;4] musteq `H;   / hard 16 vs 10
    .stg.decide[`10`10`6;4] musteq `S;  / hard 20 vs 6
    };
  should["leaves non-split decisions alone at the hand cap"]{
    .stg.decide[`5`6`6;4] musteq `D;
    };
 };

.tst.desc[".stg.Count"]{
  before{system "l src/client/lib/strategy.q"};
  should["counts the dealer's cards once per round, not once per player row"]{
    .stg.res:([]round:1 1;cards:(`K`5;`2`3`4);dealer:(`10`8;`10`8));
    .stg.tab:([]round:0N 0N;cards:(();());dealer:``);
    startCards::312;
    .stg.Count[];
    theCount musteq 2%(312-7)%52;  / basic: K5 234 = +3, dealer 10 8 once = -1; 7 cards seen
    };
 };

.tst.desc["strategy Help - 6-deck chart, dealer hits soft 17"]{
  before{system "l src/client/lib/strategy.q"};
  should["doubles the hands that change when the dealer hits soft 17"]{
    Help[`A`7`2] musteq `D;  / soft 18 vs 2
    Help[`A`8`6] musteq `D;  / soft 19 vs 6
    Help[`6`5`A] musteq `D;  / 11 vs ace
    };
  should["stands instead on a soft 18 or 19 that can no longer double"]{
    Help[`A`3`4`4] musteq `S;  / 3-card soft 18 vs 4
    Help[`A`5`3`6] musteq `S;  / 3-card soft 19 vs 6
    };
  should["still hits a soft 17 that can no longer double"]{
    Help[`A`2`4`5] musteq `H;  / 3-card soft 17 vs 5
    };
  should["hits soft 18 against an ace"]{
    Help[`A`7`A] musteq `H;
    };
  should["uses the 6-deck plays, not single-deck ones"]{
    Help[`5`3`6] musteq `H;    / hard 8 vs 6: no double
    Help[`5`4`2] musteq `H;    / hard 9 vs 2: no double
    Help[`A`2`4] musteq `H;    / soft 13 vs 4: no double
    Help[`A`6`2] musteq `H;    / soft 17 vs 2: no double
    Help[`7`7`10] musteq `H;   / 7,7 vs 10: hit, not stand
    Help[`7`7`8] musteq `H;    / 7,7 vs 8: hit, not split
    Help[`4`4`4] musteq `H;    / 4,4 vs 4: hit, not split
    };
 };

.tst.desc[".stg.recv"]{
  before{system "l src/client/lib/strategy.q"};
  should["takes the table, results and this client's handle from the state the server pushed"]{
    t:([]round:enlist 2;cards:enlist`K`5;dealer:enlist`9);
    r:([]round:enlist 1;cards:enlist`9`8;dealer:enlist`10`7);
    .stg.recv[`tab`res`me!(t;r;7i)];
    .stg.tab mustmatch t;
    .stg.res mustmatch r;
    .stg.mh musteq 7i;
    };
 };

.tst.desc[".stg.insureAmount"]{
  before{system "l src/client/lib/strategy.q"};
  should["never insures by default"]{
    .stg.tab:([]handle:enlist 7i;bet:enlist 20); .stg.mh:7i;
    theCount::10f;
    .stg.insureAmount[] musteq 0f;
    };
  should["insures half the bet once the true count reaches insureAt"]{
    .stg.tab:([]handle:6 7i;bet:40 20); .stg.mh:7i;
    insureAt::3;
    theCount::3f;
    .stg.insureAmount[] musteq 10f;
    theCount::2.9;
    .stg.insureAmount[] musteq 0f;
    };
 };

.tst.desc["insureAt per strategy"]{
  should["is 3 for the Hi-Lo counters and never for the others"]{
    system "l src/client/lib/basicCardCounter.q"; insureAt musteq 3;
    system "l src/client/lib/smallSpreadBasicCardCounter.q"; insureAt musteq 3;
    system "l src/client/lib/omegaCardCounter.q"; insureAt musteq 0w;
    system "l src/client/lib/perfectCardCounter.q"; insureAt musteq 0w;
    system "l src/client/lib/avgPlayer1.q"; insureAt musteq 0w;
    };
 };
