.utl.require`:src/players/lib/strategy.q;

.stg.help:{[cards]                                                                                 / [cards] rules of thumb, not the chart; the last card is the dealer's
  if[(2=count c)&(c[0]~c 1)&first[c:-1_cards]in`8`A;:`SP];                                         / always split aces and 8s
  if[11 in v:.stg.values c;:$[18>sum v;`H;`S]];                                                    / soft: hit to 17, never double
  if[(2=count v)&(sum[v]in 10 11)&10>d:"I"$string .crd.cardDict last cards;:`D];                   / double 10 or 11 unless the dealer shows a 10 or ace (11)
  if[12>sum v;:`H];                                                                                / can't bust: hit
  if[(16<sum v)|(16=sum v)&d=10;:`S];                                                              / 17 or more, or 16 against a 10 (the dealer has 20 anyway): stick
  :$[d<7;`S;`H];                                                                                   / 12-16: stick if the dealer shows a bust card, else hit
 };

.stg.insureAmount:{                                                                                / take even money on a blackjack, else no insurance
  t:select cards,bet from .stg.tab where handle=.stg.mh;                                           / my hand
  :$[.crd.isBJ first t`cards;0.5*first t`bet;0f];                                                  / half the bet on a blackjack
 };

.stg.getBet:{                                                                                      / chase a loss: $10 more after each, up to $50; back to $10 on a win
  if[0<r:.stg.lastResult[];:10];                                                                   / a win: back to $10
  if[r=0;:10|.stg.lastBet];                                                                        / a push, or my first hand: the same again
  :50&.stg.lastBet+10;                                                                             / a loss: $10 more, up to $50
 };
