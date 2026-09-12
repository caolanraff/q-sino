/ blackjackServer.q's own regConn/.z.po (lines 35,73) can't be tested
/ against the real file: the real server opens a real listening socket, and
/ .z.po does a real network round-trip to the connecting client that a pure
/ in-process unit test can't fake. So this spins up regConn/.z.po exactly
/ as written (copied verbatim) as a small standalone server subprocess, and
/ drives it with real second/third processes: one playing a bare "manual"
/ client (per README: a plain `q` session, no masterClient.q and so no
/ global `p`), one querying the result.

.tst.desc["regConn / .z.po manual (bare) client registration (blackjackServer.q:35,73)"]{
  should["a manual client with no global `p` still gets registered in cp"]{
    / mix in the OS pid for extra entropy - .z.p alone has repeated when the
    / suite runs several times in quick succession.
    port:string 16001 + ((`int$(`long$.z.p) mod 1000) + (("I"$first system "echo $$") mod 1000));
    tag:"qsino_test_regconn_",port;
    srvLines:(
      "\\p ",port;
      "cp:()!()";
      "DA:0Ni";
      "regConn:{pv:@[x;`p;`];$[`detectionAlgo=pv;DA::x;cp[x]:`user];pv}";  / blackjackServer.q:35, verbatim
      ".z.po:{@[{regConn[.z.w]};();{}]}");                                 / blackjackServer.q:73, minus the intro-send
    (hsym `$"/tmp/",tag,"_srv.q") 0: srvLines;
    clientLines:enlist "h:hopen `:localhost:",port,"; system \"sleep 2\"; exit 0";
    (hsym `$"/tmp/",tag,"_client.q") 0: clientLines;
    queryLines:("h:hopen `:localhost:",port;"(hsym `$\"/tmp/",tag,"_result\") 0: enlist string h\"count cp\"";"exit 0");
    (hsym `$"/tmp/",tag,"_query.q") 0: queryLines;
    system "q /tmp/",tag,"_srv.q -q < /dev/null > /tmp/",tag,"_srv.log 2>&1 &";
    system "sleep 2";
    system "q /tmp/",tag,"_client.q -q < /dev/null > /tmp/",tag,"_client.log 2>&1 &";
    system "sleep 1";  / let the client connect and the server's sync round-trip land while it's still up
    system "q /tmp/",tag,"_query.q -q < /dev/null > /tmp/",tag,"_query.log 2>&1";
    system "sleep 2";  / let the client's own process exit, and the query's file write land
    cpCount:$[count key hsym `$"/tmp/",tag,"_result";"J"$first read0 hsym `$"/tmp/",tag,"_result";0Nj];
    pids:system "ps aux | grep ",tag,"_srv.q | grep -v grep | awk '{print $2}'";
    if[count pids; system "kill ",(" " sv pids)];
    cpCount musteq 1;
    };
 };
