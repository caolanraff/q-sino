.tst.desc["omegaCardCounter"]{
  before{.utl.load each`:src/players/lib/strategy.q`:src/players/lib/omegaCardCounter.q};
  should["switches the point-count system to omega on load"]{
    .stg.countDict mustmatch`2`3`4`5`6`7`8`9`10`J`Q`K`A!1 1 2 2 2 1 0 -1 -2 -2 -2 -2 0;
  };
  should["scales the true count down to Hi-Lo points"]{
    .stg.countScale musteq 1.6;
  };
  should["bets the table minimum below 2 Hi-Lo points"]{
    .stg.trueCount:1.6*1.9;
    .stg.getBet[] musteq 10;
  };
  should["bets 25 from 2 Hi-Lo points up to (not including) 3"]{
    .stg.trueCount:1.6*2;
    .stg.getBet[] musteq 25;
  };
  should["bets 40 from 3 Hi-Lo points up to (not including) 4"]{
    .stg.trueCount:1.6*3;
    .stg.getBet[] musteq 40;
  };
  should["bets 60 from 4 Hi-Lo points up to (not including) 5"]{
    .stg.trueCount:1.6*4;
    .stg.getBet[] musteq 60;
  };
  should["bets the max 80 once the count reaches 5 Hi-Lo points or more"]{
    .stg.trueCount:1.6*5;
    .stg.getBet[] musteq 80;
  };
 };
