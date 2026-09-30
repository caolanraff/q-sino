.utl.load`:src/common/lib/util.q;

.tst.desc[".cmn.isMain"]{
  should["is true when the named file is the process's entry script, however it was launched"]{
    `.cmn.script mock {`$"src/server/bin/blackjack.q"};
    .cmn.isMain[`blackjack.q] musteq 1b;
    `.cmn.script mock {`$"/abs/path/src/server/bin/blackjack.q"};
    .cmn.isMain[`blackjack.q] musteq 1b;
    `.cmn.script mock {`blackjack.q};
    .cmn.isMain[`blackjack.q] musteq 1b;
  };
  should["is false for another script, such as the test runner"]{
    `.cmn.script mock {`$"test/run.q"};
    .cmn.isMain[`blackjack.q] musteq 0b;
  };
  should["is false when the file is only loaded, with no entry script"]{
    `.cmn.script mock {`};
    .cmn.isMain[`blackjack.q] musteq 0b;
  };
 };
