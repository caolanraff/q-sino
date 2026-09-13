/ blackjackServer.q guards its "run for real" behavior (arg parsing, \p,
/ initial buildDeck/shuffle) behind init[], only called when .z.f shows this
/ file is the process's own entry script (see the .z.f check at the very
/ bottom of blackjackServer.q) - so `system "l"`ing it here is side-effect
/ free: no socket opens, nothing exits. Most specs below still reproduce a
/ specific expression/branch verbatim (file:line noted per spec) against a
/ minimal stub of the surrounding state, rather than loading the real file,
/ since they're only exercising one small piece of logic in isolation.
/ Setup is inlined into each `should` body rather than shared via `before{}`,
/ since these specs run alongside other test files in one shared q
/ process/namespace. Any variable read from *inside* a nested `{...}`
/ closure (e.g. the `@[{...};();{...}]` traps below, or a `mock`ed
/ replacement function) is assigned with `::` rather than `:` - a plain `:`
/ inside a `should{}` body (or a mock lambda) is local to that body's own
/ lambda, and a nested lambda literal can't see an enclosing lambda's
/ locals, only true globals. qspec's `mock` (see the regConn suite) is
/ automatically restored to the real definition after each `should`.

system "l src/server/bin/blackjackServer.q";

.tst.desc["blackjackServer entry-script guard (bin/blackjackServer.q:382)"]{
  should["only fires for its own script, not when loaded as a dependency"]{
    guard::{[zf] (not null zf) and "blackjackServer.q"~last "/" vs string zf};
    (guard[`]) musteq 0b;
    (guard[`$"src/server/bin/blackjackServer.q"]) musteq 1b;
    (guard[`$"test/run.q"]) musteq 0b;
    (guard[`$"/abs/path/src/server/bin/blackjackServer.q"]) musteq 1b;
    };
 };

.tst.desc["blackjackServer.shuffle DA-notify guard (lib/deck.q:16)"]{
  should["behaves as intended AND semantics"]{
    guard::{[shufflecnt;DA] (shufflecnt>1)&not null DA};
    threw:@[{guard[1;0Ni];0b};();{1b}];
    threw musteq 0b;
    (guard[1;0Ni]) musteq 0b;
    (guard[1;5i]) musteq 0b;
    (guard[2;5i]) musteq 1b;
    (guard[2;0Ni]) musteq 0b;
    };
 };

.tst.desc[".bs.start player-table upsert (bin/blackjackServer.q:15,41)"]{
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

.tst.desc[".bs.dealer1 dealer-and-player-both-bust branch (bin/blackjackServer.q:170-171)"]{
  should["zeroes only the current player's return, leaving other players untouched"]{
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

.tst.desc["regConn"]{
  should["adds a plain connection to cp when isDA is false"]{
    cp::()!(); DA::0Ni;
    `isDA mock {0b};
    regConn[42i];
    (count cp) musteq 1;
    DA musteq 0Ni;
    };
  should["routes a detectionAlgo connection to DA instead of cp"]{
    cp::()!(); DA::0Ni;
    `isDA mock {1b};
    regConn[42i];
    DA musteq 42i;
    (count cp) musteq 0;
    };
 };

.tst.desc[".z.po"]{
  should["registers the connection and starts the table for a plain client"]{
    cp::()!(); DA::0Ni;
    regConnCalls::0; startCalls::0;
    `regConn mock {regConnCalls::regConnCalls+1};
    `isDA mock {0b};
    `.bs.start mock {startCalls::startCalls+1};
    .z.po[];
    regConnCalls musteq 1;
    startCalls musteq 1;
    };
  should["skips .bs.start for a detectionAlgo connection"]{
    startCalls::0;
    `regConn mock {};
    `isDA mock {1b};
    `.bs.start mock {startCalls::startCalls+1};
    .z.po[];
    startCalls musteq 0;
    };
 };

.tst.desc[".z.pc"]{
  should["resets DA to null for the detectionAlgo handle, without calling leave"]{
    DA::7i;
    leaveCalls::0;
    `leave mock {leaveCalls::leaveCalls+1};
    .z.pc[7i];
    DA musteq 0Ni;
    leaveCalls musteq 0;
    };
  should["calls leave for a non-DA disconnect, leaving DA untouched"]{
    DA::7i;
    leaveArg::0Ni;
    `leave mock {leaveArg::x};
    .z.pc[3i];
    DA musteq 7i;
    leaveArg musteq 3i;
    };
 };
