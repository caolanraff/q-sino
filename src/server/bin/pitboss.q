if[not`utl in key`;system"l vendor/qutil/bootstrap.q";.utl.QPATH:`:vendor`:src];
.utl.require"common";

.pit.res:([]round:`long$());                                                                       / hands seen this shoe
.pit.double:.pit.split:.pit.stick:.pit.insure:();                                                  / tell plays caught, by kind
.pit.betTrend:flip`Round`Player`Handle`basic_cor`basic_cov`omega_cor`omega_cov`perfect_cor`perfect_cov!(); / each round's bet/count correlation and covariance by player
.pit.bets:([]name:`symbol$();handle:`int$();bet:`long$();basic:`float$();omega:`float$();perfect:`float$()); / each player's recent bets, with the counts when they bet
.pit.window:100;                                                                                   / bets kept per player
.pit.minHands:20;                                                                                  / bets needed before judging a player
.pit.suspectCor:0.5;                                                                               / correlation that marks a counter

.pit.shoeSize:{[h]h"52*.bjk.rules`deckCnt"};                                                       / [handle] cards in a full shoe, from the server's rules

.pit.count:{[pts;t].crd.trueCount[pts;.crd.cardsSeen t;.pit.startCards]};                          / [points;table] true count from the cards in a table

.pit.getBetTrend:{                                                                                 / update each player's bet/count correlation
  earlier:select from .pit.res where round<.pit.rnd;                                               / earlier hands: the count a player knew when betting
  .pit.res:update basic_cnt:.pit.count[.crd.hiLo;earlier],omega_cnt:.pit.count[.crd.omega;earlier],perfect_cnt:.pit.count[.crd.perfect;earlier] from .pit.res where round=.pit.rnd; / this round's counts under each system
  tab:0!select basic_cor:0f^bet cor basic_cnt,basic_cov:bet cov basic_cnt,                         / bet vs basic count by player; 0 when either doesn't vary
    omega_cor:0f^bet cor omega_cnt,omega_cov:bet cov omega_cnt,                                    / bet vs omega count
    perfect_cor:0f^bet cor perfect_cnt,perfect_cov:bet cov perfect_cnt                             / bet vs perfect count
    by Player:name,Handle:handle from .pit.res;                                                    / per player
  upsert[`.pit.betTrend;`Round xcols update Round:.pit.rnd from tab];                              / add this round's row
  .pit.recordBets[];                                                                               / keep this round's bets
 };

.pit.recordBets:{                                                                                  / keep each player's recent bets with the counts
  .pit.bets,:select name,handle,"j"$bet,basic:basic_cnt,omega:omega_cnt,perfect:perfect_cnt from .pit.res where round=.pit.rnd; / this round's bets
  delete from`.pit.bets where .pit.window<=({reverse til count x};i)fby name;                      / keep each player's last .pit.window bets; one shoe is too short to judge
 };

.pit.correlations:{select hands:count i,score:max(0f^bet cor basic;0f^bet cor omega;0f^bet cor perfect)by name,handle from .pit.bets}; / per player: hands and best bet/count correlation
.pit.suspects:{0!select from .pit.correlations[]where hands>=.pit.minHands,score>=.pit.suspectCor}; / players whose bets follow the count

.pit.report:{[s]                                                                                   / [suspect] flag a suspected counter to the server
  .log.warn"Suspected card counter: ",string[s`name]," (bets follow the count, correlation ",.Q.f[2;s`score]," over ",string[s`hands]," hands)";
  delete from`.pit.bets where name=s`name;                                                         / start their record afresh
  neg[.pit.h](`.bjk.eject;s`handle);                                                               / ask the server to eject them
 };

