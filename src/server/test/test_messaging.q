system"l src/server/lib/messaging.q";

.tst.desc[".bs.lg"]{
  should["writes a single string to stdout without throwing"]{
    .bs.lg["a single message"] musteq -1i;
  };
  should["joins a list of strings into one line before logging"]{
    .bs.lg[("prefix ";"suffix")] musteq -1i;
  };
 };

.tst.desc[".bs.sendMsg"]{
  should["dispatches a string message to lg, not show, on a local handle"]{
    .tst.lgCalls:();
    `.bs.lg mock {[x].tst.lgCalls,:enlist x};
    .bs.sendMsg["hello";0i];
    .tst.lgCalls mustmatch enlist"hello";
  };
  should["does not dispatch a non-string message to lg (goes to show instead)"]{
    .tst.lgCalls:();
    `.bs.lg mock {[x].tst.lgCalls,:enlist x};
    .bs.sendMsg[42;0i];
    .tst.lgCalls mustmatch();
  };
  should["targets only the first handle when given a list of handles"]{
    .tst.lgCalls:();
    `.bs.lg mock {[x].tst.lgCalls,:enlist x};
    .bs.sendMsg["hi";0 1i];
    .tst.lgCalls mustmatch enlist"hi";
  };
  should["logs instead of throwing when the handle can't be written to"]{
    .tst.lgCalls:();
    `.bs.lg mock {[x].tst.lgCalls,:enlist x};
    .bs.sendMsg["hi";999i];
    count[.tst.lgCalls] musteq 1;
    first[.tst.lgCalls] mustlike "Couldn't send a message: *";
  };
 };

.tst.desc[".bs.pubMsg"]{
  should["logs once locally and calls sendMsg once per handle in the target list"]{
    .tst.lgCalls:0;
    `.bs.lg mock {[x].tst.lgCalls+:1};
    .tst.sendCalls:();
    `.bs.sendMsg mock {[x;y].tst.sendCalls,:y};
    .bs.pubMsg["hi";0 1 2i];
    .tst.lgCalls musteq 1;
    .tst.sendCalls musteq 0 1 2i;
  };
 };

.tst.desc[".bs.excFunc"]{
  should["evaluates the named function with its argument on the target handle"]{
    .tst.lgCalls:();
    `.bs.lg mock {[x].tst.lgCalls,:enlist x};
    .bs.excFunc[`.bs.lg;"probed";0i];
    .tst.lgCalls mustmatch enlist"probed";
  };
  should["logs instead of throwing when the handle can't be written to"]{
    .tst.lgCalls:();
    `.bs.lg mock {[x].tst.lgCalls,:enlist x};
    .bs.excFunc[`.mc.play;`;999i];
    first[.tst.lgCalls] mustlike "Couldn't send a trigger: *";
  };
 };

.tst.desc[".bs.user"]{
  should["combines .z.u and .z.w into a single underscore-joined symbol"]{
    .bs.user[] musteq`$string[.z.u],"_",string .z.w;
  };
 };

.tst.desc[".bs.isDA"]{
  should["is false for a connection not authenticated as detectionAlgo"]{
    .bs.isDA[] musteq 0b;
  };
 };

.tst.desc[".bs.trigger"]{
  should["sends the client its table, the shoe's results and its own handle with the trigger"]{
    .tst.sent:();
    `.bs.excFunc mock {[x;y;z].tst.sent,:enlist(x;y;z)};
    .bs.tab:([]round:enlist 3;player:enlist 1f;handle:enlist 7i;cards:enlist`K`5);
    .bs.res:([]round:1 2;handle:7 7i;profit:10 -10f);
    .bs.trigger[`.mc.play;7i];
    .tst.sent[0;0] musteq`.mc.play;
    .tst.sent[0;2] musteq 7i;
    .tst.sent[0;1;`tab] mustmatch .bs.tab;
    .tst.sent[0;1;`res] mustmatch .bs.res;
    .tst.sent[0;1;`me] musteq 7i;
  };
 };
