/ blackjackServer.q's own regConn/unregDA/.z.po (lines 35-40,74) can't be
/ tested against the real file: the real server opens a real listening
/ socket, and .z.po does a real network round-trip to the connecting
/ client that a pure in-process unit test can't fake. So this spins up
/ regConn/unregDA/.z.po exactly as written (copied verbatim) as a small
/ standalone server subprocess, drives it with a real second process
/ playing a bare "manual" client (per README: a plain `q` session, no
/ masterClient.q and so no global `p`), and queries the result by
/ connecting to the server directly from this same process. Registration
/ is optimistic (cp is set before the client's `p` is queried)
/ specifically so a client that acts immediately after connecting - such
/ as staking straight away - isn't racing a slow round-trip to a client
/ that may not even be listening for it yet.

.tst.desc["regConn / unregDA / .z.po manual (bare) client registration (blackjackServer.q:35-40,74)"]{
  should["a manual client with no global `p` is registered in cp right away, with no wait for the p round-trip"]{
    / mix in the OS pid for extra entropy - .z.p alone has repeated when the
    / suite runs several times in quick succession.
    port:string 16001 + ((`int$(`long$.z.p) mod 1000) + (("I"$first system "echo $$") mod 1000));
    tag:"qsino_test_regconn_",port;
    srvLines:(
      "\\p ",port;
      "cp:()!()";
      "DA:0Ni";
      ".bs.tab:([]player:();name:();handle:())";
      "user:{`$string[.z.u],\"_\",string[.z.w]}";
      "regConn:{cp[x]:user[];x}";                                     / blackjackServer.q:35, verbatim
      "unregDA:{[x] pv:@[x;`p;`];if[`detectionAlgo=pv;DA::x;cp::x _cp;delete from `.bs.tab where handle=x];pv}";  / blackjackServer.q:36-40, verbatim
      ".z.po:{@[{h:regConn[.z.w];pv:unregDA[h]};();{}]}");             / blackjackServer.q:74, minus the intro-send and .bs.start
    (hsym `$"/tmp/",tag,"_srv.q") 0: srvLines;
    / a slow-to-respond manual client: connects, then immediately blocks in
    / a foreign call before it could ever service a sync `p` query - the
    / same shape as a human staking the instant they connect.
    clientLines:enlist "h:hopen `:localhost:",port,"; system \"sleep 3\"; exit 0";
    (hsym `$"/tmp/",tag,"_client.q") 0: clientLines;
    system "q /tmp/",tag,"_srv.q -q < /dev/null > /tmp/",tag,"_srv.log 2>&1 &";
    system "sleep 2";
    system "q /tmp/",tag,"_client.q -q < /dev/null > /tmp/",tag,"_client.log 2>&1 &";
    system "sleep 1";  / well before the slow client would ever answer the p query
    qh:hopen `$":localhost:",port;
    cpCount:qh"count cp";
    hclose qh;
    system "sleep 3";  / let the slow client's own process exit before cleanup
    pids:system "ps aux | grep ",tag,"_srv.q | grep -v grep | awk '{print $2}'";
    if[count pids; system "kill ",(" " sv pids)];
    cpCount musteq 1;
    };
 };
