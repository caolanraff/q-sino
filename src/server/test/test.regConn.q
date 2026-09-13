/ blackjackServer.q's own regConn/.z.pw/.z.po (lines 19,35,36,41,79) can't be
/ tested against the real file: the real server opens a real listening
/ socket, and identity now comes from the connection handshake itself
/ (.z.u/.z.pw), which a pure in-process unit test can't fake. So this spins
/ up regConn/.z.pw/.z.po exactly as written (copied verbatim, minus the
/ .bs.start/intro calls which need the rest of the server) as a small
/ standalone server subprocess, connects to it with real handles carrying
/ different credentials, and queries the result by connecting to the
/ server directly from this same process.
/ Identity is resolved entirely during the handshake (.z.u is set before
/ .z.po ever runs, and a bad password is rejected by .z.pw before .z.po
/ runs at all) - unlike the old design this replaced, there is no
/ synchronous round-trip back to the connecting client and so no race to
/ guard against.

.tst.desc["regConn / .z.pw / .z.po connection-identity handling (blackjackServer.q:19,35,36,41,79)"]{
  should["a plain, unauthenticated client is registered into cp right away"]{
    port:string 16101 + ((`int$(`long$.z.p) mod 1000) + (("I"$first system "echo $$") mod 1000));
    tag:"qsino_test_regconn_plain_",port;
    srvLines:(
      "\\p ",port;
      "cp:()!()";
      "DA:0Ni";
      "daPass:\"q-sino-da\"";                                            / blackjackServer.q:19, verbatim
      "user:{`$string[.z.u],\"_\",string[.z.w]}";                        / blackjackServer.q:35, verbatim
      "regConn:{cp[x]:user[];x}";                                        / blackjackServer.q:36, verbatim
      ".z.pw:{[u;p] $[u~`detectionAlgo;p~daPass;1b]}";                   / blackjackServer.q:41, verbatim
      ".z.po:{@[{$[`detectionAlgo=.z.u;DA::.z.w;regConn[.z.w]]};();{}]}"); / blackjackServer.q:79, minus .bs.start/intro
    (hsym `$"/tmp/",tag,"_srv.q") 0: srvLines;
    system "q /tmp/",tag,"_srv.q -q < /dev/null > /tmp/",tag,"_srv.log 2>&1 &";
    system "sleep 2";
    h:hopen `$":localhost:",port;
    qh:hopen `$":localhost:",port;
    cpCount:qh"count cp";
    hclose h; hclose qh;
    pids:system "ps aux | grep ",tag,"_srv.q | grep -v grep | awk '{print $2}'";
    if[count pids; system "kill ",(" " sv pids)];
    cpCount musteq 2;
    };

  should["a detectionAlgo client presenting the correct shared secret becomes DA and is never added to cp"]{
    port:string 16201 + ((`int$(`long$.z.p) mod 1000) + (("I"$first system "echo $$") mod 1000));
    tag:"qsino_test_regconn_da_",port;
    srvLines:(
      "\\p ",port;
      "cp:()!()";
      "DA:0Ni";
      "daPass:\"q-sino-da\"";
      "user:{`$string[.z.u],\"_\",string[.z.w]}";
      "regConn:{cp[x]:user[];x}";
      ".z.pw:{[u;p] $[u~`detectionAlgo;p~daPass;1b]}";
      ".z.po:{@[{$[`detectionAlgo=.z.u;DA::.z.w;regConn[.z.w]]};();{}]}");
    (hsym `$"/tmp/",tag,"_srv.q") 0: srvLines;
    system "q /tmp/",tag,"_srv.q -q < /dev/null > /tmp/",tag,"_srv.log 2>&1 &";
    system "sleep 2";
    h:hopen `$":localhost:",port,":detectionAlgo:q-sino-da";
    qh:hopen `$":localhost:",port;
    daIsSet:not null qh"DA";
    cpCount:qh"count cp";
    hclose h; hclose qh;
    pids:system "ps aux | grep ",tag,"_srv.q | grep -v grep | awk '{print $2}'";
    if[count pids; system "kill ",(" " sv pids)];
    daIsSet musteq 1b;
    cpCount musteq 1;  / only qh (the plain query connection); the DA handle never joins cp
    };

  should["a detectionAlgo client presenting the wrong password is rejected outright, touching neither cp nor DA"]{
    port:string 16301 + ((`int$(`long$.z.p) mod 1000) + (("I"$first system "echo $$") mod 1000));
    tag:"qsino_test_regconn_badpw_",port;
    srvLines:(
      "\\p ",port;
      "cp:()!()";
      "DA:0Ni";
      "daPass:\"q-sino-da\"";
      "user:{`$string[.z.u],\"_\",string[.z.w]}";
      "regConn:{cp[x]:user[];x}";
      ".z.pw:{[u;p] $[u~`detectionAlgo;p~daPass;1b]}";
      ".z.po:{@[{$[`detectionAlgo=.z.u;DA::.z.w;regConn[.z.w]]};();{}]}");
    (hsym `$"/tmp/",tag,"_srv.q") 0: srvLines;
    system "q /tmp/",tag,"_srv.q -q < /dev/null > /tmp/",tag,"_srv.log 2>&1 &";
    system "sleep 2";
    rejected:@[{hopen x;0b};`$":localhost:",port,":detectionAlgo:wrongpass";{1b}];
    qh:hopen `$":localhost:",port;
    daIsNull:null qh"DA";
    cpCount:qh"count cp";
    hclose qh;
    pids:system "ps aux | grep ",tag,"_srv.q | grep -v grep | awk '{print $2}'";
    if[count pids; system "kill ",(" " sv pids)];
    rejected musteq 1b;
    daIsNull musteq 1b;
    cpCount musteq 1;  / only qh; the rejected handle never got as far as .z.po
    };
 };
