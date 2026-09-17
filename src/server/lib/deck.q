/// Deck functions ///
buildDeck:{
  dc:$[null x;deckCnt;x];
  d:value ssr[{((x*2)-1)#"x,"}[dc];"x";"deck"];
  .bs.deck:(-52*dc)?d;
  };

shuffle:{
  if[not .bs.hd;lg"Please wait unil the hand is over before requesting a reshuffle";:()];
  lg"Shuffling the deck";
  .bs.deck:(neg count .bs.deck)?.bs.deck;
  .bs.hist,:.bs.res;
  .bs.res:0#.bs.res;
  shufflecnt+:1;
  .bs.count:0f;
  if[(shufflecnt>1)&not null DA;excFunc[`shuffle;`;DA]];
  excFunc[`shuffle;`]each autoH;
  };

getCard:{
  c:rand .bs.deck;
  .bs.deck:.bs.deck except[til count .bs.deck;first where .bs.deck=c];
  c
  };

dealCard:{
  p:first[x]`player;
  h:first[x]`handle;
  c:getCard[];
  sendMsg["Your card is ",(string c);h];
  update cards:(cards,'c) from `.bs.tab where player=p;
  };
