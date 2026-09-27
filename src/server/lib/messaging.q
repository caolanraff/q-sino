.bjk.lg:{-1 ssr[string .z.p;"D";" "]," ",raze x};
.bjk.sendMsg:{[msg;h]@[neg first h;($[10h=type msg;.bjk.lg;show];msg);{.bjk.lg"Couldn't send a message: ",x}]};
.bjk.pubMsg:{.bjk.lg x;.bjk.sendMsg[x]each y};
.bjk.excFunc:{[f;arg;h]@[neg first h;(f;arg);{.bjk.lg"Couldn't send a trigger: ",x}]};
.bjk.clientState:{[h]`tab`res`me`rules!(.bjk.tab;.bjk.res;h;.bjk.rules)};
.bjk.trigger:{[f;h].bjk.excFunc[f;.bjk.clientState h;h]};
.bjk.user:{`$string[.z.u],"_",string .z.w};
.bjk.isPit:{.z.u~`pitboss};

.bjk.regConn:{[h]
  if[.bjk.isPit[];:.bjk.pit:h];
  .bjk.cp[h]:.bjk.user[];
  .bjk.joined[h]:.bjk.rnd;
 };
