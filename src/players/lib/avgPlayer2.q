.utl.require`:src/players/lib/strategy.q;

.stg.wins:0;                                                                                       / wins in a row

.stg.help:{[cards]                                                                                 / [cards] rules of thumb, not the chart; the last card is the dealer's
  c:-1_cards;                                                                                      / my cards
  if[(2=count c)&(c[0]~c 1)&first[c]in`8`A;:`SP];                                                  / always split aces and 8s
  v:.stg.values c;                                                                                 / their values
  d:"I"$string .crd.cardDict last cards;                                                           / the dealer's card value, ace 11
  if[11 in v;:$[18>sum v;`H;`S]];                                                                  / soft: hit to 17, never double
  if[(2=count v)&(sum[v]in 10 11)&d<10;:`D];                                                       / double 10 or 11 unless the dealer shows a 10 or ace
  if[12>sum v;:`H];                                                                                / can't bust: hit
  if[16<sum v;:`S];                                                                                / 17 or more: stick
  :$[d<7;`S;`H];                                                                                   / 12-16: stick if the dealer shows a bust card, else hit
 };

.stg.getBet:{                                                                                      / press a win: add it to the bet, pocketing the third in a row; else $10
  r:.stg.lastResult[];                                                                             / what I won or lost last round
  if[r<0;.stg.wins:0;:10];                                                                         / a loss: back to $10
  if[r=0;:10|.stg.lastBet];                                                                        / a push, or my first hand: the same again
  if[3=.stg.wins+:1;.stg.wins:0;:10];                                                              / a third win in a row: pocket it, back to $10
  :.stg.lastBet+"j"$r;                                                                             / let it ride
 };
