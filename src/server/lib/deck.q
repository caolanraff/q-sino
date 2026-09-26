.bs.buildDeck:{[n]
  dc:$[null n;.bs.deckCnt;n];
  .bs.deck:(-52*dc)?raze dc#enlist .bs.deckTemplate;
 };

.bs.shuffle:{
  if[not .bs.hd;.bs.lg"Please wait until the hand is over before requesting a reshuffle";:()];
  .bs.lg"Shuffling the deck";
  .bs.deck:neg[count .bs.deck]?.bs.deck;
  .bs.hist,:.bs.res;
  .bs.res:0#.bs.res;
  .bs.shuffleCnt+:1;
  .bs.count:0f;
  if[(.bs.shuffleCnt>1)&not null .bs.da;.bs.excFunc[`.da.shuffle;`;.bs.da]];
  .bs.excFunc[`.mc.shuffle;`]each key .bs.cp;
 };

.bs.getCard:{
  i:rand count .bs.deck;
  c:.bs.deck i;
  .bs.deck:.bs.deck _ i;
  :c;
 };

.bs.dealCard:{[r]
  c:.bs.getCard[];
  .bs.sendMsg["Your card is ",string c;r`handle];
  update cards:(cards,'c)from`.bs.tab where player=r`player;
 };

.bs.handCount:{[c]
  v:sum"I"$string .bs.cardDict c;
  :"i"$v-10*sum[c=`A]&0|ceiling(v-21)%10;
 };

.bs.isSoft:{[c].bs.handCount[c]>sum["I"$string .bs.cardDict c]-10*sum c=`A};
.bs.isBJ:{[c](2=count c)&21=.bs.handCount c};                                                      / split hands' two-card 21 isn't a natural - callers exclude them

