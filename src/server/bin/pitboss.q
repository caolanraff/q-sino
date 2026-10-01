if[not`utl in key`;system"l vendor/qutil/bootstrap.q";.utl.QPATH:`:vendor`:src];
.utl.require"common";

.pit.res:([]round:`long$());                                                                       / hands seen this shoe
.pit.double:.pit.split:.pit.stick:.pit.insure:();                                                  / tell plays caught, by kind
.pit.betTrend:flip`round`name`handle`basic_cor`basic_cov`omega_cor`omega_cov`perfect_cor`perfect_cov!(); / each round's bet/count correlation and covariance by player
.pit.bets:([]name:`symbol$();handle:`int$();bet:`long$();basic:`float$();omega:`float$();perfect:`float$()); / each player's recent bets, with the counts when they bet
.pit.window:100;                                                                                   / bets kept per player
.pit.minHands:20;                                                                                  / bets needed before judging a player
.pit.suspectCor:0.5;                                                                               / correlation that marks a counter
.pit.persist:5;                                                                                    / rounds in a row a player must stay flagged
.pit.streak:(`symbol$())!`long$();                                                                 / player to rounds flagged in a row
.pit.insured:([]name:`symbol$();handle:`int$();basic:`float$());                                   / each player's insured hands, with the Hi-Lo count when they bet
.pit.insureCount:3;                                                                                / Hi-Lo true count where a counter starts insuring
.pit.minInsures:2;                                                                                 / insured hands, all at a high count, that mark a counter
.pit.scores:([]time:`timestamp$();round:`long$();name:`symbol$();handle:`int$();hands:`long$();basic:`float$();omega:`float$();perfect:`float$();score:`float$()); / each round's correlation scores, for charting

.pit.shoeSize:{[h]h"52*.bjk.rules`deckCnt"};                                                       / [handle] cards in a full shoe, from the server's rules

.pit.count:{[pts;t].crd.trueCount[pts;.crd.cardsSeen t;.pit.startCards]};                          / [points;table] true count from the cards in a table

.pit.getBetTrend:{                                                                                 / update each player's bet/count correlation
  earlier:select from .pit.res where round<.pit.rnd;                                               / earlier hands: the count a player knew when betting
  .pit.res:update basic_cnt:.pit.count[.crd.hiLo;earlier],omega_cnt:.pit.count[.crd.omega;earlier],perfect_cnt:.pit.count[.crd.perfect;earlier] from .pit.res where round=.pit.rnd; / this round's counts under each system
  tab:0!select basic_cor:0f^bet cor basic_cnt,basic_cov:bet cov basic_cnt,                         / bet vs basic count by player; 0 when either doesn't vary
    omega_cor:0f^bet cor omega_cnt,omega_cov:bet cov omega_cnt,                                    / bet vs omega count
    perfect_cor:0f^bet cor perfect_cnt,perfect_cov:bet cov perfect_cnt                             / bet vs perfect count
    by name,handle from .pit.res;                                                                  / per player
  upsert[`.pit.betTrend;`round xcols update round:.pit.rnd from tab];                              / add this round's row
  .pit.recordBets[];                                                                               / keep this round's bets
 };

.pit.recordBets:{                                                                                  / keep each player's recent bets with the counts
  .pit.bets,:select name,handle,"j"$bet,basic:basic_cnt,omega:omega_cnt,perfect:perfect_cnt from .pit.res where round=.pit.rnd; / this round's bets
  .pit.insured,:select name,handle,basic:basic_cnt from .pit.res where round=.pit.rnd,insurance>0; / this round's insured hands
  delete from`.pit.bets where .pit.window<=({reverse til count x};i)fby name;                      / keep each player's last .pit.window bets; one shoe is too short to judge
 };

.pit.correlations:{update score:basic|omega|perfect from select hands:count i,basic:0f^bet cor basic,omega:0f^bet cor omega,perfect:0f^bet cor perfect by name,handle from .pit.bets}; / per player: hands, bet/count correlation per system, and the best
.pit.recordScores:{.pit.scores,:`time`round xcols update time:.z.p,round:.pit.rnd from 0!.pit.correlations[]}; / keep this round's scores
.pit.insurers:{select from(select insures:count i,highOnly:all basic>=.pit.insureCount by name,handle from .pit.insured)where highOnly}; / players who've only insured at a high count; basic strategy never insures
.pit.flagged:{                                                                                     / players over the line this round, on either tell
  s:.pit.correlations[]lj .pit.insurers[];                                                         / each player's scores and insurance record
  :select from s where((hands>=.pit.minHands)&score>=.pit.suspectCor)|.pit.minInsures<=0^insures;  / bets follow the count, or insures only at a high count
 };

.pit.updateStreaks:{                                                                               / count the rounds each player has been flagged in a row
  n:exec name from .pit.correlations[];                                                            / players with bets
  .pit.streak:n!(1+0^.pit.streak n)*n in exec name from .pit.flagged[];                            / extend a flagged player's streak, reset the rest
 };

.pit.suspects:{0!select from .pit.flagged[]where .pit.persist<=.pit.streak name};                  / players flagged .pit.persist rounds in a row; one round can be chance

.pit.report:{[s]                                                                                   / [suspect] flag a suspected counter to the server
  .log.warn"Suspected card counter: ",string[s`name]," (bet/count correlation ",.Q.f[2;s`score]," over ",string[s`hands]," hands; insured only at a high count ",string[0^s`insures]," times)";
  delete from`.pit.bets where name=s`name;                                                         / start their record afresh
  delete from`.pit.insured where name=s`name;                                                      / and their insurance record
  .pit.streak _:s`name;                                                                            / reset their streak
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

.pit.gcol:{`time,`$string[x],\:"_",string y};                                                      / time plus a <player>_<system> column per player

.pit.chart:{                                                                                       / suspicion scores over time, per player and system, with the alert line
  if[not count .pit.scores;:()];                                                                   / nothing yet
  u:exec distinct name from .pit.scores;                                                           / players
  b:.pit.gcol[u;`basic]xcol exec u#name!basic by time:time from .pit.scores;                       / basic count correlation per player over time
  o:.pit.gcol[u;`omega]xcol exec u#name!omega by time:time from .pit.scores;                       / omega count correlation
  p:.pit.gcol[u;`perfect]xcol exec u#name!perfect by time:time from .pit.scores;                   / perfect count correlation
  :update alert:.pit.suspectCor from 0!(lj/)(b;o;p);                                               / join them, with the alert line at .pit.suspectCor
 };

.pit.shuffle:{.pit.res:0#.pit.res};                                                                / new shoe: forget the hands seen

.pit.getDetect:{[rs]                                                                               / [rounds] run detection on newly finished rounds
  .pit.getBetTrend[];                                                                              / update bet trends
  .pit.recordScores[];                                                                             / keep this round's scores
  .pit.getPlayTrend select from .pit.res where round in rs;                                        / tells in the new rounds only; a finished round's never change
  .pit.updateStreaks[];                                                                            / update flag streaks
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

