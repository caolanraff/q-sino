/ blackjackServer.q's own regConn/.z.po (lines 35,73) can't be tested against
/ the real file directly: the real server currently crashes on startup
/ (see test.blackjackServer.q's "startup" spec) before it could ever accept
/ a connection, and even once that's fixed, .z.po itself does a *real*
/ network round-trip to the connecting client that a pure in-process unit
/ test can't fake. So this spins up regConn/.z.po exactly as written in
/ blackjackServer.q (lines 35 and 73, copied verbatim) as a small standalone
/ server subprocess, and drives it with real second/third processes: one
/ playing the part of a bare "manual" client (per README: a plain `q`
/ session, with no masterClient.q and so no global `p` defined), one
/ querying the result back out.

.tst.desc["regConn / .z.po manual (bare) client registration (blackjackServer.q:35,73)"]{

  should["confirms review finding: a manual client with no global `p` never gets registered in cp"]{
    / mix in the OS pid for extra entropy - .z.p alone has repeated when the
    / suite runs several times in quick succession, risking a port clash
    / with a leftover process from a previous run.
    port:string 16001 + ((`int$(`long$.z.p) mod 1000) + (("I"$first system "echo $$") mod 1000));
    tag:"qsino_test_regconn_",port;

    srvLines:(
      "\\p ",port;
      "cp:()!()";
      "DA:0Ni";
      "regConn:{$[`detectionAlgo=x`p;DA::x;cp[x]:`user]}";  / blackjackServer.q:35, verbatim
      "regConn2:{@[regConn;x;{}]}";                          / don't let .z.po's own crash bring the harness down
      ".z.po:{regConn2[.z.w]}");                              / blackjackServer.q:73, minus the intro-send
    (hsym `$"/tmp/",tag,"_srv.q") 0: srvLines;

    clientLines:enlist "h:hopen `:localhost:",port,"; system \"sleep 1\"; exit 0";
    (hsym `$"/tmp/",tag,"_client.q") 0: clientLines;

    queryLines:("h:hopen `:localhost:",port;"(hsym `$\"/tmp/",tag,"_result\") 0: enlist string h\"count cp\"";"exit 0");
    (hsym `$"/tmp/",tag,"_query.q") 0: queryLines;

    system "q /tmp/",tag,"_srv.q -q < /dev/null > /tmp/",tag,"_srv.log 2>&1 &";
    system "sleep 2";
    system "q /tmp/",tag,"_client.q -q < /dev/null > /tmp/",tag,"_client.log 2>&1";
    system "sleep 2";  / give the server's own sync round-trip to the client time to unblock
    system "q /tmp/",tag,"_query.q -q < /dev/null > /tmp/",tag,"_query.log 2>&1";
    system "sleep 2";  / and let the query process's file write land before we read it back

    cpCount:$[count key hsym `$"/tmp/",tag,"_result";"J"$first read0 hsym `$"/tmp/",tag,"_result";0Nj];

    / lsof/pgrep have proven unreliable for finding a sibling process spawned
    / by an earlier `system[...&]` call in this environment; `ps`+`awk`,
    / matched against this run's uniquely-tagged server script, works.
    pids:system "ps aux | grep ",tag,"_srv.q | grep -v grep | awk '{print $2}'";
    if[count pids; system "kill ",(" " sv pids)];

    cpCount musteq 0;
    };

 };
