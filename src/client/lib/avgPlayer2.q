system"l src/client/lib/strategy.q";

Help:{
  pc:"I"$string .stg.cardDict[-1_x];
  pc[(0|(sum pc=11)&ceiling (sum[pc]-21)%10)#where pc=11]:1;
  csum:sum pc;
  $[csum<17;`H;`S]
  };

// bets the profit of previous hand
getBet:{
  bet:$[(0=count .stg.res)|(not `profit in cols .stg.res);
    10;
    "i"$last exec profit from .stg.res where handle=.stg.mh];
  if[bet<=0;bet:10];
  bet
  };
