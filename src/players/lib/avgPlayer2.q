.utl.require`:src/players/lib/strategy.q;

.stg.help:.stg.hitBelow17;                                                                         / hit under 17, else stick
.stg.getBet:{$[0<p:"j"$last 0f,exec profit from .stg.res where uid=.stg.uid;p;10]};                / bet last hand's winnings, else $10
