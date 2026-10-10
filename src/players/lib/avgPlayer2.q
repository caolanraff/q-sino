.utl.require`:src/players/lib/strategy.q;

.stg.wins:0;                                                                                       / wins in a row

.stg.help:{[cards]                                                                                 / [cards] afraid to bust: stick on any 12 or more; the last card is the dealer's
  if[`A`A~c:-1_cards;:`SP];                                                                        / split aces, the one split everyone knows
  if[11 in v:.stg.values c;:$[17>sum v;`H;`S]];                                                    / soft: stick from 17
  if[(2=count v)&11=sum v;:`D];                                                                    / double 11, the one double everyone knows
  :$[12>sum v;`H;`S];                                                                              / hit only while a card can't bust me
 };

.stg.insureAmount:{                                                                                / insure a 20 or a blackjack, to protect it
  t:select cards,bet from .stg.tab where handle=.stg.mh;                                           / my hand
  :$[20<=sum .stg.values first t`cards;0.5*first t`bet;0f];                                        / half the bet on 20 or more
 };

.stg.getBet:{                                                                                      / press a win: add it to the bet, pocketing the third in a row; else $10
  if[0>r:.stg.lastResult[];.stg.wins:0;:10];                                                       / a loss: back to $10
  if[r=0;:10|.stg.lastBet];                                                                        / a push, or my first hand: the same again
  if[3=.stg.wins+:1;.stg.wins:0;:10];                                                              / a third win in a row: pocket it, back to $10
  :.stg.lastBet+"j"$r;                                                                             / let it ride
 };
