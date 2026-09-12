/ playerCore.q and the players/*.q strategy files have no network/side
/ effects at load time, so they're safe to `system "l"` directly.
system "l src/client/playerCore.q";

.tst.desc["avgPlayer strategies ace handling"]{

  should["confirms review finding: avgPlayer1 never treats aces as soft - A,9,5 is a hittable soft 15 but is scored/played as a 25"]{
    / avgPlayer1.q's Help always scores an ace as 11 and never reduces it,
    / so A,9,5 (true soft value 1+9+5=15, should Hit) is scored as
    / 11+9+5=25 and wrongly recommended to Stick.
    system "l src/client/players/avgPlayer1.q";
    Help[`A`9`5`2] musteq `S;
    };

  should["confirms review finding: avgPlayer2 has the same ace bug"]{
    system "l src/client/players/avgPlayer2.q";
    Help[`A`9`5`2] musteq `S;
    };

  should["confirms review finding: avgPlayer3 has the same ace bug"]{
    system "l src/client/players/avgPlayer3.q";
    Help[`A`9`5`2] musteq `S;
    };

  should["sanity: avgPlayer1 still correctly hits a plain hard 12"]{
    system "l src/client/players/avgPlayer1.q";
    Help[`10`2`10] musteq `H;
    };

 };

.tst.desc["masterClient allow-list matches the players directory"]{

  should["confirms review finding: pt typo blocks a real strategy - masterClient.q's pt does not match the players/ directory on disk"]{
    / masterClient.q itself can't be safely `system "l"`ed in a unit test:
    / it ends by hopen-ing a live server and calling exit[1] if none is
    / found. Extract just the `pt:...` declaration line instead, so the
    / real (un-retyped) source text is what gets checked.
    lines:read0 `:src/client/masterClient.q;
    ptLine:first lines where lines like "pt:*";
    value ptLine;  / assignment statements evaluate to (::); re-read the real global `pt` afterwards

    onDisk:asc `$-2 _/: string key `:src/client/players;  / strip ".q"

    (asc pt) mustnmatch onDisk;
    };

 };
