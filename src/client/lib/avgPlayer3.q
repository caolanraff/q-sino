system"l src/client/lib/strategy.q";

.stg.help:.stg.hitBelow17;
.stg.getBet:{$[count[.stg.res]&0=(exec max round from .stg.res)mod 5;20;10]};
