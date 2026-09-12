Help:{
  csum:sum "I"$string cardDict[-1_x];
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
