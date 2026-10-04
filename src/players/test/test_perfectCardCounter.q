.tst.desc["perfectCardCounter"]{
  before{.utl.load each`:src/players/lib/strategy.q`:src/players/lib/perfectCardCounter.q};
  should["switches the point-count system to perfect on load"]{
    .stg.countDict mustmatch`2`3`4`5`6`7`8`9`10`J`Q`K`A!4 5 6 9 6 4 1 -2 -7 -7 -7 -7 -5;
  };
  should["scales the true count down to Hi-Lo points"]{
    .stg.countScale musteq 6.3;
  };
  should["bets the table minimum below a true count of 12.6"]{
    .stg.trueCount:12.5;
    .stg.getBet[] musteq 10;
  };
  should["bets 25 from a true count of 12.6 up to (not including) 18.9"]{
    .stg.trueCount:12.6;
    .stg.getBet[] musteq 25;
  };
  should["bets 40 from a true count of 18.9 up to (not including) 25.2"]{
    .stg.trueCount:18.9;
    .stg.getBet[] musteq 40;
  };
  should["bets 60 from a true count of 25.2 up to (not including) 31.5"]{
    .stg.trueCount:25.2;
    .stg.getBet[] musteq 60;
  };
  should["bets the max 80 once the true count reaches 31.5 or more"]{
    .stg.trueCount:31.5;
    .stg.getBet[] musteq 80;
  };
 };
