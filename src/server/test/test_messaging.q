system "l src/server/lib/messaging.q";

.tst.desc["lg"]{
  should["writes a single string to stdout without throwing"]{
    (.bs.lg["a single message"]) musteq -1i;
    };
  should["joins a list of strings into one line before logging"]{
    (.bs.lg[("prefix ";"suffix")]) musteq -1i;
    };
 };

.tst.desc["sendMsg"]{
  should["dispatches a string message to lg, not show, on a local handle"]{
    lgCalls::();
    `.bs.lg mock {[x] lgCalls,:enlist x};
    .bs.sendMsg["hello";0i];
    lgCalls mustmatch enlist "hello";
    };
  should["does not dispatch a non-string message to lg (goes to show instead)"]{
    lgCalls::();
    `.bs.lg mock {[x] lgCalls,:enlist x};
    .bs.sendMsg[42;0i];
    lgCalls mustmatch ();
    };
  should["targets only the first handle when given a list of handles"]{
    lgCalls::();
    `.bs.lg mock {[x] lgCalls,:enlist x};
    .bs.sendMsg["hi";0 1i];
    lgCalls mustmatch enlist "hi";
    };
 };

.tst.desc["pubMsg"]{
  should["logs once locally and calls sendMsg once per handle in the target list"]{
    lgCalls::0;
    `.bs.lg mock {[x] lgCalls+::1};
    sendCalls::();
    `.bs.sendMsg mock {[x;y] sendCalls,:y};
    .bs.pubMsg["hi";0 1 2i];
    lgCalls musteq 1;
    sendCalls musteq 0 1 2i;
    };
 };

.tst.desc["excFunc"]{
  should["evaluates the named function with y on the target handle"]{
    lgCalls::();
    `.bs.lg mock {[x] lgCalls,:enlist x};
    .bs.excFunc[`.bs.lg;"probed";0i];
    lgCalls mustmatch enlist "probed";
    };
 };

.tst.desc["user"]{
  should["combines .z.u and .z.w into a single underscore-joined symbol"]{
    (.bs.user[]) musteq `$string[.z.u],"_",string[.z.w];
    };
 };

.tst.desc["isDA"]{
  should["is false for a connection not authenticated as detectionAlgo"]{
    .bs.isDA[] musteq 0b;
    };
 };

.tst.desc[".bs.trigger"]{
  should["sends the client its table, the shoe's results and its own handle with the trigger"]{
    sent::();
    `.bs.excFunc mock {[x;y;z] sent,:enlist(x;y;z)};
    .bs.tab:([]round:enlist 3;player:enlist 1f;handle:enlist 7i;cards:enlist`K`5);
    .bs.res:([]round:1 2;handle:7 7i;profit:10 -10f);
    .bs.trigger[`.mc.play;7i];
    (first sent 0) musteq `.mc.play;
    (last sent 0) musteq 7i;
    (sent[0;1]`tab) mustmatch .bs.tab;
    (sent[0;1]`res) mustmatch .bs.res;
    (sent[0;1]`me) musteq 7i;
    };
 };

.tst.desc[".bs.clientState rules"]{
  should["tells the client whether the table offers surrender"]{
    .bs.tab:([]round:enlist 1;handle:enlist 7i); .bs.res:([]round:0#0);
    .bs.rules[`surrender]:1b;
    ((.bs.clientState 7i)[`rules]`surrender) musteq 1b;
    .bs.rules[`surrender]:0b;
    ((.bs.clientState 7i)[`rules]`surrender) musteq 0b;
    .bs.rules[`surrender]:1b;
    };
 };
