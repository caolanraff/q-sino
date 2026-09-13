.tst.desc["masterClient allow-list matches the players in lib/"]{
  should["every player strategy in lib/ is listed, spelled correctly, in masterClient.q's pt"]{
    / masterClient.q calls exit on bad args and blocks on a live hopen, so
    / it can't be `system "l"`ed in-process. Run it for real with no
    / -player instead - it prints its pt allow-list to stdout and exits
    / before ever attempting to connect.
    tag:"qsino_test_masterclient_pt_",first system "echo $$";
    system "q src/client/bin/masterClient.q -q < /dev/null > /tmp/",tag,".log 2>&1";
    system "sleep 1";
    out:read0 `$"/tmp/",tag,".log";
    errLine:first out where out like "*Missing player*";
    rest:last ("options - " vs errLine);
    rest:$[last rest="\"";-1_rest;rest];
    pt:`$"," vs rest;
    onDisk:asc `$-2 _/: string (key `:src/client/lib) except `playerCore.q;  / strip ".q"
    (asc pt) mustmatch onDisk;
    };
 };
