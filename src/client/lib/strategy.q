.utl.require"common";

.stg.trueCount:0f;                                                                                 / current true count
.stg.insureAt:0w;                                                                                  / true count to insure at; never by default
.stg.handsPlayed:0;                                                                                / hands played so far

.stg.dealerDict:`2`3`4`5`6`7`8`9`11!`TWO`THREE`FOUR`FIVE`SIX`SEVEN`EIGHT`NINE`ACE;                 / dealer card to chart column
.stg.dealerDict,:`10`J`Q`K!`TEN;                                                                   / tens

.stg.hard:([hTotal:3+til 19]                                                                       / hard totals: 6-deck H17 DAS basic strategy
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

.stg.soft:([hTotal:13+til 9]                                                                       / soft totals, A2 (13) to A10 (21); DS = double if allowed, else stick
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

.stg.pair:([hTotal:2+til 10]                                                                       / pairs, by card value; 11 is aces
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

.stg.countDict:.crd.hiLo;                                                                          / count system; a strategy may replace it

.stg.count:{                                                                                       / update the true count from every card seen
  seen:.crd.cardsSeen[.stg.res],.crd.cardsSeen .stg.tab;                                           / cards seen this shoe
  .stg.trueCount:.crd.trueCount[.stg.countDict;seen;52*.stg.rules`deckCnt];                        / true count
 };

.stg.recv:{[s]                                                                                     / [state] keep the state the server pushed
  .stg.tab:s`tab;                                                                                  / the table
  .stg.res:s`res;                                                                                  / this shoe's results
  .stg.mh:s`me;                                                                                    / my handle
  .stg.rules:s`rules;                                                                              / table rules
  .stg.chips:0f^s`chips;                                                                           / my chips; none if I haven't bought in
 };

.stg.values:{[cards]                                                                               / [cards] card values, with aces as 1 where needed
  v:"I"$string .crd.cardDict cards;                                                                / values with every ace as 11
  v[(0|sum[v=11]&ceiling(sum[v]-21)%10)#where v=11]:1;                                             / count just enough aces as 1 to get to 21 or under
  :v;                                                                                              / return them
 };

.stg.lookup:{[t;k;dc]first?[t;enlist(=;`hTotal;k);();first .stg.dealerDict dc]};                   / [table;total;dealer] chart cell for a hand total against the dealer's card

.stg.chartPlay:{[v;dc]                                                                             / [values;dealer] chart play for a hand
  if[any 11 in v;:.stg.lookup[.stg.soft;sum v;dc]];                                                / soft: an ace counts 11
  if[(v[0]~v 1)&3>count v;:.stg.lookup[.stg.pair;v 1;dc]];                                         / a two-card pair
  :.stg.lookup[.stg.hard;sum v;dc];                                                                / otherwise hard
 };

.stg.help:{[cards]                                                                                 / [cards] chart play for a hand; the last card is the dealer's
  if[all 11=distinct"I"$string .crd.cardDict[-1_cards];:`SP];                                      / a pair of aces always splits
  v:.stg.values[-1_cards];                                                                         / player's card values
  r:.stg.chartPlay[v;.crd.cardDict[-1#cards]];                                                     / chart play against the dealer's card
  if[(r=`D)&2<count v;:`H];                                                                        / can't double after two cards: hit
  if[r=`DS;:$[2<count v;`S;`D]];                                                                   / double on two cards, else stick
  if[(r=`SP)&2<count v;:`S];                                                                       / can't split after two cards: stick
  :r;                                                                                              / the play
 };

.stg.hitBelow17:{[cards]$[17>sum .stg.values[-1_cards];`H;`S]};                                    / [cards] hit under 17, else stick
.stg.betSpread:{[bets]bets 0|4&-1+floor .stg.trueCount};                                           / [bets] pick a bet by true count

.stg.decide:{[cards;hands;afford]                                                                  / [cards;hands;afford] the play, playing a pair as a hard total at the split cap or when I can't cover another bet
  r:.stg.help cards;                                                                               / chart play
  if[(r=`SP)&(hands>=.stg.rules`maxSplitHands)|not afford;                                         / split, but at the cap or short of money
    r:.stg.lookup[.stg.hard;sum"I"$string .crd.cardDict[-1_cards];.crd.cardDict last cards];       / play the pair as a hard total
  ];
  if[(r=`D)&not afford;                                                                            / double, but short of money
    r:$[`DS=.stg.chartPlay[.stg.values -1_cards;.crd.cardDict -1#cards];`S;`H];                    / stick where the chart says double-else-stick, else hit
  ];
  :r;                                                                                              / the play
 };

.stg.tableBet:{.stg.rules[`minBet]|.stg.rules[`maxBet]&("j"$floor .stg.chips)&x};                  / keep a bet within the table limits and my chips
.stg.available:{.stg.chips-exec sum(0^bet)+0^insurance from .stg.tab where handle=.stg.mh};        / my chips less what I have on the table this round
.stg.insureAmount:{                                                                                / insurance to take
  :$[.stg.trueCount>=.stg.insureAt;0.5*first exec bet from .stg.tab where handle=.stg.mh;0f];      / half the bet once the true count reaches .stg.insureAt, else 0
 };

.plr.leave:{[msg] -1 msg;hclose .plr.h;exit 0};                                                    / [message] say why, disconnect and exit

.plr.stake:{[s]                                                                                    / [state] bet by the count; replaces player.q's prompt
  .stg.recv s;                                                                                     / take the pushed state
  if[.stg.chips<.stg.rules`minBet;:.plr.leave"Out of chips, disconnecting"];                       / can't afford the minimum: leave
  if[.plr.toth<.stg.handsPlayed+:1;                                                                / count this hand; past --hands, leave
    n:string[.plr.toth]," hand",$[.plr.toth=1;"";"s"];                                             / hands played, e.g. "100 hands"
    :.plr.leave"Played ",n,", disconnecting";                                                      / leave
  ];
  .stg.count[];                                                                                    / update the true count
  neg[.plr.h](`stake;.stg.tableBet .stg.getBet[]);                                                 / bet within the table limits and my chips
 };

.plr.insure:{[s]                                                                                   / [state] insure by the count; replaces player.q's prompt
  .stg.recv s;                                                                                     / take the pushed state
  .stg.count[];                                                                                    / update the true count
  neg[.plr.h](`insure;.stg.insureAmount[]);                                                        / answer
 };

.plr.play:{[s]                                                                                     / [state] play by the chart; replaces player.q's prompt
  .stg.recv s;                                                                                     / take the pushed state
  hand:raze[exec cards from .stg.tab where turn],raze exec dealer from .stg.tab where turn;        / player's cards, then the dealer's
  afford:.stg.available[]>=first exec bet from .stg.tab where turn;                                / can I cover another bet the size of this hand's
  hands:count select from .stg.tab where handle=.stg.mh;                                           / my hands this round
  neg[.plr.h](.plr.handDict .stg.decide[hand;hands;afford];`);                                     / send the play
 };

.plr.shuffle:{.stg.trueCount:0f};                                                                  / new shoe: reset the count; replaces player.q's note

