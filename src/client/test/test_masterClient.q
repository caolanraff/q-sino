system "l src/client/bin/masterClient.q";

.tst.desc["masterClient allow-list matches the players in lib/"]{
  should["every player strategy in lib/ is listed, spelled correctly, in masterClient.q's pt"]{
    onDisk:asc `$-2 _/: string (key `:src/client/lib) except `playerCore.q;  / strip ".q"
    (asc pt) mustmatch onDisk;
    };
 };
