if[not`utl in key`;system"l vendor/qutil/bootstrap.q";.utl.QPATH:`:vendor`:src];
.utl.require"common";

.pit.res:([]round:`long$());
.pit.double:.pit.split:.pit.stick:.pit.insure:();
.pit.betTrend:flip`Round`Player`Handle`basic_cor`basic_cov`omega_cor`omega_cov`perfect_cor`perfect_cov!();
.pit.bets:([]name:`symbol$();handle:`int$();bet:`long$();basic:`float$();omega:`float$();perfect:`float$());
.pit.window:100;
.pit.minHands:20;
.pit.suspectCor:0.5;
.pit.persist:5;
.pit.streak:(`symbol$())!`long$();
.pit.scores:([]time:`timestamp$();round:`long$();name:`symbol$();handle:`int$();hands:`long$();basic:`float$();omega:`float$();perfect:`float$();score:`float$());

.pit.shoeSize:{[h]h"52*.bjk.rules`deckCnt"};                                                               / a full shoe - count .bjk.deck is only what's left mid-shoe

.pit.count:{[pts;t].crd.trueCount[pts;.crd.cardsSeen t;.pit.startCards]};

.pit.getBetTrend:{
  earlier:select from .pit.res where round<.pit.rnd;                                                 / the count a player could have known when betting
  .pit.res:update basic_cnt:.pit.count[.crd.hiLo;earlier],omega_cnt:.pit.count[.crd.omega;earlier],perfect_cnt:.pit.count[.crd.perfect;earlier] from .pit.res where round=.pit.rnd;
  tab:0!select basic_cor:0f^bet cor basic_cnt,basic_cov:bet cov basic_cnt,                         / cor is null when bets or the count don't vary
    omega_cor:0f^bet cor omega_cnt,omega_cov:bet cov omega_cnt,
    perfect_cor:0f^bet cor perfect_cnt,perfect_cov:bet cov perfect_cnt
    by Player:name,Handle:handle from .pit.res;
  upsert[`.pit.betTrend;`Round xcols update Round:.pit.rnd from tab];
  .pit.recordBets[];
 };

.pit.recordBets:{
  .pit.bets,:select name,handle,"j"$bet,basic:basic_cnt,omega:omega_cnt,perfect:perfect_cnt from .pit.res where round=.pit.rnd;
  delete from`.pit.bets where .pit.window<=({reverse til count x};i)fby name;                      / a shoe can be too short to judge at a full table
 };

.pit.correlations:{update score:basic|omega|perfect from select hands:count i,basic:0f^bet cor basic,omega:0f^bet cor omega,perfect:0f^bet cor perfect by name,handle from .pit.bets};
.pit.recordScores:{.pit.scores,:`time`round xcols update time:.z.p,round:.pit.rnd from 0!.pit.correlations[]};
.pit.flagged:{select from .pit.correlations[]where hands>=.pit.minHands,score>=.pit.suspectCor};

.pit.updateStreaks:{
  n:exec name from .pit.correlations[];
  .pit.streak:n!(1+0^.pit.streak n)*n in exec name from .pit.flagged[];
 };

.pit.suspects:{0!select from .pit.flagged[]where .pit.persist<=.pit.streak name};                  / one round over the line can be chance

.pit.report:{[s]
  .log.warn"Suspected card counter: ",string[s`name]," (bets follow the count, correlation ",.Q.f[2;s`score]," over ",string[s`hands]," hands)";
  delete from`.pit.bets where name=s`name;
  .pit.streak _:s`name;
  neg[.pit.h](`.bjk.eject;s`handle);
 };

.pit.handFacts:{[t]                                                                                 / tells: plays 6-deck H17 basic strategy wouldn't make
  t:update up:"I"$string .crd.cardDict first each dealer,
    two:{sum"I"$string .crd.cardDict 2#x}each cards,
    soft:{`A in 2#x}each cards,
    theCount:basic_cnt
    from t;
  :update doubleTell:double&(two within 18 20)&not soft&((two=18)&up within 2 6)|(two=19)&up=6,
    splitTell:split&(first each cards)in`10`J`Q`K,
    stickTell:(2=count each cards)&(cnt in 15 16)&(not split&`A=first each cards)&soft|up>=7,
    insureTell:insurance>0
    from t;
 };

.pit.getPlayTrend:{[t]
  if[0=count t;:()];
  t:.pit.handFacts t;
  .pit.double,:select round,name,handle,cards,cnt,dealer,theCount from t where doubleTell;
  .pit.split,:select round,name,handle,cards,cnt,dealer,theCount from t where splitTell;
  .pit.stick,:select round,name,handle,cards,cnt,dealer,theCount from t where stickTell;
  .pit.insure,:select round,name,handle,cards,cnt,dealer,theCount,insurance from t where insureTell;
 };

.pit.gcol:{`time,`$string[x],\:"_",string y};

.pit.chart:{
  if[not count .pit.scores;:()];
  u:exec distinct name from .pit.scores;
  b:.pit.gcol[u;`basic]xcol exec u#name!basic by time:time from .pit.scores;
  o:.pit.gcol[u;`omega]xcol exec u#name!omega by time:time from .pit.scores;
  p:.pit.gcol[u;`perfect]xcol exec u#name!perfect by time:time from .pit.scores;
  :update alert:.pit.suspectCor from 0!(lj/)(b;o;p);
 };

.pit.shuffle:{.pit.res:0#.pit.res};

.pit.getDetect:{[rs]
  .pit.getBetTrend[];
  .pit.recordScores[];
  .pit.getPlayTrend select from .pit.res where round in rs;                                        / a finished round's tells never change
  .pit.updateStreaks[];
  .pit.report each .pit.suspects[];
 };

.pit.gameover:{[s]
  .pit.rnd:s`rnd;
  new:select from s[`res]where not round in exec round from .pit.res;
  .pit.res:.pit.res uj new;
  .pit.getDetect exec distinct round from new;
 };

.pit.init:{
  .utl.addOptDef["server";"S";`:localhost:5555;{`.pit.server set hsym x}];
  .utl.parseArgs[];
  .log.info"Loading detection algorithm";
  if[not system"p";system"p 5556"];
  .pit.h:@[hopen;`$string[.pit.server],":pitboss";{.log.error"Unable to connect to blackjack.q: ",x;exit 1}];
  .pit.startCards:.pit.shoeSize .pit.h;
 };

.util.run[`pitboss.q;`.pit.init];

