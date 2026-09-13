.tst.desc["masterClient allow-list matches the players in lib/"]{
  should["every player strategy in lib/ is listed, spelled correctly, in masterClient.q's pt"]{
    / masterClient.q can't be safely `system "l"`ed (it hopen's a live
    / server); extract just the pt:... line instead.
    lines:read0 `:src/client/bin/masterClient.q;
    ptLine:first lines where lines like "pt:*";
    value ptLine;  / an assignment statement evaluates to (::); re-read the real global `pt` afterwards
    / lib/ also holds playerCore.q, which isn't a player strategy - exclude it.
    onDisk:asc `$-2 _/: string (key `:src/client/lib) except `playerCore.q;  / strip ".q"
    (asc pt) mustmatch onDisk;
    };
 };
