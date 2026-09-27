system"l src/server/lib/messaging.q";

.tst.desc[".bjk.lg"]{
  should["writes a single string to stdout without throwing"]{
    .bjk.lg["a single message"] musteq -1i;
  };
  should["joins a list of strings into one line before logging"]{
    .bjk.lg[("prefix ";"suffix")] musteq -1i;
  };
 };

.tst.desc[".bjk.sendMsg"]{
  should["dispatches a string message to lg, not show, on a local handle"]{
    .tst.lgCalls:();
    `.bjk.lg mock {[x].tst.lgCalls,:enlist x};
    .bjk.sendMsg["hello";0i];
    .tst.lgCalls mustmatch enlist"hello";
  };
  should["does not dispatch a non-string message to lg (goes to show instead)"]{
    .tst.lgCalls:();
    `.bjk.lg mock {[x].tst.lgCalls,:enlist x};
    .bjk.sendMsg[42;0i];
    .tst.lgCalls mustmatch();
  };
  should["targets only the first handle when given a list of handles"]{
    .tst.lgCalls:();
    `.bjk.lg mock {[x].tst.lgCalls,:enlist x};
    .bjk.sendMsg["hi";0 1i];
    .tst.lgCalls mustmatch enlist"hi";
  };
  should["logs instead of throwing when the handle can't be written to"]{
    .tst.lgCalls:();
    `.bjk.lg mock {[x].tst.lgCalls,:enlist x};
    .bjk.sendMsg["hi";999i];
    count[.tst.lgCalls] musteq 1;
    first[.tst.lgCalls] mustlike "Couldn't send a message: *";
  };
 };

.tst.desc[".bjk.pubMsg"]{
  should["logs once locally and calls sendMsg once per handle in the target list"]{
    .tst.lgCalls:0;
    `.bjk.lg mock {[x].tst.lgCalls+:1};
    .tst.sendCalls:();
    `.bjk.sendMsg mock {[x;y].tst.sendCalls,:y};
    .bjk.pubMsg["hi";0 1 2i];
    .tst.lgCalls musteq 1;
    .tst.sendCalls musteq 0 1 2i;
  };
 };

.tst.desc[".bjk.excFunc"]{
  should["evaluates the named function with its argument on the target handle"]{
    .tst.lgCalls:();
    `.bjk.lg mock {[x].tst.lgCalls,:enlist x};
    .bjk.excFunc[`.bjk.lg;"probed";0i];
    .tst.lgCalls mustmatch enlist"probed";
  };
  should["logs instead of throwing when the handle can't be written to"]{
    .tst.lgCalls:();
    `.bjk.lg mock {[x].tst.lgCalls,:enlist x};
    .bjk.excFunc[`.plr.play;`;999i];
    first[.tst.lgCalls] mustlike "Couldn't send a trigger: *";
  };
 };

.tst.desc[".bjk.user"]{
  should["combines .z.u and .z.w into a single underscore-joined symbol"]{
    .bjk.user[] musteq`$string[.z.u],"_",string .z.w;
  };
 };

.tst.desc[".bjk.isPit"]{
  should["is false for a connection not authenticated as pitboss"]{
    .bjk.isPit[] musteq 0b;
  };
 };

.tst.desc[".bjk.trigger"]{
  should["sends the client its table, the shoe's results and its own handle with the trigger"]{
    .tst.sent:();
    `.bjk.excFunc mock {[x;y;z].tst.sent,:enlist(x;y;z)};
    .bjk.tab:([]round:enlist 3;player:enlist 1f;handle:enlist 7i;cards:enlist`K`5);
    .bjk.res:([]round:1 2;handle:7 7i;profit:10 -10f);
    .bjk.rules:`maxSplitHands`deckCnt!4 6;
    .bjk.trigger[`.plr.play;7i];
    .tst.sent[0;0] musteq`.plr.play;
    .tst.sent[0;2] musteq 7i;
    .tst.sent[0;1;`tab] mustmatch .bjk.tab;
    .tst.sent[0;1;`res] mustmatch .bjk.res;
    .tst.sent[0;1;`me] musteq 7i;
    .tst.sent[0;1;`rules] mustmatch`maxSplitHands`deckCnt!4 6;
  };
 };

