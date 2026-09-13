/// Messaging / connection-identity functions ///
/ loaded into bin/blackjackServer.q; moved here verbatim, no behavior change.
lg:{-1 ssr[string[.z.p];"D";" "]," ",raze x};
sendMsg:{neg[first y]($[10h=type x;lg;show];x)};
pubMsg:{lg x;sendMsg[x]each y};
excFunc:{neg[first z](x;y)};
user:{`$string[.z.u],"_",string[.z.w]};
isDA:{.z.u~`detectionAlgo};
regConn:{$[isDA[];DA::x;cp[x]:user[]]};
