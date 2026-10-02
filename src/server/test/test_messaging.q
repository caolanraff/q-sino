.utl.load`:src/server/lib/messaging.q;

.tst.desc[".bjk.display"]{
  should["prints a string message as-is, with no timestamp or level"]{
    .bjk.display["hello"] mustmatch(-1;"hello");
  };
  should["shows anything else, such as a table"]{
    .bjk.display[42] mustmatch(show;42);
  };
 };

.tst.desc[".bjk.sendMsg"]{
  before{
    .tst.lgCalls:();
  };
  should["sends the message, indented, to the handle to be displayed there"]{
    .tst.rec:{.tst.lgCalls,:enlist x};
    `.bjk.display mock {[msg](`.tst.rec;msg)};
    .bjk.sendMsg["hello";0i];
    .tst.lgCalls mustmatch enlist"  hello";
  };
  should["targets only the first handle when given a list of handles"]{
    .tst.rec:{.tst.lgCalls,:enlist x};
    `.bjk.display mock {[msg](`.tst.rec;msg)};
    .bjk.sendMsg["hi";0 1i];
    .tst.lgCalls mustmatch enlist"  hi";
  };
  should["logs instead of throwing when the handle can't be written to"]{
    `.log.warn mock {.tst.lgCalls,:enlist x};
    .bjk.sendMsg["hi";999i];
    count[.tst.lgCalls] musteq 1;
    first[.tst.lgCalls] mustlike "Couldn't send a message: *";
  };
 };

.tst.desc[".bjk.prompt"]{
  should["sends the message flush left, for the player to answer"]{
    .tst.lgCalls:();
    .tst.rec:{.tst.lgCalls,:enlist x};
    `.bjk.display mock {[msg](`.tst.rec;msg)};
    .bjk.prompt["Hit or stick?";0i];
    .tst.lgCalls mustmatch enlist"Hit or stick?";
  };
 };

.tst.desc[".bjk.indent"]{
  should["indents every line of a string by two spaces"]{
    .bjk.indent["one\ntwo"] mustmatch "  one\n  two";
  };
  should["renders anything else as text first, then indents it"]{
    .bjk.indent[([]a:1 2)] mustmatch "  a\n  -\n  1\n  2";
  };
 };

.tst.desc[".bjk.banner"]{
  should["frames a heading"]{
    .bjk.banner["Hand 3"] mustmatch "~~~~~~~~~~~~ Hand 3 ~~~~~~~~~~~~";
  };
 };

.tst.desc[".bjk.pubMsg"]{
  should["logs once locally and calls sendMsg once per handle in the target list"]{
    .tst.lgCalls:0;
    `.log.info mock {.tst.lgCalls+:1};
    .tst.sendCalls:();
    `.bjk.sendMsg mock {.tst.sendCalls,:y};
    .bjk.pubMsg["hi";0 1 2i];
    .tst.lgCalls musteq 1;
    .tst.sendCalls musteq 0 1 2i;
  };
 };

.tst.desc[".bjk.excFunc"]{
  before{
    .tst.lgCalls:();
  };
  should["evaluates the named function with its argument on the target handle"]{
    `.log.info mock {.tst.lgCalls,:enlist x};
    .bjk.excFunc[`.log.info;"probed";0i];
    .tst.lgCalls mustmatch enlist"probed";
  };
  should["logs instead of throwing when the handle can't be written to"]{
    `.log.warn mock {.tst.lgCalls,:enlist x};
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
    `.bjk.excFunc mock {.tst.sent,:enlist(x;y;z)};
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

