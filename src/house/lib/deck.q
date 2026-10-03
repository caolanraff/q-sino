.bjk.buildDeck:{[n]                                                                                / [decks] build a new shoe; null for the table's deck count
  dc:$[null n;.bjk.rules`deckCnt;n];                                                               / number of decks
  .bjk.deck:(-52*dc)?raze dc#enlist .bjk.deckTemplate;                                             / every card, in random order
 };

.bjk.shuffle:{                                                                                     / reshuffle and start a new shoe
  if[not .bjk.hd;.log.info"Please wait until the hand is over before requesting a reshuffle";:()]; / not mid-hand
  .log.info"Shuffling the deck";
  .bjk.deck:neg[count .bjk.deck]?.bjk.deck;                                                        / reorder the cards left
  .bjk.hist,:.bjk.res;                                                                             / archive this shoe's results
  .bjk.res:0#.bjk.res;                                                                             / clear them
  .bjk.shuffleCnt+:1;                                                                              / count shuffles
  if[(.bjk.shuffleCnt>1)&not null .bjk.pit;.bjk.excFunc[`.pit.shuffle;`;.bjk.pit]];                / tell the pitboss, after the first shuffle
  .bjk.excFunc[`.plr.shuffle;`]each key .bjk.cp;                                                   / tell every player
 };

.bjk.getCard:{                                                                                     / draw a random card from the shoe
  i:rand count .bjk.deck;                                                                          / pick a position
  c:.bjk.deck i;                                                                                   / the card there
  .bjk.deck:.bjk.deck _ i;                                                                         / remove it from the shoe
  :c;                                                                                              / return it
 };

.bjk.dealCard:{[r]                                                                                 / [row] deal a card to a hand
  c:.bjk.getCard[];                                                                                / draw
  .bjk.sendMsg["Your card is ",string c;r`handle];                                                 / tell the player
  update cards:(cards,'c)from`.bjk.tab where player=r`player;                                      / add it to the hand
 };

.bjk.handCount:{[c]                                                                                / [cards] best total for a hand
  v:sum"I"$string .crd.cardDict c;                                                                 / total with every ace as 11
  :"i"$v-10*sum[c=`A]&0|ceiling(v-21)%10;                                                          / count just enough aces as 1 to get to 21 or under
 };

.bjk.isSoft:{[c].bjk.handCount[c]>sum["I"$string .crd.cardDict c]-10*sum c=`A};                    / [cards] an ace still counts as 11
.bjk.showHand:{[c].util.clist[c]," (",$[.bjk.isSoft c;"soft ";""],string[.bjk.handCount c],")"};   / [cards] a hand and its count, e.g. "A,6 (soft 17)"
.bjk.aCard:{[c]$[c in`A`8;"an ";"a "],string c};                                                   / [card] the card with its article, e.g. "an A"
.bjk.isBJ:{[c](2=count c)&21=.bjk.handCount c};                                                    / [cards] two-card 21; callers exclude split hands, whose 21 isn't a natural

