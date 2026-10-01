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
  should["write to stdout"]{
    .log.warn["careful"] musteq -1i;
    .log.error["broken"] musteq -1i;
  };
 };

.tst.desc[".log.str"]{
  should["passes a string through"]{
    .log.str["Shuffling the deck"] mustmatch"Shuffling the deck";
  };
  should["joins a list of strings"]{
    .log.str[("New users";" have joined")] mustmatch"New users have joined";
  };
  should["formats anything else, such as a table, with .Q.s"]{
    .log.str[([]hand:1 2;bet:10 20)] mustmatch .Q.s([]hand:1 2;bet:10 20);
  };
 };

.tst.desc[".log.line"]{
  should["stamps the line with the time and level"]{
    .log.line["INFO";("Shuffling";" the deck")] mustlike"20[0-9][0-9].[0-9][0-9].[0-9][0-9] [0-9][0-9]:[0-9][0-9]:*INFO Shuffling the deck";
  };
 };

.tst.desc[".log.msg"]{
  should["write the line to stdout"]{
    .log.msg["INFO";"dealing"] musteq -1i;
  };
 };
