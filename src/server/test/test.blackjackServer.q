/ blackjackServer.q can't be `system "l"`ed directly in a unit test: it
/ opens a real listening socket. Most specs instead reproduce the exact
/ expression/branch under test, copied verbatim from the real source
/ (file:line noted per spec), against a minimal stub of the surrounding
/ state. Setup is inlined into each `should` body rather than shared via
/ `before{}`, since these specs run alongside other test files in one
/ shared q process/namespace. Any variable read from *inside* a nested
/ `{...}` closure (e.g. the `@[{...};();{...}]` traps below) is assigned
/ with `::` rather than `:` - a plain `:` inside a `should{}` body is local
/ to that body's own lambda, and a nested lambda literal can't see an
/ enclosing lambda's locals, only true globals.

.tst.desc["blackjackServer startup"]{
  should["the real server process is reachable a moment after launch"]{
    / blackjackServer.q hardcodes \p 5555, so this needs port 5555 free.
    system "pkill -f blackjackServer.q 2>/dev/null; sleep 1";
    system "q src/server/blackjackServer.q -gameplay manual -hands 1 -q < /dev/null > /tmp/qsino_test_bjs.log 2>&1 &";
    system "sleep 2";
    pids:system "ps aux | grep blackjackServer.q | grep -v grep | awk '{print $2}'";
    (count pids) mustgt 0;
    system "pkill -f blackjackServer.q 2>/dev/null";
    };
 };

.tst.desc["blackjackServer.shuffle DA-notify guard (blackjackServer.q:91)"]{
  should["behaves as intended AND semantics"]{
    / blackjackServer.q:91: if[(shufflecnt>1)&not null DA;excFunc[`shuffle;`;DA]];
    guard::{[shufflecnt;DA] (shufflecnt>1)&not null DA};
    threw:@[{guard[1;0Ni];0b};();{1b}];
    threw musteq 0b;
    (guard[1;0Ni]) musteq 0b;
    (guard[1;5i]) musteq 0b;
    (guard[2;5i]) musteq 1b;
    (guard[2;0Ni]) musteq 0b;
    };
 };

.tst.desc[".bs.start player-table upsert (blackjackServer.q:26,59)"]{
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

.tst.desc[".bs.dealer1 dealer-and-player-both-bust branch (blackjackServer.q:216-217)"]{
  should["zeroes only the current player's return, leaving other players untouched"]{
    / blackjackServer.q:217, copied verbatim.
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
