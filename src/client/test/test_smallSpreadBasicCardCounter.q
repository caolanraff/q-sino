.tst.desc["smallSpreadBasicCardCounter .stg.getBet"]{
  before{system"l src/client/lib/smallSpreadBasicCardCounter.q"};
  should["bets the table minimum below a true count of 2"]{
    .stg.trueCount:1;
    .stg.getBet[] musteq 10;
  };
  should["bets 15 from a true count of 2 up to (not including) 3"]{
    .stg.trueCount:2;
    .stg.getBet[] musteq 15;
  };
  should["bets 20 from a true count of 3 up to (not including) 4"]{
    .stg.trueCount:3;
    .stg.getBet[] musteq 20;
  };
  should["bets 25 from a true count of 4 up to (not including) 5"]{
    .stg.trueCount:4;
    .stg.getBet[] musteq 25;
  };
  should["bets the max 30 once the true count reaches 5 or more"]{
    .stg.trueCount:5;
    .stg.getBet[] musteq 30;
  };
  should["uses the default basic point-count system - never calls .stg.setCountDict"]{
    .stg.countDict mustmatch .stg.basic;
  };
 };
