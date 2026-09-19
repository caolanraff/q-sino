.tst.desc["basicCardCounter.getBet"]{
  should["bets the table minimum below a true count of 2"]{
    system "l src/client/lib/basicCardCounter.q";
    theCount::1;
    getBet[] musteq 10;
    };
  should["bets 25 from a true count of 2 up to (not including) 3"]{
    system "l src/client/lib/basicCardCounter.q";
    theCount::2;
    getBet[] musteq 25;
    };
  should["bets 40 from a true count of 3 up to (not including) 4"]{
    system "l src/client/lib/basicCardCounter.q";
    theCount::3;
    getBet[] musteq 40;
    };
  should["bets 60 from a true count of 4 up to (not including) 5"]{
    system "l src/client/lib/basicCardCounter.q";
    theCount::4;
    getBet[] musteq 60;
    };
  should["bets the max 80 once the true count reaches 5 or more"]{
    system "l src/client/lib/basicCardCounter.q";
    theCount::5;
    getBet[] musteq 80;
    };
  should["uses the default basic point-count system - never calls setCountDict"]{
    system "l src/client/lib/basicCardCounter.q";
    countDict mustmatch basic;
    };
 };
