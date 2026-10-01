.utl.require"common";

.stg.trueCount:0f;
.stg.insureAt:0w;
.stg.handsPlayed:0;

.stg.dealerDict:`2`3`4`5`6`7`8`9`10`J`Q`K`11!`TWO`THREE`FOUR`FIVE`SIX`SEVEN`EIGHT`NINE`TEN`TEN`TEN`TEN`ACE;

.stg.hard:([hTotal:3+til 19]                                                                       / 6-deck H17 DAS basic strategy; DS = double if allowed, else stick
  TWO:`H`H`H`H`H`H`H`D`D`H`S`S`S`S`S`S`S`S`S;
  THREE:`H`H`H`H`H`H`D`D`D`H`S`S`S`S`S`S`S`S`S;
  FOUR:`H`H`H`H`H`H`D`D`D`S`S`S`S`S`S`S`S`S`S;
  FIVE:`H`H`H`H`H`H`D`D`D`S`S`S`S`S`S`S`S`S`S;
  SIX:`H`H`H`H`H`H`D`D`D`S`S`S`S`S`S`S`S`S`S;
  SEVEN:`H`H`H`H`H`H`H`D`D`H`H`H`H`H`S`S`S`S`S;
  EIGHT:`H`H`H`H`H`H`H`D`D`H`H`H`H`H`S`S`S`S`S;
  NINE:`H`H`H`H`H`H`H`D`D`H`H`H`H`H`S`S`S`S`S;
  TEN:`H`H`H`H`H`H`H`H`D`H`H`H`H`H`S`S`S`S`S;
  ACE:`H`H`H`H`H`H`H`H`D`H`H`H`H`H`S`S`S`S`S);

.stg.soft:([hTotal:13+til 9]
  TWO:`H`H`H`H`H`DS`S`S`S;
  THREE:`H`H`H`H`D`DS`S`S`S;
  FOUR:`H`H`D`D`D`DS`S`S`S;
  FIVE:`D`D`D`D`D`DS`S`S`S;
  SIX:`D`D`D`D`D`DS`DS`S`S;
  SEVEN:`H`H`H`H`H`S`S`S`S;
  EIGHT:`H`H`H`H`H`S`S`S`S;
  NINE:`H`H`H`H`H`H`S`S`S;
  TEN:`H`H`H`H`H`H`S`S`S;
  ACE:`H`H`H`H`H`H`S`S`S);

.stg.pair:([hTotal:2+til 10]
  TWO:`SP`SP`H`D`SP`SP`SP`SP`S`SP;
  THREE:`SP`SP`H`D`SP`SP`SP`SP`S`SP;
  FOUR:`SP`SP`H`D`SP`SP`SP`SP`S`SP;
  FIVE:`SP`SP`SP`D`SP`SP`SP`SP`S`SP;
  SIX:`SP`SP`SP`D`SP`SP`SP`SP`S`SP;
  SEVEN:`SP`SP`H`D`H`SP`SP`S`S`SP;
  EIGHT:`H`H`H`D`H`H`SP`SP`S`SP;
  NINE:`H`H`H`D`H`H`SP`SP`S`SP;
  TEN:`H`H`H`H`H`H`SP`S`S`SP;
  ACE:`H`H`H`H`H`H`SP`S`S`SP);

.stg.countDict:.crd.hiLo;

.stg.count:{
  seen:.crd.cardsSeen[.stg.res],.crd.cardsSeen .stg.tab;
  .stg.trueCount:.crd.trueCount[.stg.countDict;seen;52*.stg.rules`deckCnt];
 };

.stg.recv:{[s]
  .stg.tab:s`tab;
  .stg.res:s`res;
  .stg.mh:s`me;
  .stg.rules:s`rules;
 };

.stg.values:{[cards]
  v:"I"$string .crd.cardDict cards;
  v[(0|sum[v=11]&ceiling(sum[v]-21)%10)#where v=11]:1;
  :v;
 };

.stg.lookup:{[t;k;dc]first?[t;enlist(=;`hTotal;k);();first .stg.dealerDict dc]};

.stg.chartPlay:{[v;dc]
  if[any 11 in v;:.stg.lookup[.stg.soft;sum v;dc]];
  if[(v[0]~v 1)&3>count v;:.stg.lookup[.stg.pair;v 1;dc]];
  :.stg.lookup[.stg.hard;sum v;dc];
 };

.stg.help:{[cards]
  if[all 11=distinct"I"$string .crd.cardDict[-1_cards];:`SP];
  v:.stg.values[-1_cards];
  r:.stg.chartPlay[v;.crd.cardDict[-1#cards]];
  if[(r=`D)&2<count v;:`H];
  if[r=`DS;:$[2<count v;`S;`D]];
  if[(r=`SP)&2<count v;:`S];
  :r;
 };

.stg.hitBelow17:{[cards]$[17>sum .stg.values[-1_cards];`H;`S]};
.stg.betSpread:{[bets]bets 0|4&-1+floor .stg.trueCount};

.stg.decide:{[cards;hands]
  r:.stg.help cards;
  if[(r=`SP)&hands>=.stg.rules`maxSplitHands;
    r:.stg.lookup[.stg.hard;sum"I"$string .crd.cardDict[-1_cards];.crd.cardDict last cards];
  ];
  :r;
 };

.stg.tableBet:{.stg.rules[`minBet]|.stg.rules[`maxBet]&x};
.stg.insureAmount:{$[.stg.trueCount>=.stg.insureAt;0.5*first exec bet from .stg.tab where handle=.stg.mh;0f]};

/ real auto-play hooks the server pushes to every connected handle; loaded whenever a
/ strategy file loads this, overriding player.q's log-only defaults
.plr.stake:{[s]
  .stg.recv s;
  if[.plr.toth<.stg.handsPlayed+:1;
    -1"Played ",string[.plr.toth]," hand",$[.plr.toth=1;"";"s"],", disconnecting";
    hclose .plr.h;
    exit 0;
  ];
  .stg.count[];
  neg[.plr.h](`stake;.stg.tableBet .stg.getBet[]);
 };

.plr.insure:{[s]
  .stg.recv s;
  .stg.count[];
  neg[.plr.h](`insure;.stg.insureAmount[]);
 };

.plr.play:{[s]
  .stg.recv s;
  hand:raze[exec cards from .stg.tab where turn],raze exec dealer from .stg.tab where turn;
  neg[.plr.h](.plr.handDict .stg.decide[hand;count select from .stg.tab where handle=.stg.mh];`);
 };

.plr.shuffle:{.stg.trueCount:0f};

