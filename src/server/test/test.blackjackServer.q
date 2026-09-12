/ blackjackServer.q can't be `system "l"`ed directly in a unit test: it
/ opens a real listening socket and, per the first spec below, currently
/ crashes on load. Each spec instead reproduces the exact expression/branch
/ under test, copied verbatim from the real source (file:line noted per
/ spec), against a minimal stub of the surrounding state. Setup is inlined
/ into each `should` body rather than shared via `before{}`, since these
/ specs run alongside other test files in one shared q process/namespace.
/ Any variable read from *inside* a nested `{...}` closure (e.g. the
/ `@[{...};();{...}]` error traps below) is assigned with `::` rather than
/ `:` - a plain `:` inside a `should{}` body is local to that body's own
/ lambda, and a nested lambda literal can't see an enclosing lambda's
/ locals, only true globals.

.tst.desc["blackjackServer startup"]{
  should["confirms review finding: the real server process crashes on every startup and is not reachable a moment after launch"]{
    / blackjackServer.q:412 calls shuffle[] unconditionally at the end of
    / the script; its DA-notify guard (line 91, below) always throws, and an
    / uncaught error during a script's top-level load kills the process.
    / This spec currently PASSES (confirming the crash); once fixed, flip
    / the assertion to expect `pids` to be non-empty instead.
    port:string 16000 + `int$(`long$.z.p) mod 3000; / a throwaway port per run, to dodge collisions
    tag:"qsino_test_bjs_",port;
    system "cp src/server/blackjackServer.q /tmp/",tag,".q";
    system "q /tmp/",tag,".q -gameplay manual -hands 1 -p ",port," -q < /dev/null > /tmp/",tag,".log 2>&1 &";
    system "sleep 2";
    pids:system "ps aux | grep ",tag,".q | grep -v grep | awk '{print $2}'";
    if[count pids; system "kill ",(" " sv pids)];  / clean up if the bug is ever fixed and it's actually alive
    (count pids) musteq 0;
    };
 };

.tst.desc["blackjackServer.shuffle DA-notify guard ($ vs &, blackjackServer.q:91)"]{
  should["confirms review finding: $ between two booleans always throws instead of behaving as logical AND"]{
    / blackjackServer.q:91: if[(shufflecnt>1)$not null DA;excFunc[`shuffle;`;DA]];
    / `$` between two booleans is Cast, not And - it should be `&`.
    guard::{[shufflecnt;DA] (shufflecnt>1)$not null DA};
    threw:@[{guard[1;0Ni];0b};();{1b}];
    threw musteq 1b;
    };
  should["once fixed to &, behaves as intended AND semantics"]{
    fixed:{[shufflecnt;DA] (shufflecnt>1)&not null DA};
    (fixed[1;0Ni]) musteq 0b;
    (fixed[1;5i]) musteq 0b;
    (fixed[2;5i]) musteq 1b;
    (fixed[2;0Ni]) musteq 0b;
    };
 };

.tst.desc[".bs.start player-table upsert (blackjackServer.q:26,59)"]{
  should["succeeds for exactly one connected player"]{
    .bs.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!();
    cp:enlist[5i]!enlist`alice;
    upd::`player`name`handle!(1+til count cp;value cp;key cp);
    threw:@[{![1#0#.bs.tab;();0b;upd];0b};();{1b}];
    threw musteq 0b;
    };
  should["confirms review finding: throws for two connected players"]{
    .bs.tab:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!();
    cp:(5i;6i)!`alice`bob;
    upd::`player`name`handle!(1+til count cp;value cp;key cp);
    threw:@[{![1#0#.bs.tab;();0b;upd];0b};();{1b}];
    threw musteq 1b;
    };
 };

.tst.desc[".bs.dealer1 dealer-and-player-both-bust branch (blackjackServer.q:216-217)"]{
  should["confirms review finding: missing backtick means the busted player's return is never actually set (stays null, not 0)"]{
    / blackjackServer.q:217, copied verbatim - note the missing backtick
    / before .bs.tab (every sibling branch elsewhere in .bs.dealer1 has
    / `.bs.tab): `from .bs.tab` queries the table value and returns a new
    / table that's discarded here, rather than updating .bs.tab in place.
    .bs.tab:([]player:1 2f;name:`p1`p2;handle:10 11i;cnt:25 24i;return:250f,0n);
    DCount:24;  / dealer also busted (>21) in this scenario
    p:2f;
    ucnt:first exec cnt from .bs.tab where player=p;
    if[DCount>21;
      $[ucnt<=21;
        [1];
        [update return:0f from .bs.tab]]];
    (exec first return from .bs.tab where player=2) musteq 0n;
    };
  should["once the backtick is added, correctly zeroes the busted player's return"]{
    .bs.tab:([]player:1 2f;name:`p1`p2;handle:10 11i;cnt:25 24i;return:250f,0n);
    DCount:24;
    p:2f;
    ucnt:first exec cnt from .bs.tab where player=p;
    if[DCount>21;
      $[ucnt<=21;
        [1];
        [update return:0f from `.bs.tab]]];  / fixed
    (exec first return from .bs.tab where player=2) musteq 0f;
    };
 };
