.crd.cardDict:`A`K`Q`J`10`9`8`7`6`5`4`3`2!`11`10`10`10`10`9`8`7`6`5`4`3`2;                         / card to its value, ace high

.crd.hiLo:`2`3`4`5`6`7`8`9`10`J`Q`K`A!1 1 1 1 1 0 0 0 -1 -1 -1 -1 -1;                              / Hi-Lo count per card
.crd.omega:`2`3`4`5`6`7`8`9`10`J`Q`K`A!1 1 2 2 2 1 0 -1 -2 -2 -2 -2 0;                             / Omega II count per card
.crd.perfect:`2`3`4`5`6`7`8`9`10`J`Q`K`A!4 5 6 9 6 4 1 -2 -8 -8 -8 -8 -3;                          / perfect (weighted) count per card

.crd.cardsSeen:{[t]                                                                                / every card dealt in a tab/res table, e.g. .crd.cardsSeen .bjk.res
  c:raze[t`cards],raze value exec{x first idesc count each x}dealer by round from t;               / dealer's hand once per round; a forfeit row has only the up-card
  :c where not null c;                                                                             / drop empty card slots
 };

.crd.trueCount:{[pts;seen;shoe]sum[pts seen]%(shoe-count seen)%52};                                / running count per deck left, e.g. .crd.trueCount[.crd.hiLo;`2`5`K;312]
