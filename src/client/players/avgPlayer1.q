Help:{
  pc:"I"$string cardDict[-1_x];
  while[(sum[pc]>21)&any pc=11;pc[first where pc=11]:1];
  csum:sum pc;
  $[csum<17;`H;`S]
  };

// Player 1 only bets 20
getBet:{:20};
