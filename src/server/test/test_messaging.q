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
