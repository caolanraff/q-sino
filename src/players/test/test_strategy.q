.tst.desc[".stg.help"]{
  before{.utl.load`:src/players/lib/strategy.q};
  should["A,A,9 vs dealer 6 is a made soft 21 and should stick"]{
    .stg.help[`A`A`9`6] musteq`S;
  };
  should["A,9,+hit A vs dealer 2 is a soft 21 and should stick"]{
    .stg.help[`A`9`A`2] musteq`S;
  };
  should["still correctly recommends stick on a plain made 20"]{
    .stg.help[`10`Q`6] musteq`S;
  };
  should["still correctly recommends Hit on a hard 12 vs a strong dealer up-card"]{
    .stg.help[`10`2`10] musteq`H;
  };
 };

.tst.desc[".stg.decide"]{
  before{.utl.load`:src/players/lib/strategy.q;.stg.rules:`maxSplitHands`deckCnt!4 6};
  should["passes .stg.help's split through while the player is under the hand cap"]{
    .stg.decide[`8`8`10;3;1b] musteq`SP;
  };
  should["plays a pair as its hard total once the player is at the hand cap"]{
    .stg.decide[`8`8`10;4;1b] musteq`H;                                                               / hard 16 vs 10
    .stg.decide[`10`10`6;4;1b] musteq`S;                                                              / hard 20 vs 6
  };
  should["leaves non-split decisions alone at the hand cap"]{
    .stg.decide[`5`6`6;4;1b] musteq`D;
  };
 };

.tst.desc[".stg.count"]{
  before{.utl.load`:src/players/lib/strategy.q};
  should["counts the dealer's cards once per round, not once per player row"]{
    .stg.res:([]round:1 1;cards:(`K`5;`2`3`4);dealer:(`10`8;`10`8));
    .stg.tab:([]round:0N 0N;cards:(();());dealer:``);
    .stg.rules:`maxSplitHands`deckCnt!4 6;
    .stg.count[];
    .stg.trueCount musteq 2%(312-7)%52;                                                            / basic: K5 234 = +3, dealer 10 8 once = -1; 7 cards seen
  };
 };

.tst.desc[".stg.help - 6-deck chart, dealer hits soft 17"]{
  before{.utl.load`:src/players/lib/strategy.q};
  should["doubles the hands that change when the dealer hits soft 17"]{
    .stg.help[`A`7`2] musteq`D;                                                                    / soft 18 vs 2
    .stg.help[`A`8`6] musteq`D;                                                                    / soft 19 vs 6
    .stg.help[`6`5`A] musteq`D;                                                                    / 11 vs ace
  };
  should["sticks instead on a soft 18 or 19 that can no longer double"]{
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
    .stg.help[`7`7`10] musteq`H;                                                                   / 7,7 vs 10: hit, not stick
    .stg.help[`7`7`8] musteq`H;                                                                    / 7,7 vs 8: hit, not split
    .stg.help[`4`4`4] musteq`H;                                                                    / 4,4 vs 4: hit, not split
  };
 };

.tst.desc[".stg.recv"]{
  before{.utl.load`:src/players/lib/strategy.q};
  should["takes the table, results, this client's handle and the table rules from the state the server pushed"]{
    t:([]round:enlist 2;cards:enlist`K`5;dealer:enlist`9);
    r:([]round:enlist 1;cards:enlist`9`8;dealer:enlist`10`7);
    .stg.recv[`tab`res`me`rules`chips!(t;r;7i;`maxSplitHands`deckCnt!4 6;800f)];
    .stg.tab mustmatch t;
    .stg.res mustmatch r;
    .stg.mh musteq 7i;
    .stg.rules mustmatch`maxSplitHands`deckCnt!4 6;
  };
  should["uses the pushed split cap and deck count, not fixed ones"]{
    .stg.recv[`tab`res`me`rules`chips!(([]round:"j"$();cards:();dealer:());([]round:enlist 1;cards:enlist`K`5;dealer:enlist`10`8);7i;`maxSplitHands`deckCnt!2 2;800f)];
    .stg.decide[`8`8`10;2;1b] musteq`H;
    .stg.count[];
    .stg.trueCount musteq -1%(104-4)%52;
  };
 };

.tst.desc[".stg.insureAmount"]{
  before{
    .utl.load`:src/players/lib/strategy.q;
    .stg.mh:7i;
  };
  should["never insures by default"]{
    .stg.tab:([]handle:enlist 7i;bet:enlist 20);
    .stg.trueCount:10f;
    .stg.insureAmount[] musteq 0f;
  };
  should["insures half the bet once the true count reaches .stg.insureAt"]{
    .stg.tab:([]handle:6 7i;bet:40 20);
    .stg.insureAt:3;
    .stg.trueCount:3f;
    .stg.insureAmount[] musteq 10f;
    .stg.trueCount:2.9;
    .stg.insureAmount[] musteq 0f;
  };
 };

.tst.desc[".stg.insureAt per strategy"]{
  should["is 3 for the Hi-Lo counters and never for the others"]{
    .utl.load each`:src/players/lib/strategy.q`:src/players/lib/basicCardCounter.q;
    .stg.insureAt musteq 3;
    .utl.load each`:src/players/lib/strategy.q`:src/players/lib/smallSpreadBasicCardCounter.q;
    .stg.insureAt musteq 3;
    .utl.load each`:src/players/lib/strategy.q`:src/players/lib/omegaCardCounter.q;
    .stg.insureAt musteq 0w;
    .utl.load each`:src/players/lib/strategy.q`:src/players/lib/perfectCardCounter.q;
    .stg.insureAt musteq 0w;
    .utl.load each`:src/players/lib/strategy.q`:src/players/lib/avgPlayer1.q;
    .stg.insureAt musteq 0w;
  };
 };

