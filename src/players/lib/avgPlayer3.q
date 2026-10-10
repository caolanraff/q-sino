.utl.require`:src/players/lib/strategy.q;

.stg.soft:{x^(`D`DS!`H`S)x}each .stg.soft;                                                         / basic strategy, but never doubles a soft hand
update THREE:`H,FOUR:`H,FIVE:`H,SIX:`H from`.stg.hard where hTotal=9;                              / never doubles 9
update ACE:`H from`.stg.hard where hTotal=11;                                                      / hits 11 against an ace
update TEN:`S from`.stg.hard where hTotal=16;                                                      / sticks on 16 against a 10
.stg.pair,:update hTotal:hTotal div 2 from select from .stg.hard where hTotal in 4 6 8 12;         / never splits 2s, 3s, 4s or 6s: plays them by total

.stg.insureAmount:{                                                                                / takes even money on a blackjack, else no insurance
  t:select cards,bet from .stg.tab where handle=.stg.mh;                                           / my hand
  :$[.crd.isBJ first t`cards;0.5*first t`bet;0f];                                                  / half the bet on a blackjack
 };

.stg.getBet:{                                                                                      / chase a loss: $10 more after each, up to $50; back to $10 on a win
  r:.stg.lastResult[];                                                                             / what I won or lost last round
  if[r>0;:10];                                                                                     / a win: back to $10
  if[r=0;:10|.stg.lastBet];                                                                        / a push, or my first hand: the same again
  :50&.stg.lastBet+10;                                                                             / a loss: $10 more, up to $50
 };
