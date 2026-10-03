.utl.require`:src/players/lib/strategy.q;

.stg.help:.stg.hitBelow17;                                                                         / hit under 17, else stick
.stg.getBet:{$[0=count .stg.res;10;0=(exec max round from .stg.res)mod 5;20;10]};                  / bet $20 every fifth round, else $10
