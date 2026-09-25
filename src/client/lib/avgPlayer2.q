system"l src/client/lib/playerCore.q";

Help:{
  pc:"I"$string .mc.cardDict[-1_x];
  pc[(0|(sum pc=11)&ceiling (sum[pc]-21)%10)#where pc=11]:1;
  csum:sum pc;
  $[csum<17;`H;`S]
  };

// bets the profit of previous hand
getBet:{
  .mc.getRes[];
  bet:$[(0=count .mc.res)|(not `profit in cols .mc.res);
    10;
    "i"$last exec profit from .mc.res where handle=.mc.mh];
  if[bet<=0;bet:10];
  bet
  };
