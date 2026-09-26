\c 20 200

.da.hist:();
.da.res:([]round:`long$());
.da.betTrend:flip `Round`Player`Handle`basic_cor`basic_cov`omega_cor`omega_cov`perfect_cor`perfect_cov!();

/// Count logic ///
/ a full shoe's card count from the server at h - not count .bs.deck, which is only what's left if we start mid-shoe
.da.shoeSize:{[h]h"52*.bs.deckCnt"};

.da.cardDict:`A`K`Q`J`10`9`8`7`6`5`4`3`2!`11`10`10`10`10`9`8`7`6`5`4`3`2;

.da.basic:`2`3`4`5`6`7`8`9`10`J`Q`K`A!1 1 1 1 1 0 0 0 -1 -1 -1 -1 -1;
.da.omega:`2`3`4`5`6`7`8`9`10`J`Q`K`A!1 1 2 2 2 1 0 -1 -2 -2 -2 -2 0;
.da.perfect:`2`3`4`5`6`7`8`9`10`J`Q`K`A!4 5 6 9 6 4 1 -2 -8 -8 -8 -8 -3;

/ every card seen in a set of result rows: each hand's cards, plus the dealer's hand once per round -
/ every player's row carries its own copy of the dealer's cards (a forfeit row only the up-card, so take the longest)
.da.cardsSeen:{[t]
  c:raze[t`cards],raze value exec {x first idesc count each x} dealer by round from t;
  c where not null c
  };

/ true count for point system pts over result rows t
.da.count:{[pts;t]
  seen:.da.cardsSeen t;
  sum[pts seen]%(.da.startCards-count seen)%52
  };

/// Bet trends ///
.da.getBetTrend:{
  / the count a player could have known when betting this round - earlier rounds only
  earlier:select from .da.res where round<.da.rnd;
  .da.res:update basic_cnt:.da.count[.da.basic;earlier],omega_cnt:.da.count[.da.omega;earlier],perfect_cnt:.da.count[.da.perfect;earlier] from .da.res where round=.da.rnd;
  tab:0!select basic_cor:(bet cor basic_cnt),basic_cov:(bet cov basic_cnt),
    omega_cor:(bet cor omega_cnt),omega_cov:(bet cov omega_cnt),
    perfect_cor:(bet cor perfect_cnt),perfect_cov:(bet cov perfect_cnt)
    by Player:name,Handle:handle from .da.res;
  upsert[`.da.betTrend;`Round xcols update Round:.da.rnd from tab];
  update basic_cor:0f from `.da.betTrend where null basic_cor;
  };

/// Play trends ///
/ basic strategy is the baseline (6-deck, dealer hits soft 17 - the chart in playerCore.q): only plays that
/ depart from it are counter tells, so each flag leaves out hands that basic strategy plays the same way
.da.handFacts:{[t]
  :update up:"I"$string .da.cardDict first each dealer,
    two:{sum "I"$string .da.cardDict 2#x} each cards,
    soft:{`A in 2#x} each cards,
    theCount:basic_cnt
    from t;
  };

.da.getPlayTrend:{
  tab:.da.handFacts .da.hist,.da.res;
  / doubling a first-two-card 18-20, except soft 18 vs 2-6 and soft 19 vs 6, which basic strategy doubles
  .da.double:select round,name,handle,cards,cnt,dealer,theCount from tab where double,two within 18 20,not soft&((two=18)&up within 2 6)|((two=19)&up=6);
  / splitting tens - basic strategy never does
  .da.split:select round,name,handle,cards,cnt,dealer,theCount from tab where split,(first each cards) in `10`J`Q`K;
  / standing on a two-card 15/16 against 7-A, or on a soft 15/16 at all (basic strategy hits both); split aces stand by rule
  .da.stand:select round,name,handle,cards,cnt,dealer,theCount from tab where 2=count each cards,cnt in 15 16,not surrender,not split&`A=first each cards,soft|up>=7;
  };

/// Charting ///
.da.gcol:{`Round,{`$string[x],"_",string[y]}'[except[x;`Round];y]};

.da.chart:{
  if[not count .da.betTrend;:()];
  u:exec distinct Player from .da.betTrend;
  b:.da.gcol[u;`basic] xcol exec u#Player!basic_cov by Round:.z.d+Round from .da.betTrend;
  o:.da.gcol[u;`omega] xcol exec u#Player!omega_cov by Round:.z.d+Round from .da.betTrend;
  p:.da.gcol[u;`perfect] xcol exec u#Player!perfect_cov by Round:.z.d+Round from .da.betTrend;
  update alert1:10, alert2:-10 from 0!(lj/)(b;o;p)
  };

/// Main ///
.da.shuffle:{
  .da.hist,:.da.res;
  .da.res:0#.da.res;
  };

.da.getDetect:{
  .da.getBetTrend[];
  .da.getPlayTrend[];
  };

.da.gameover:{[s]
  .da.rnd:s`rnd;r:s`res;
  .da.res:.da.res uj select from r where not round in exec round from .da.res;
  .da.getDetect[];
  };

/// Start ///
init:{
  show "Loading detection algorithm";
  system "p 5556";
  .da.h:@[hopen;`$":localhost:5555:detectionAlgo";{show"Unable to connect to blackJack_server.q";exit 1}];
  .da.startCards:.da.shoeSize .da.h;
  };

if[(not null .z.f) and "detectionAlgo.q"~last "/" vs string .z.f;init[]];
