.utl.load`:src/common/lib/util.q;

.tst.desc[".util.run"]{
  should["calls init when the named file is the process's entry script, however it was launched"]{
    .tst.runs:0;
    .tst.init:{.tst.runs+:1};
    `.util.script mock {`$"src/server/bin/blackjack.q"};
    .util.run[`blackjack.q;`.tst.init];
    `.util.script mock {`$"/abs/path/src/server/bin/blackjack.q"};
    .util.run[`blackjack.q;`.tst.init];
    `.util.script mock {`blackjack.q};
    .util.run[`blackjack.q;`.tst.init];
    .tst.runs musteq 3;
  };
  should["doesn't call init for another script, such as the test runner"]{
    .tst.runs:0;
    .tst.init:{.tst.runs+:1};
    `.util.script mock {`$"test/run.q"};
    .util.run[`blackjack.q;`.tst.init];
    .tst.runs musteq 0;
  };
  should["doesn't call init when the file is only loaded, with no entry script"]{
    .tst.runs:0;
    .tst.init:{.tst.runs+:1};
    `.util.script mock {`};
    .util.run[`blackjack.q;`.tst.init];
    .tst.runs musteq 0;
  };
 };

.tst.desc[".util.clist"]{
  should["joins symbols into a comma-separated string"]{
    .util.clist[`stake`hit`stick] musteq "stake, hit, stick";
    .util.clist[enlist`hit] musteq "hit";
  };
 };
