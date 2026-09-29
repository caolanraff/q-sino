.tst.desc["perfectCardCounter"]{
  before{.utl.load each`:src/client/lib/strategy.q`:src/client/lib/perfectCardCounter.q};
  should["switches the point-count system to perfect on load"]{
    .stg.countDict mustmatch`2`3`4`5`6`7`8`9`10`J`Q`K`A!4 5 6 9 6 4 1 -2 -8 -8 -8 -8 -3;
  };
  should["bets the table minimum below a true count of 2"]{
    .stg.trueCount:1;
    .stg.getBet[] musteq 10;
  };
  should["bets 25 from a true count of 2 up to (not including) 3"]{
    .stg.trueCount:2;
    .stg.getBet[] musteq 25;
  };
  should["bets 40 from a true count of 3 up to (not including) 4"]{
    .stg.trueCount:3;
    .stg.getBet[] musteq 40;
  };
  should["bets 60 from a true count of 4 up to (not including) 5"]{
    .stg.trueCount:4;
    .stg.getBet[] musteq 60;
  };
  should["bets the max 80 once the true count reaches 5 or more"]{
    .stg.trueCount:5;
    .stg.getBet[] musteq 80;
  };
 };
