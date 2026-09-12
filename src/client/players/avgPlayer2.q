Help:{
  pc:"I"$string cardDict[-1_x];
  while[(sum[pc]>21)&any pc=11;pc[first where pc=11]:1];
  csum:sum pc;
  $[csum<17;`H;`S]
  };

// bets the profit of previous hand
getBet:{
  getRes[];
  bet:$[(0=count .mc.res)|(not `profit in cols .mc.res);
    10;
    "i"$last exec profit from .mc.res where name=.z.u];
  if[bet<=0;bet:10];
  bet
  };
