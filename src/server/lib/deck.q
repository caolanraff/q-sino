/// Deck functions ///
.bs.buildDeck:{
  dc:$[null x;.bs.deckCnt;x];
  d:raze dc#enlist .bs.deckTemplate;
  .bs.deck:(-52*dc)?d;
  };

.bs.shuffle:{
  if[not .bs.hd;.bs.lg"Please wait unil the hand is over before requesting a reshuffle";:()];
  .bs.lg"Shuffling the deck";
  .bs.deck:(neg count .bs.deck)?.bs.deck;
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
  .bs.deck:(i#.bs.deck),(i+1)_.bs.deck;
  :c;
  };

.bs.dealCard:{
  p:x`player;
  h:x`handle;
  c:.bs.getCard[];
  .bs.sendMsg["Your card is ",(string c);h];
  update cards:(cards,'c) from `.bs.tab where player=p;
  };

/// Hand scoring ///
/ best total for a hand: aces count 11, dropping to 1 one at a time only while the hand would otherwise bust
.bs.handCount:{[c]
  v:sum "I"$string .bs.cardDict c;
  :"i"$v-10*(sum c=`A)&0|ceiling(v-21)%10;
  };

/ a two-card 21 - callers must exclude split hands, whose two-card 21 isn't a natural
.bs.isBJ:{[c](2=count c)&21=.bs.handCount c};
