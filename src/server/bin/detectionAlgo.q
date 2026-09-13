\c 20 200

.bs.count:0f;
.da.hist:();
.da.betTrend:flip `Round`Player`Handle`basic_cor`basic_cov`omega_cor`omega_cov`perfect_cor`perfect_cov!();

/// Count logic ///
cardDict:`A`K`Q`J`10`9`8`7`6`5`4`3`2!`11`10`10`10`10`9`8`7`6`5`4`3`2;

basic:`2`3`4`5`6`7`8`9`10`J`Q`K`A!1 1 1 1 1 0 0 0 -1 -1 -1 -1 -1;
omega:`2`3`4`5`6`7`8`9`10`J`Q`K`A!1 1 2 2 2 1 0 -1 -2 -2 -2 -2 0;
perfect:`2`3`4`5`6`7`8`9`10`J`Q`K`A!4 5 6 9 6 4 1 -2 -8 -8 -8 -8 -3;

Count:{
  acr:(,//)value exec cards,dealer from .da.res;
  runCount:sum x acr;
  runCount%(startCards-count acr)%52
  };

/// Bet trends ///
getBetTrend:{
  .da.res:update basic_cnt:Count[basic],omega_cnt:Count[omega],perfect_cnt:Count[perfect] from .da.res where round=.da.rnd;
  tab:0!select basic_cor:(bet cor basic_cnt),basic_cov:(bet cov basic_cnt),
    omega_cor:(bet cor omega_cnt),omega_cov:(bet cov omega_cnt),
    perfect_cor:(bet cor perfect_cnt),perfect_cov:(bet cov perfect_cnt)
    by Player:name,Handle:handle from .da.res;
  upsert[`.da.betTrend;`Round xcols update Round:.da.rnd from tab];
  update basic_cor:0f from `.da.betTrend where null basic_cor;
  };

/// Play trends ///
getPlayTrend:{
  tab:.da.hist,.da.res;
  / doubling soft 18/19/20
  t:update orgcnt:{sum "I"$string cardDict[2#x]}'[cards] from select from tab where double=1b;
  .da.double:select round,name,handle,cards,cnt,dealer,theCount:.bs.count from t where orgcnt in (18;19;20);
  / splitting tens
  .da.split:select round,name,handle,cards,cnt,dealer,theCount:.bs.count from tab where split=1b, (raze 1#'cards) in (`10`J`Q`K);
  / standing on 15/16
  .da.stand:select from tab where (count each cards)=2,cnt in (15;16);
  };

/// Charting ///
gcol:{`Round,{`$string[x],"_",string[y]}'[except[x;`Round];y]};

chart:{
  if[not count .da.betTrend;:()];
  u:exec distinct Player from .da.betTrend;
  b:gcol[u;`basic] xcol exec u#Player!basic_cov by Round:.z.d+Round from .da.betTrend;
  o:gcol[u;`omega] xcol exec u#Player!omega_cov by Round:.z.d+Round from .da.betTrend;
  p:gcol[u;`perfect] xcol exec u#Player!perfect_cov by Round:.z.d+Round from .da.betTrend;
  update alert1:10, alert2:-10 from 0!(lj/)(b;o;p)
  };

/// Main ///
shuffle:{
  .bs.count:0f;
  .da.hist,:.da.res;
  .da.res:0#.da.res;
  };

getDetect:{
  getBetTrend[];
  getPlayTrend[];
  };

gameover:{
  .da.rnd:.z.w`.bs.rnd;
  .da.res,:x;
  .da.res:distinct .da.res;
  getDetect[];
  };

/// Start ///
init:{
  show "Loading detection algorithm";
  system "p 5556";
  h::@[hopen;`$":localhost:5555:detectionAlgo";{show"Unable to connect to blackJack_server.q";exit 1}];
  startCards::h"count .bs.deck";
  };

if[(not null .z.f) and "detectionAlgo.q"~last "/" vs string .z.f;init[]];
