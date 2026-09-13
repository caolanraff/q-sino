/ blackjackServer.q opens a real listening socket, so it can't be
/ `system "l"`ed directly in a unit test. Its `-port` flag lets specs below
/ spawn the real file as a subprocess on an ephemeral port instead and talk
/ to it over real IPC (the startup and regConn specs). Where a spec only
/ needs one specific expression/branch, it instead reproduces that snippet
/ verbatim (file:line noted per spec), against a minimal stub of the
/ surrounding state. Setup is inlined into each `should` body rather than
/ shared via `before{}`, since these specs run alongside other test files in
/ one shared q process/namespace. Any variable read from *inside* a nested
/ `{...}` closure (e.g. the `@[{...};();{...}]` traps below) is assigned
/ with `::` rather than `:` - a plain `:` inside a `should{}` body is local
/ to that body's own lambda, and a nested lambda literal can't see an
/ enclosing lambda's locals, only true globals.

.tst.desc["blackjackServer startup"]{
  should["the real server process is reachable a moment after launch, on the port it was given"]{
    port:string 16001 + ((`int$(`long$.z.p) mod 1000) + (("I"$first system "echo $$") mod 1000));
    system "q src/server/bin/blackjackServer.q -gameplay manual -port ",port," -q < /dev/null > /tmp/qsino_test_startup_",port,".log 2>&1 &";
    system "sleep 2";
    h:@[hopen;`$":localhost:",port;{0Ni}];
    reachable:not null h;
    if[reachable;hclose h];
    pids:system "ps aux | grep 'blackjackServer.q.*-port ",port,"' | grep -v grep | awk '{print $2}'";
    if[count pids; system "kill ",(" " sv pids)];
    reachable musteq 1b;
    };
 };

.tst.desc["blackjackServer.shuffle DA-notify guard (lib/deck.q:17)"]{
  should["behaves as intended AND semantics"]{
    / lib/deck.q:17: if[(shufflecnt>1)&not null DA;excFunc[`shuffle;`;DA]];
    guard::{[shufflecnt;DA] (shufflecnt>1)&not null DA};
    threw:@[{guard[1;0Ni];0b};();{1b}];
    threw musteq 0b;
    (guard[1;0Ni]) musteq 0b;
    (guard[1;5i]) musteq 0b;
    (guard[2;5i]) musteq 1b;
    (guard[2;0Ni]) musteq 0b;
    };
 };

.tst.desc[".bs.start player-table upsert (bin/blackjackServer.q:26,55)"]{
  should["succeeds for exactly one connected player"]{
    .bs.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!();
    cp::enlist[5i]!enlist`alice;
    threw:@[{`.bs.tab upsert ([]player:1+til count cp;name:value cp;handle:key cp);0b};();{1b}];
    threw musteq 0b;
    (count .bs.tab) musteq 1;
    };
  should["succeeds for two connected players"]{
    .bs.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!();
    cp::(5i;6i)!`alice`bob;
    threw:@[{`.bs.tab upsert ([]player:1+til count cp;name:value cp;handle:key cp);0b};();{1b}];
    threw musteq 0b;
    (count .bs.tab) musteq 2;
    (asc exec name from .bs.tab) musteq `alice`bob;
    };
 };

.tst.desc[".bs.dealer1 dealer-and-player-both-bust branch (bin/blackjackServer.q:185-186)"]{
  should["zeroes only the current player's return, leaving other players untouched"]{
    / bin/blackjackServer.q:186, copied verbatim.
    .bs.tab:([]player:1 2f;name:`p1`p2;handle:10 11i;cnt:25 24i;return:250f,0n);
    DCount:24;  / dealer also busted (>21) in this scenario
    p:2f;
    ucnt:first exec cnt from .bs.tab where player=p;
    if[DCount>21;
      $[ucnt<=21;
        [1];
        [update return:0f from `.bs.tab where player=p]]];
    (exec first return from .bs.tab where player=2) musteq 0f;
    (exec first return from .bs.tab where player=1) musteq 250f;
    };
 };

.tst.desc["regConn / .z.po / .z.pc connection-identity handling (spawns the real bin/blackjackServer.q)"]{
  should["a plain client is registered into cp right away"]{
    port:string 16101 + ((`int$(`long$.z.p) mod 1000) + (("I"$first system "echo $$") mod 1000));
    system "q src/server/bin/blackjackServer.q -gameplay manual -port ",port," -q < /dev/null > /tmp/qsino_test_regconn_plain_",port,".log 2>&1 &";
    system "sleep 2";
    h:hopen `$":localhost:",port;
    qh:hopen `$":localhost:",port;
    cpCount:qh"count cp";
    hclose h; hclose qh;
    pids:system "ps aux | grep 'blackjackServer.q.*-port ",port,"' | grep -v grep | awk '{print $2}'";
    if[count pids; system "kill ",(" " sv pids)];
    cpCount musteq 2;
    };
  should["a client connecting as detectionAlgo becomes DA and is never added to cp"]{
    port:string 16201 + ((`int$(`long$.z.p) mod 1000) + (("I"$first system "echo $$") mod 1000));
    system "q src/server/bin/blackjackServer.q -gameplay manual -port ",port," -q < /dev/null > /tmp/qsino_test_regconn_da_",port,".log 2>&1 &";
    system "sleep 2";
    h:hopen `$":localhost:",port,":detectionAlgo";
    qh:hopen `$":localhost:",port;
    daIsSet:not null qh"DA";
    cpCount:qh"count cp";
    hclose h; hclose qh;
    pids:system "ps aux | grep 'blackjackServer.q.*-port ",port,"' | grep -v grep | awk '{print $2}'";
    if[count pids; system "kill ",(" " sv pids)];
    daIsSet musteq 1b;
    cpCount musteq 1;  / only qh (the plain query connection); the DA handle never joins cp
    };
  should["DA resets to null when the detectionAlgo connection closes, without touching cp"]{
    port:string 16301 + ((`int$(`long$.z.p) mod 1000) + (("I"$first system "echo $$") mod 1000));
    system "q src/server/bin/blackjackServer.q -gameplay manual -port ",port," -q < /dev/null > /tmp/qsino_test_regconn_pc_",port,".log 2>&1 &";
    system "sleep 2";
    qh:hopen `$":localhost:",port;
    hDA:hopen `$":localhost:",port,":detectionAlgo";
    cpCountBeforeClose:qh"count cp";
    hclose hDA;
    system "sleep 1";
    daAfterClose:qh"DA";
    cpCountAfterClose:qh"count cp";
    hclose qh;
    pids:system "ps aux | grep 'blackjackServer.q.*-port ",port,"' | grep -v grep | awk '{print $2}'";
    if[count pids; system "kill ",(" " sv pids)];
    cpCountBeforeClose musteq 1;  / just qh; the DA handle never joined cp
    daAfterClose musteq 0Ni;
    cpCountAfterClose musteq 1;  / qh untouched by the DA's disconnect
    };
 };
