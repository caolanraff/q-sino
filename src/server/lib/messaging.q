.bs.lg:{-1 ssr[string .z.p;"D";" "]," ",raze x};
.bs.sendMsg:{[msg;h]@[neg first h;($[10h=type msg;.bs.lg;show];msg);{.bs.lg"Couldn't send a message: ",x}]};
.bs.pubMsg:{.bs.lg x;.bs.sendMsg[x]each y};
.bs.excFunc:{[f;arg;h]@[neg first h;(f;arg);{.bs.lg"Couldn't send a trigger: ",x}]};
.bs.clientState:{[h]`tab`res`me!(.bs.tab;.bs.res;h)};
.bs.trigger:{[f;h].bs.excFunc[f;.bs.clientState h;h]};
.bs.user:{`$string[.z.u],"_",string .z.w};
.bs.isDA:{.z.u~`detectionAlgo};

.bs.regConn:{[h]
  if[.bs.isDA[];:.bs.da:h];
  .bs.cp[h]:.bs.user[];
  .bs.joined[h]:.bs.rnd;
 };
