system"l src/client/lib/playerCore.q";

Help:{
  pc:"I"$string cardDict[-1_x];
  pc[(0|(sum pc=11)&ceiling (sum[pc]-21)%10)#where pc=11]:1;
  csum:sum pc;
  $[csum<17;`H;`S]
  };

// Player 1 only bets 20
getBet:{:20};