.tst.desc[".stg.betSpread"]{
  before{.utl.load`:src/players/lib/strategy.q};
  should["steps up a bet per Hi-Lo point from a true count of 2, capped at the last bet"]{
    .stg.trueCount:1.9;
    .stg.betSpread[10 25 40 60 80] musteq 10;
    .stg.trueCount:2f;
    .stg.betSpread[10 25 40 60 80] musteq 25;
    .stg.trueCount:9f;
    .stg.betSpread[10 25 40 60 80] musteq 80;
  };
  should["divides the true count by .stg.countScale first"]{
    .stg.countScale:6f;
    .stg.trueCount:11.9;
    .stg.betSpread[10 25 40 60 80] musteq 10;
    .stg.trueCount:12f;
    .stg.betSpread[10 25 40 60 80] musteq 25;
  };
 };

.tst.desc[".stg.tableBet"]{
  before{.utl.load`:src/players/lib/strategy.q;.stg.rules:`maxSplitHands`deckCnt`minBet`maxBet!4 6 10 500;.stg.chips:1000f};
  should["keeps a bet inside the table limits"]{
    .stg.tableBet[25] musteq 25;
  };
  should["raises a bet below the minimum, so it isn't refused"]{
    .stg.tableBet[5] musteq 10;
  };
  should["caps a bet above the maximum"]{
    .stg.tableBet[800] musteq 500;
  };
 };

.tst.desc[".plr.stake table limits"]{
  should["stakes the strategy's bet clamped to the pushed table limits"]{
    .utl.load each`:src/players/lib/strategy.q`:src/players/lib/avgPlayer2.q;
    .tst.staked:();
    `stake mock {.tst.staked,:x};
    `.stg.getBet mock {5};
    .plr.h:0i;
    .plr.toth:1000;
    .stg.handsPlayed:0;
    t:([]round:"j"$();cards:();dealer:());
    .plr.stake`tab`res`me`rules`chips!(t;t;0i;`maxSplitHands`deckCnt`minBet`maxBet!4 6 10 500;1000f);
    .tst.staked mustmatch enlist 10;
  };
 };

.tst.desc[".stg.decide short of money"]{
  before{.utl.load`:src/players/lib/strategy.q;.stg.rules:`maxSplitHands`deckCnt!4 6};
  should["hits instead of doubling when it can't cover another bet"]{
    .stg.decide[`5`6`6;1;0b] musteq`H;                                                             / hard 11 vs 6 doubles, else hit
  };
  should["sticks instead of doubling where the chart says double, else stick"]{
    .stg.decide[`A`7`4;1;0b] musteq`S;                                                             / soft 18 vs 4: double, else stick
  };
  should["plays a pair as its hard total instead of splitting"]{
    .stg.decide[`8`8`10;1;0b] musteq`H;                                                            / 8,8 vs 10 as hard 16: hit
  };
 };

.tst.desc[".stg.tableBet chips"]{
  before{.utl.load`:src/players/lib/strategy.q;.stg.rules:`maxSplitHands`deckCnt`minBet`maxBet!4 6 10 500};
  should["never bets more than its chips, in whole dollars"]{
    .stg.chips:35.5;
    .stg.tableBet[80] mustmatch 35;
  };
 };

.tst.desc[".stg.available"]{
  should["is its chips less this round's bets and insurance"]{
    .utl.load`:src/players/lib/strategy.q;
    .stg.mh:5i;
    .stg.chips:100f;
    .stg.tab:([]handle:5 5 6i;bet:20 20 40;insurance:10 0 0f);
    .stg.available[] musteq 50f;
  };
 };

.tst.desc[".plr.stake out of chips"]{
  should["leaves instead of staking once it can't afford the minimum bet"]{
    .utl.load each`:src/players/lib/strategy.q`:src/players/lib/avgPlayer1.q;
    .tst.left:();
    `.plr.leave mock {.tst.left,:enlist x};
    .tst.staked:();
    `stake mock {.tst.staked,:x};
    .plr.h:0i;
    .plr.toth:1000;
    .stg.handsPlayed:0;
    t:([]round:0#0;cards:();dealer:0#`);
    .plr.stake`tab`res`me`rules`chips!(t;t;0i;`maxSplitHands`deckCnt`minBet`maxBet!4 6 10 500;8f);
    .tst.left mustmatch enlist"Out of chips";
    count[.tst.staked] musteq 0;
  };
 };

.tst.desc[".stg.recv chips"]{
  should["assumes its own buy-in until the server has chips for it"]{
    .utl.load`:src/players/lib/strategy.q;
    .plr.buyin:1000;
    .stg.recv`tab`res`me`rules`chips!(();();7i;`maxSplitHands`deckCnt`minBet`maxBet`minBuyIn!4 6 10 500 100;0n);
    .stg.chips musteq 1000f;
    .stg.recv`tab`res`me`rules`chips!(();();7i;`maxSplitHands`deckCnt`minBet`maxBet`minBuyIn!4 6 10 500 100;420f);
    .stg.chips musteq 420f;
  };
 };
