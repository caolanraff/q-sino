/ masterClient.q guards its connect-on-load behavior behind init[], only run
/ when the file is the process's own entry script (see the .z.f check at the
/ bottom of masterClient.q) - so `system "l"`ing it here is side-effect-free
/ and pt can be read directly.
system "l src/client/bin/masterClient.q";

.tst.desc["masterClient allow-list matches the players in lib/"]{
  should["every player strategy in lib/ is listed, spelled correctly, in masterClient.q's pt"]{
    onDisk:asc `$-2 _/: string (key `:src/client/lib) except `playerCore.q;  / strip ".q"
    (asc pt) mustmatch onDisk;
    };
 };
