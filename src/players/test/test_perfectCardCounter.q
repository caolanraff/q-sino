.tst.desc["perfectCardCounter"]{
  before{.utl.load each`:src/players/lib/strategy.q`:src/players/lib/perfectCardCounter.q};
  should["switches the point-count system to perfect on load"]{
    .stg.countDict mustmatch`2`3`4`5`6`7`8`9`10`J`Q`K`A!4 5 6 9 6 4 1 -2 -7 -7 -7 -7 -5;
  };
  should["scales the true count down to Hi-Lo points"]{
    .stg.countScale musteq 6f;
  };
  should["bets the table minimum below a true count of 12"]{
    .stg.trueCount:11.9;
    .stg.getBet[] musteq 10;
  };
  should["bets 25 from a true count of 12 up to (not including) 18"]{
    .stg.trueCount:12f;
    .stg.getBet[] musteq 25;
  };
  should["bets 40 from a true count of 18 up to (not including) 24"]{
    .stg.trueCount:18f;
    .stg.getBet[] musteq 40;
  };
  should["bets 60 from a true count of 24 up to (not including) 30"]{
    .stg.trueCount:24f;
    .stg.getBet[] musteq 60;
  };
  should["bets the max 80 once the true count reaches 30 or more"]{
    .stg.trueCount:30f;
    .stg.getBet[] musteq 80;
  };
 };
