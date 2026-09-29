.pit.res:([]round:`long$());
.pit.double:.pit.split:.pit.stand:.pit.insure:();
.pit.betTrend:flip`Round`Player`Handle`basic_cor`basic_cov`omega_cor`omega_cov`perfect_cor`perfect_cov!();

.pit.lg:{-1 ssr[string .z.p;"D";" "]," ",raze x};
.pit.shoeSize:{[h]h"52*.bjk.rules`deckCnt"};                                                               / a full shoe - count .bjk.deck is only what's left mid-shoe

.pit.cardDict:`A`K`Q`J`10`9`8`7`6`5`4`3`2!`11`10`10`10`10`9`8`7`6`5`4`3`2;

.pit.basic:`2`3`4`5`6`7`8`9`10`J`Q`K`A!1 1 1 1 1 0 0 0 -1 -1 -1 -1 -1;
.pit.omega:`2`3`4`5`6`7`8`9`10`J`Q`K`A!1 1 2 2 2 1 0 -1 -2 -2 -2 -2 0;
.pit.perfect:`2`3`4`5`6`7`8`9`10`J`Q`K`A!4 5 6 9 6 4 1 -2 -8 -8 -8 -8 -3;

.pit.cardsSeen:{[t]
  c:raze[t`cards],raze value exec{x first idesc count each x}dealer by round from t;               / dealer's hand once per round; a forfeit row has only the up-card
  :c where not null c;
 };

.pit.count:{[pts;t]
  seen:.pit.cardsSeen t;
  :sum[pts seen]%(.pit.startCards-count seen)%52;
 };

.pit.getBetTrend:{
  earlier:select from .pit.res where round<.pit.rnd;                                                 / the count a player could have known when betting
  .pit.res:update basic_cnt:.pit.count[.pit.basic;earlier],omega_cnt:.pit.count[.pit.omega;earlier],perfect_cnt:.pit.count[.pit.perfect;earlier] from .pit.res where round=.pit.rnd;
  tab:0!select basic_cor:0f^bet cor basic_cnt,basic_cov:bet cov basic_cnt,                         / cor is null when bets or the count don't vary
    omega_cor:0f^bet cor omega_cnt,omega_cov:bet cov omega_cnt,
    perfect_cor:0f^bet cor perfect_cnt,perfect_cov:bet cov perfect_cnt
    by Player:name,Handle:handle from .pit.res;
  upsert[`.pit.betTrend;`Round xcols update Round:.pit.rnd from tab];
 };

.pit.handFacts:{[t]                                                                                 / tells: plays 6-deck H17 basic strategy wouldn't make
  t:update up:"I"$string .pit.cardDict first each dealer,
    two:{sum"I"$string .pit.cardDict 2#x}each cards,
    soft:{`A in 2#x}each cards,
    theCount:basic_cnt
    from t;
  :update doubleTell:double&(two within 18 20)&not soft&((two=18)&up within 2 6)|(two=19)&up=6,
    splitTell:split&(first each cards)in`10`J`Q`K,
    standTell:(2=count each cards)&(cnt in 15 16)&(not split&`A=first each cards)&soft|up>=7,
    insureTell:insurance>0
    from t;
 };

.pit.getPlayTrend:{[t]
  if[0=count t;:()];
  t:.pit.handFacts t;
  .pit.double,:select round,name,handle,cards,cnt,dealer,theCount from t where doubleTell;
  .pit.split,:select round,name,handle,cards,cnt,dealer,theCount from t where splitTell;
  .pit.stand,:select round,name,handle,cards,cnt,dealer,theCount from t where standTell;
  .pit.insure,:select round,name,handle,cards,cnt,dealer,theCount,insurance from t where insureTell;
 };

.pit.gcol:{`Round,`$string[x except`Round],\:"_",string y};

.pit.chart:{
  if[not count .pit.betTrend;:()];
  u:exec distinct Player from .pit.betTrend;
  b:.pit.gcol[u;`basic]xcol exec u#Player!basic_cov by Round:.z.d+Round from .pit.betTrend;
  o:.pit.gcol[u;`omega]xcol exec u#Player!omega_cov by Round:.z.d+Round from .pit.betTrend;
  p:.pit.gcol[u;`perfect]xcol exec u#Player!perfect_cov by Round:.z.d+Round from .pit.betTrend;
  :update alert1:10,alert2:-10 from 0!(lj/)(b;o;p);
 };

.pit.shuffle:{.pit.res:0#.pit.res};

.pit.getDetect:{[rs]
  .pit.getBetTrend[];
  .pit.getPlayTrend select from .pit.res where round in rs;                                        / a finished round's tells never change
 };

.pit.gameover:{[s]
  .pit.rnd:s`rnd;
  new:select from s[`res]where not round in exec round from .pit.res;
  .pit.res:.pit.res uj new;
  .pit.getDetect exec distinct round from new;
 };

.pit.init:{
  system"c 100 200";
  system"l vendor/qutil/bootstrap.q";
  .utl.QPATH:enlist`:vendor;
  .utl.require"qutil/opts.q";
  .utl.addOptDef["server";"S";`localhost:5555;`.pit.server];
  .utl.parseArgs[];
  .pit.lg"Loading detection algorithm";
  if[not system"p";system"p 5556"];
  .pit.h:@[hopen;hsym`$string[.pit.server],":pitboss";{.pit.lg"Unable to connect to blackjack.q: ",x;exit 1}];
  .pit.startCards:.pit.shoeSize .pit.h;
 };

if[not[null .z.f]&"pitboss.q"~last"/"vs string .z.f;.pit.init[]];

