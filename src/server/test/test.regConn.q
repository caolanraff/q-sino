/ blackjackServer.q's own user/isDA/regConn/.z.po/.z.pc (lines 34,38,39,
/ 77,78) can't be tested against the real file: the real server opens a
/ real listening socket, and identity now comes from the connection
/ handshake itself (.z.u), which a pure in-process unit test can't fake.
/ So this spins up user/isDA/regConn/.z.po/.z.pc exactly as written (copied
/ verbatim, minus the .bs.start/intro/leave calls which need the rest of
/ the server) as a small standalone server subprocess, connects to it with
/ real handles carrying different usernames, and queries the result by
/ connecting to the server directly from this same process.
/ Identity is resolved entirely during the handshake (.z.u is set before
/ .z.po ever runs) - unlike the old design this replaced, there is no
/ synchronous round-trip back to the connecting client and so no race to
/ guard against.

.tst.desc["regConn / .z.po / .z.pc connection-identity handling (blackjackServer.q:34,38,39,77,78)"]{
  should["a plain client is registered into cp right away"]{
    port:string 16101 + ((`int$(`long$.z.p) mod 1000) + (("I"$first system "echo $$") mod 1000));
    tag:"qsino_test_regconn_plain_",port;
    srvLines:(
      "\\p ",port;
      "cp:()!()";
      "DA:0Ni";
      "user:{`$string[.z.u],\"_\",string[.z.w]}";               / blackjackServer.q:34, verbatim
      "isDA:{.z.u~`detectionAlgo}";                              / blackjackServer.q:38, verbatim
      "regConn:{$[isDA[];DA::x;cp[x]:user[]]}";                  / blackjackServer.q:39, verbatim
      ".z.po:{@[{regConn[.z.w]};();{}]}");                       / blackjackServer.q:77, minus .bs.start/intro
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

  should["a client connecting as detectionAlgo becomes DA and is never added to cp"]{
    port:string 16201 + ((`int$(`long$.z.p) mod 1000) + (("I"$first system "echo $$") mod 1000));
    tag:"qsino_test_regconn_da_",port;
    srvLines:(
      "\\p ",port;
      "cp:()!()";
      "DA:0Ni";
      "user:{`$string[.z.u],\"_\",string[.z.w]}";
      "isDA:{.z.u~`detectionAlgo}";
      "regConn:{$[isDA[];DA::x;cp[x]:user[]]}";
      ".z.po:{@[{regConn[.z.w]};();{}]}");
    (hsym `$"/tmp/",tag,"_srv.q") 0: srvLines;
    system "q /tmp/",tag,"_srv.q -q < /dev/null > /tmp/",tag,"_srv.log 2>&1 &";
    system "sleep 2";
    h:hopen `$":localhost:",port,":detectionAlgo";
    qh:hopen `$":localhost:",port;
    daIsSet:not null qh"DA";
    cpCount:qh"count cp";
    hclose h; hclose qh;
    pids:system "ps aux | grep ",tag,"_srv.q | grep -v grep | awk '{print $2}'";
    if[count pids; system "kill ",(" " sv pids)];
    daIsSet musteq 1b;
    cpCount musteq 1;  / only qh (the plain query connection); the DA handle never joins cp
    };

  should["DA resets to null when the detectionAlgo connection closes, without touching cp"]{
    port:string 16301 + ((`int$(`long$.z.p) mod 1000) + (("I"$first system "echo $$") mod 1000));
    tag:"qsino_test_regconn_pc_",port;
    srvLines:(
      "\\p ",port;
      "cp:()!()";
      "DA:0Ni";
      "user:{`$string[.z.u],\"_\",string[.z.w]}";
      "isDA:{.z.u~`detectionAlgo}";
      "regConn:{$[isDA[];DA::x;cp[x]:user[]]}";
      ".z.po:{@[{regConn[.z.w]};();{}]}";
      ".z.pc:{$[x=DA;DA::0Ni;cp::x _cp]}");                      / blackjackServer.q:78, minus leave's server-state cleanup
    (hsym `$"/tmp/",tag,"_srv.q") 0: srvLines;
    system "q /tmp/",tag,"_srv.q -q < /dev/null > /tmp/",tag,"_srv.log 2>&1 &";
    system "sleep 2";
    qh:hopen `$":localhost:",port;
    hDA:hopen `$":localhost:",port,":detectionAlgo";
    cpCountBeforeClose:qh"count cp";
    hclose hDA;
    system "sleep 1";
    daAfterClose:qh"DA";
    cpCountAfterClose:qh"count cp";
    hclose qh;
    pids:system "ps aux | grep ",tag,"_srv.q | grep -v grep | awk '{print $2}'";
    if[count pids; system "kill ",(" " sv pids)];
    cpCountBeforeClose musteq 1;  / just qh; the DA handle never joined cp
    daAfterClose musteq 0Ni;
    cpCountAfterClose musteq 1;  / qh untouched by the DA's disconnect
    };
 };
