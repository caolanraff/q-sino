.utl.load`:src/common/lib/log.q;

.tst.desc[".log.info"]{
  should["writes a single string to stdout"]{
    .log.info["a single message"] musteq -1i;
  };
  should["joins a list of strings into one line before logging"]{
    .log.info[("prefix ";"suffix")] musteq -1i;
  };
 };

.tst.desc[".log.warn and .log.error"]{
  should["write to stderr"]{
    .log.warn["careful"] musteq -2i;
    .log.error["broken"] musteq -2i;
  };
 };

.tst.desc[".log.plain"]{
  should["writes to stdout with no level, for what players see"]{
    (value[.log.plain]1 2)mustmatch(-1;"");
  };
  should["leaves just the time before the message"]{
    .tst.line:"";
    .log.msg[{.tst.line:x};value[.log.plain]2;"Your card is 5"];
    .tst.line mustlike"20[0-9][0-9].[0-9][0-9].[0-9][0-9] [0-9][0-9]:[0-9][0-9]:[0-9.]* Your card is 5";
  };
 };

.tst.desc[".log.msg"]{
  should["stamps the line with the time and level"]{
    .tst.line:"";
    .log.msg[{.tst.line:x};"INFO ";("Shuffling";" the deck")];
    .tst.line mustlike"20[0-9][0-9].[0-9][0-9].[0-9][0-9] [0-9][0-9]:[0-9][0-9]:*INFO Shuffling the deck";
  };
  should["still works when sent by value to a process without .log, as the server does to players"]{
    f:-9!-8!.log.plain;
    `.log.msg mock {[h;lvl;x]'"should not be called by name"};
    f["Your card is 5"] musteq -1i;
  };
 };
