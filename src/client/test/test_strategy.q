.tst.desc[".stg.help"]{
  before{.utl.load`:src/client/lib/strategy.q};
  should["A,A,9 vs dealer 6 is a made soft 21 and should Stand"]{
    .stg.help[`A`A`9`6] musteq`S;
  };
  should["A,9,+hit A vs dealer 2 is a soft 21 and should Stand"]{
    .stg.help[`A`9`A`2] musteq`S;
  };
  should["still correctly recommends Stand on a plain made 20"]{
    .stg.help[`10`Q`6] musteq`S;
  };
  should["still correctly recommends Hit on a hard 12 vs a strong dealer up-card"]{
    .stg.help[`10`2`10] musteq`H;
  };
 };

.tst.desc[".stg.decide"]{
  before{.utl.load`:src/client/lib/strategy.q;.stg.rules:`maxSplitHands`deckCnt!4 6};
  should["passes .stg.help's split through while the player is under the hand cap"]{
    .stg.decide[`8`8`10;3] musteq`SP;
  };
  should["plays a pair as its hard total once the player is at the hand cap"]{
    .stg.decide[`8`8`10;4] musteq`H;                                                               / hard 16 vs 10
    .stg.decide[`10`10`6;4] musteq`S;                                                              / hard 20 vs 6
  };
  should["leaves non-split decisions alone at the hand cap"]{
    .stg.decide[`5`6`6;4] musteq`D;
  };
 };

.tst.desc[".stg.count"]{
  before{.utl.load`:src/client/lib/strategy.q};
  should["counts the dealer's cards once per round, not once per player row"]{
    .stg.res:([]round:1 1;cards:(`K`5;`2`3`4);dealer:(`10`8;`10`8));
    .stg.tab:([]round:0N 0N;cards:(();());dealer:``);
    .stg.rules:`maxSplitHands`deckCnt!4 6;
    .stg.count[];
    .stg.trueCount musteq 2%(312-7)%52;                                                            / basic: K5 234 = +3, dealer 10 8 once = -1; 7 cards seen
  };
 };

.tst.desc[".stg.help - 6-deck chart, dealer hits soft 17"]{
  before{.utl.load`:src/client/lib/strategy.q};
  should["doubles the hands that change when the dealer hits soft 17"]{
    .stg.help[`A`7`2] musteq`D;                                                                    / soft 18 vs 2
    .stg.help[`A`8`6] musteq`D;                                                                    / soft 19 vs 6
    .stg.help[`6`5`A] musteq`D;                                                                    / 11 vs ace
  };
  should["stands instead on a soft 18 or 19 that can no longer double"]{
    .stg.help[`A`3`4`4] musteq`S;                                                                  / 3-card soft 18 vs 4
    .stg.help[`A`5`3`6] musteq`S;                                                                  / 3-card soft 19 vs 6
  };
  should["still hits a soft 17 that can no longer double"]{
    .stg.help[`A`2`4`5] musteq`H;                                                                  / 3-card soft 17 vs 5
  };
  should["hits soft 18 against an ace"]{
    .stg.help[`A`7`A] musteq`H;
  };
  should["uses the 6-deck plays, not single-deck ones"]{
    .stg.help[`5`3`6] musteq`H;                                                                    / hard 8 vs 6: no double
    .stg.help[`5`4`2] musteq`H;                                                                    / hard 9 vs 2: no double
    .stg.help[`A`2`4] musteq`H;                                                                    / soft 13 vs 4: no double
    .stg.help[`A`6`2] musteq`H;                                                                    / soft 17 vs 2: no double
    .stg.help[`7`7`10] musteq`H;                                                                   / 7,7 vs 10: hit, not stand
    .stg.help[`7`7`8] musteq`H;                                                                    / 7,7 vs 8: hit, not split
    .stg.help[`4`4`4] musteq`H;                                                                    / 4,4 vs 4: hit, not split
  };
 };

.tst.desc[".stg.recv"]{
  before{.utl.load`:src/client/lib/strategy.q};
  should["takes the table, results, this client's handle and the table rules from the state the server pushed"]{
    t:([]round:enlist 2;cards:enlist`K`5;dealer:enlist`9);
    r:([]round:enlist 1;cards:enlist`9`8;dealer:enlist`10`7);
    .stg.recv[`tab`res`me`rules!(t;r;7i;`maxSplitHands`deckCnt!4 6)];
    .stg.tab mustmatch t;
    .stg.res mustmatch r;
    .stg.mh musteq 7i;
    .stg.rules mustmatch`maxSplitHands`deckCnt!4 6;
  };
  should["uses the pushed split cap and deck count, not fixed ones"]{
    .stg.recv[`tab`res`me`rules!(([]round:0#0;cards:();dealer:0#`);([]round:enlist 1;cards:enlist`K`5;dealer:enlist`10`8);7i;`maxSplitHands`deckCnt!2 2)];
    .stg.decide[`8`8`10;2] musteq`H;
    .stg.count[];
    .stg.trueCount musteq -1%(104-4)%52;
  };
 };

.tst.desc[".stg.insureAmount"]{
  before{.utl.load`:src/client/lib/strategy.q};
  should["never insures by default"]{
    .stg.tab:([]handle:enlist 7i;bet:enlist 20);
    .stg.mh:7i;
    .stg.trueCount:10f;
    .stg.insureAmount[] musteq 0f;
  };
  should["insures half the bet once the true count reaches .stg.insureAt"]{
    .stg.tab:([]handle:6 7i;bet:40 20);
    .stg.mh:7i;
    .stg.insureAt:3;
    .stg.trueCount:3f;
    .stg.insureAmount[] musteq 10f;
    .stg.trueCount:2.9;
    .stg.insureAmount[] musteq 0f;
  };
 };

.tst.desc[".stg.insureAt per strategy"]{
  should["is 3 for the Hi-Lo counters and never for the others"]{
    .utl.load each`:src/client/lib/strategy.q`:src/client/lib/basicCardCounter.q;
    .stg.insureAt musteq 3;
    .utl.load each`:src/client/lib/strategy.q`:src/client/lib/smallSpreadBasicCardCounter.q;
    .stg.insureAt musteq 3;
    .utl.load each`:src/client/lib/strategy.q`:src/client/lib/omegaCardCounter.q;
    .stg.insureAt musteq 0w;
    .utl.load each`:src/client/lib/strategy.q`:src/client/lib/perfectCardCounter.q;
    .stg.insureAt musteq 0w;
    .utl.load each`:src/client/lib/strategy.q`:src/client/lib/avgPlayer1.q;
    .stg.insureAt musteq 0w;
  };
 };
