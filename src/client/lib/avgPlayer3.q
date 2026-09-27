system"l src/client/lib/strategy.q";

Help:{
  pc:"I"$string .stg.cardDict[-1_x];
  pc[(0|(sum pc=11)&ceiling (sum[pc]-21)%10)#where pc=11]:1;
  csum:sum pc;
  $[csum<17;`H;`S]
  };

// bets 20 every 5th hand
getBet:{
  :$[(0=count .stg.res)|(not `round in cols .stg.res);
      10;
    0=(exec max round from .stg.res) mod 5;
      20;
      10];
  };
