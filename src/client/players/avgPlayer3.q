Help:{
  csum:sum "I"$string cardDict[-1_x];
  $[csum<17;`H;`S]
  };

// bets 20 every 5th hand
getBet:{
  :$[(0=count .mc.res)|(not `round in cols .mc.res);
      10;
    0=(exec max round from .mc.res) mod 5;
      20;
      10];
  };