.pit.handFacts:{[t]                                                                                / [table] flag tells: plays 6-deck H17 basic strategy wouldn't make
  t:update up:"I"$string .crd.cardDict first each dealer,                                          / dealer's up-card value
    two:{sum"I"$string .crd.cardDict 2#x}each cards,                                               / first two cards' total
    soft:{`A in 2#x}each cards,                                                                    / soft hand
    theCount:basic_cnt                                                                             / count when the hand was bet
    from t;                                                                                        / per hand
  :update doubleTell:double&(two within 18 20)&not soft&((two=18)&up within 2 6)|(two=19)&up=6,    / doubled 18-20, except soft 18 v 2-6 and soft 19 v 6
    splitTell:split&(first each cards)in`10`J`Q`K,                                                 / split tens
    stickTell:(2=count each cards)&(cnt in 15 16)&(not split&`A=first each cards)&soft|up>=7,      / stuck on a two-card soft 15/16, or 15/16 v 7+
    insureTell:insurance>0                                                                         / took insurance
    from t;                                                                                        / per hand
 };

.pit.getPlayTrend:{[t]                                                                             / [table] record the tells in finished hands
  if[0=count t;:()];                                                                               / nothing new
  t:.pit.handFacts t;                                                                              / flag tells
  .pit.double,:select round,name,handle,cards,cnt,dealer,theCount from t where doubleTell;         / doubles that were tells
  .pit.split,:select round,name,handle,cards,cnt,dealer,theCount from t where splitTell;           / splits that were tells
  .pit.stick,:select round,name,handle,cards,cnt,dealer,theCount from t where stickTell;           / sticks that were tells
  .pit.insure,:select round,name,handle,cards,cnt,dealer,theCount,insurance from t where insureTell; / insurance taken
 };

.pit.gcol:{`Round,`$string[x except`Round],\:"_",string y};                                        / Round plus a <player>_<system> column per player

.pit.chart:{                                                                                       / covariance by round, per player and system, with alert lines
  if[not count .pit.betTrend;:()];                                                                 / nothing yet
  u:exec distinct Player from .pit.betTrend;                                                       / players
  b:.pit.gcol[u;`basic]xcol exec u#Player!basic_cov by Round:.z.d+Round from .pit.betTrend;        / basic count covariance per player by round
  o:.pit.gcol[u;`omega]xcol exec u#Player!omega_cov by Round:.z.d+Round from .pit.betTrend;        / omega count covariance
  p:.pit.gcol[u;`perfect]xcol exec u#Player!perfect_cov by Round:.z.d+Round from .pit.betTrend;    / perfect count covariance
  :update alert1:10,alert2:-10 from 0!(lj/)(b;o;p);                                                / join them, with alert lines at +/-10
 };

.pit.shuffle:{.pit.res:0#.pit.res};                                                                / new shoe: forget the hands seen

.pit.getDetect:{[rs]                                                                               / [rounds] run detection on newly finished rounds
  .pit.getBetTrend[];                                                                              / update bet trends
  .pit.getPlayTrend select from .pit.res where round in rs;                                        / tells in the new rounds only; a finished round's never change
  .pit.report each .pit.suspects[];                                                                / report each suspect
 };

.pit.gameover:{[s]                                                                                 / [state] take a finished round's results from the server
  .pit.rnd:s`rnd;                                                                                  / current round
  new:select from s[`res]where not round in exec round from .pit.res;                              / rounds not seen yet
  .pit.res:.pit.res uj new;                                                                        / add them
  .pit.getDetect exec distinct round from new;                                                     / run detection on them
 };

.pit.init:{                                                                                        / start the detection process
  .utl.addOptDef["server";"S";`:localhost:5555;{`.pit.server set hsym x}];                         / --server: blackjack server address
  .utl.parseArgs[];                                                                                / parse the command line
  .log.info"Loading detection algorithm";
  if[not system"p";system"p 5556"];
  .pit.h:@[hopen;`$string[.pit.server],":pitboss";{.log.error"Unable to connect to blackjack.q: ",x;exit 1}]; / connect to the server as the pitboss, or exit
  .pit.startCards:.pit.shoeSize .pit.h;                                                            / full shoe size
 };

.util.run[`pitboss.q;`.pit.init];                                                                  / init when run as the entry script

