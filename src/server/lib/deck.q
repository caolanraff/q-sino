/// Deck functions ///
buildDeck:{
  dc:$[null x;.bs.deckCnt;x];
  d:value ssr[{((x*2)-1)#"x,"}[dc];"x";".bs.deckTemplate"];
  .bs.deck:(-52*dc)?d;
  };

shuffle:{
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
  c:rand .bs.deck;
  .bs.deck:.bs.deck except[til count .bs.deck;first where .bs.deck=c];
  c
  };

.bs.dealCard:{
  p:first[x]`player;
  h:first[x]`handle;
  c:.bs.getCard[];
  .bs.sendMsg["Your card is ",(string c);h];
  update cards:(cards,'c) from `.bs.tab where player=p;
  };
