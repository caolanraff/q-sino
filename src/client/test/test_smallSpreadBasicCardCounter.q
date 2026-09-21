.tst.desc["smallSpreadBasicCardCounter.getBet"]{
  before{system "l src/client/lib/smallSpreadBasicCardCounter.q"};
  should["bets the table minimum below a true count of 2"]{
    theCount::1;
    getBet[] musteq 10;
    };
  should["bets 15 from a true count of 2 up to (not including) 3"]{
    theCount::2;
    getBet[] musteq 15;
    };
  should["bets 20 from a true count of 3 up to (not including) 4"]{
    theCount::3;
    getBet[] musteq 20;
    };
  should["bets 25 from a true count of 4 up to (not including) 5"]{
    theCount::4;
    getBet[] musteq 25;
    };
  should["bets the max 30 once the true count reaches 5 or more"]{
    theCount::5;
    getBet[] musteq 30;
    };
  should["uses the default basic point-count system - never calls setCountDict"]{
    countDict mustmatch basic;
    };
 };
