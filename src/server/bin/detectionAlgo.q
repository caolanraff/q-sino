\c 20 200

.bs.count:0f;
.da.hist:();
.da.res:([]round:`long$());
.da.betTrend:flip `Round`Player`Handle`basic_cor`basic_cov`omega_cor`omega_cov`perfect_cor`perfect_cov!();

/// Count logic ///
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
.da.getPlayTrend:{
  tab:.da.hist,.da.res;
  / doubling soft 18/19/20
  t:update orgcnt:{sum "I"$string .da.cardDict[2#x]}'[cards] from select from tab where double=1b;
  .da.double:select round,name,handle,cards,cnt,dealer,theCount:.bs.count from t where orgcnt in (18;19;20);
  / splitting tens
  .da.split:select round,name,handle,cards,cnt,dealer,theCount:.bs.count from tab where split=1b, (raze 1#'cards) in (`10`J`Q`K);
  / standing on 15/16
  .da.stand:select from tab where (count each cards)=2,cnt in (15;16);
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
  .bs.count:0f;
  .da.hist,:.da.res;
  .da.res:0#.da.res;
  };

.da.getDetect:{
  .da.getBetTrend[];
  .da.getPlayTrend[];
  };

.da.gameover:{
  .da.rnd:.z.w`.bs.rnd;
  / x is the whole shoe's .bs.res so far: only take rounds not already held (held rows carry the
  / count columns added by .da.getBetTrend, so a distinct over both would keep them twice)
  .da.res:.da.res uj select from x where not round in exec round from .da.res;
  .da.getDetect[];
  };

/// Start ///
init:{
  show "Loading detection algorithm";
  system "p 5556";
  .da.h:@[hopen;`$":localhost:5555:detectionAlgo";{show"Unable to connect to blackJack_server.q";exit 1}];
  .da.startCards:.da.h"count .bs.deck";
  };

if[(not null .z.f) and "detectionAlgo.q"~last "/" vs string .z.f;init[]];
