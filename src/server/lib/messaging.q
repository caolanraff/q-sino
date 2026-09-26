/// Messaging / connection-identity functions ///
.bs.lg:{-1 ssr[string[.z.p];"D";" "]," ",raze x};
.bs.sendMsg:{neg[first y]($[10h=type x;.bs.lg;show];x)};
.bs.pubMsg:{.bs.lg x;.bs.sendMsg[x]each y};
.bs.excFunc:{neg[first z](x;y)};
.bs.clientState:{[h]`tab`res`me`rules!(.bs.tab;.bs.res;h;enlist[`surrender]!enlist .bs.surrender)};
.bs.trigger:{[f;h].bs.excFunc[f;.bs.clientState h;h]};
.bs.user:{`$string[.z.u],"_",string[.z.w]};
.bs.isDA:{.z.u~`detectionAlgo};
.bs.regConn:{
  if[.bs.isDA[];:.bs.da:x];
  .bs.cp[x]:.bs.user[];
  .bs.joined[x]:.bs.rnd;
  };
