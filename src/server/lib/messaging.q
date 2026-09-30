.bjk.display:{[msg]($[10h=type msg;-1;show];msg)};
.bjk.sendMsg:{[msg;h]@[neg first h;.bjk.display msg;{.log.warn"Couldn't send a message: ",x}]};
.bjk.pubMsg:{.log.info x;.bjk.sendMsg[x]each y};
.bjk.excFunc:{[f;arg;h]@[neg first h;(f;arg);{.log.warn"Couldn't send a trigger: ",x}]};
.bjk.clientState:{[h]`tab`res`me`rules!(.bjk.tab;.bjk.res;h;.bjk.rules)};
.bjk.trigger:{[f;h].bjk.excFunc[f;.bjk.clientState h;h]};
.bjk.user:{`$string[.z.u],"_",string .z.w};
.bjk.isPit:{.z.u~`pitboss};

.bjk.regConn:{[h]
  if[.bjk.isPit[];:.bjk.pit:h];
  .bjk.cp[h]:.bjk.user[];
  .bjk.joined[h]:.bjk.rnd;
 };
