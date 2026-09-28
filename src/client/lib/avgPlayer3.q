system"l src/client/lib/strategy.q";

.stg.help:.stg.hitBelow17;
.stg.getBet:{$[0=count .stg.res;10;0=(exec max round from .stg.res)mod 5;20;10]};
