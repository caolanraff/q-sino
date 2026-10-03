.tst.desc["omegaCardCounter"]{
  before{.utl.load each`:src/players/lib/strategy.q`:src/players/lib/omegaCardCounter.q};
  should["switches the point-count system to omega on load"]{
    .stg.countDict mustmatch`2`3`4`5`6`7`8`9`10`J`Q`K`A!1 1 2 2 2 1 0 -1 -2 -2 -2 -2 0;
  };
  should["scales the true count down to Hi-Lo points"]{
    .stg.countScale musteq 1.6;
  };
  should["bets the table minimum below a true count of 3.2"]{
    .stg.trueCount:3.1;
    .stg.getBet[] musteq 10;
  };
  should["bets 25 from a true count of 3.2 up to (not including) 4.8"]{
    .stg.trueCount:3.2;
    .stg.getBet[] musteq 25;
  };
  should["bets 40 from a true count of 4.8 up to (not including) 6.4"]{
    .stg.trueCount:4.8;
    .stg.getBet[] musteq 40;
  };
  should["bets 60 from a true count of 6.4 up to (not including) 8"]{
    .stg.trueCount:6.4;
    .stg.getBet[] musteq 60;
  };
  should["bets the max 80 once the true count reaches 8 or more"]{
    .stg.trueCount:8f;
    .stg.getBet[] musteq 80;
  };
 };
