.bjk.buildDeck:{[n]
  dc:$[null n;.bjk.rules`deckCnt;n];
  .bjk.deck:(-52*dc)?raze dc#enlist .bjk.deckTemplate;
 };

.bjk.shuffle:{
  if[not .bjk.hd;.bjk.lg"Please wait until the hand is over before requesting a reshuffle";:()];
  .bjk.lg"Shuffling the deck";
  .bjk.deck:neg[count .bjk.deck]?.bjk.deck;
  .bjk.hist,:.bjk.res;
  .bjk.res:0#.bjk.res;
  .bjk.shuffleCnt+:1;
  if[(.bjk.shuffleCnt>1)&not null .bjk.pit;.bjk.excFunc[`.pit.shuffle;`;.bjk.pit]];
  .bjk.excFunc[`.plr.shuffle;`]each key .bjk.cp;
 };

.bjk.getCard:{
  i:rand count .bjk.deck;
  c:.bjk.deck i;
  .bjk.deck:.bjk.deck _ i;
  :c;
 };

.bjk.dealCard:{[r]
  c:.bjk.getCard[];
  .bjk.sendMsg["Your card is ",string c;r`handle];
  update cards:(cards,'c)from`.bjk.tab where player=r`player;
 };

.bjk.handCount:{[c]
  v:sum"I"$string .bjk.cardDict c;
  :"i"$v-10*sum[c=`A]&0|ceiling(v-21)%10;
 };

.bjk.isSoft:{[c].bjk.handCount[c]>sum["I"$string .bjk.cardDict c]-10*sum c=`A};
.bjk.isBJ:{[c](2=count c)&21=.bjk.handCount c};                                                      / split hands' two-card 21 isn't a natural - callers exclude them

