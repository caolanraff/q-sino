/ playerCore.q and the players/*.q strategy files have no network/side
/ effects at load time, so they're safe to `system "l"` directly.
system "l src/client/playerCore.q";

.tst.desc["avgPlayer strategies ace handling"]{
  should["avgPlayer1: A,9,5 is a hittable soft 15, not a bust"]{
    system "l src/client/players/avgPlayer1.q";
    Help[`A`9`5`2] musteq `H;
    };
  should["avgPlayer2: A,9,5 is a hittable soft 15, not a bust"]{
    system "l src/client/players/avgPlayer2.q";
    Help[`A`9`5`2] musteq `H;
    };
  should["avgPlayer3: A,9,5 is a hittable soft 15, not a bust"]{
    system "l src/client/players/avgPlayer3.q";
    Help[`A`9`5`2] musteq `H;
    };
  should["avgPlayer1 still correctly hits a plain hard 12"]{
    system "l src/client/players/avgPlayer1.q";
    Help[`10`2`10] musteq `H;
    };
 };

.tst.desc["masterClient allow-list matches the players directory"]{
  should["every players/*.q strategy is listed, spelled correctly, in masterClient.q's pt"]{
    / masterClient.q can't be safely `system "l"`ed (it hopen's a live
    / server); extract just the pt:... line instead.
    lines:read0 `:src/client/masterClient.q;
    ptLine:first lines where lines like "pt:*";
    value ptLine;  / an assignment statement evaluates to (::); re-read the real global `pt` afterwards
    onDisk:asc `$-2 _/: string key `:src/client/players;  / strip ".q"
    (asc pt) mustmatch onDisk;
    };
 };
