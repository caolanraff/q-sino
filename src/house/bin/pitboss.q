if[not`utl in key`;system"l vendor/qutil/bootstrap.q";.utl.QPATH:`:vendor`:src];
.utl.require"common";

.pit.res:([]round:"j"$());                                                                         / hands seen this shoe
.pit.double:.pit.split:.pit.stick:.pit.insure:();                                                  / tell plays caught, by kind
.pit.betTrend:([]round:"j"$();name:`$();handle:"i"$();basic_cor:"f"$();basic_cov:"f"$();           / each round's bet/count correlation and covariance by player
  omega_cor:"f"$();omega_cov:"f"$();perfect_cor:"f"$();perfect_cov:"f"$());
.pit.bets:([]name:`$();handle:"i"$();bet:"j"$();basic:"f"$();omega:"f"$();perfect:"f"$());         / each player's recent bets, with the counts when they bet
.pit.window:100;                                                                                   / bets kept per player
.pit.minHands:20;                                                                                  / bets needed before judging a player
.pit.suspectCor:0.5;                                                                               / correlation that marks a counter
.pit.persist:5;                                                                                    / rounds in a row a player must stay flagged
.pit.streak:(`$())!"j"$();                                                                         / player to rounds flagged in a row
.pit.insured:([]name:`$();handle:"i"$();basic:"f"$());                                             / each player's insured hands, with the Hi-Lo count when they bet
.pit.insureCount:3;                                                                                / Hi-Lo true count where a counter starts insuring
.pit.minInsures:2;                                                                                 / insured hands, all at a high count, that mark a counter
.pit.goodCount:2;                                                                                  / Hi-Lo true count from which the deck favours the player
.pit.badCount:0;                                                                                   / Hi-Lo true count at or below which it doesn't
.pit.minRampHands:5;                                                                               / bets needed at each before comparing them
.pit.minRamp:1.5;                                                                                  / how many times bigger a counter bets when the count is good
.pit.scores:([]time:"p"$();round:"j"$();name:`$();handle:"i"$();hands:"j"$();                      / each round's correlation scores, for charting
  basic:"f"$();omega:"f"$();perfect:"f"$();score:"f"$());

.pit.shoeSize:{[h]h"52*.bjk.rules`deckCnt"};                                                       / [handle] cards in a full shoe, from the server's rules

.pit.count:{[pts;t].crd.trueCount[pts;.crd.cardsSeen t;.pit.startCards]};                          / [points;table] true count from the cards in a table

.pit.getBetTrend:{                                                                                 / update each player's bet/count correlation
  past:select from .pit.res where round<.pit.rnd;                                                  / earlier hands: the count a player knew when betting
  .pit.res:update basic_cnt:.pit.count[.crd.hiLo;past],omega_cnt:.pit.count[.crd.omega;past],      / this round's counts under each system
    perfect_cnt:.pit.count[.crd.perfect;past] from .pit.res where round=.pit.rnd;
  tab:0!select basic_cor:0f^bet cor basic_cnt,basic_cov:bet cov basic_cnt,                         / bet vs each system's count, per player; cor is 0 when either doesn't vary
    omega_cor:0f^bet cor omega_cnt,omega_cov:bet cov omega_cnt,
    perfect_cor:0f^bet cor perfect_cnt,perfect_cov:bet cov perfect_cnt
    by name,handle from .pit.res;
  upsert[`.pit.betTrend;`round xcols update round:.pit.rnd from tab];                              / add this round's row
  .pit.recordBets[];                                                                               / keep this round's bets
 };

.pit.recordBets:{                                                                                  / keep each player's recent bets with the counts
  .pit.bets,:select name,handle,"j"$bet,basic:basic_cnt,omega:omega_cnt,perfect:perfect_cnt        / this round's bets
    from .pit.res where round=.pit.rnd;
  .pit.insured,:select name,handle,basic:basic_cnt from .pit.res where round=.pit.rnd,insurance>0; / this round's insured hands
  delete from`.pit.bets where .pit.window<=({reverse til count x};i)fby name;                      / keep each player's last .pit.window bets; one shoe is too short to judge
 };

.pit.correlations:{                                                                                / per player: hands, bet/count correlation per system, and the best
  s:select hands:count i,basic:0f^bet cor basic,omega:0f^bet cor omega,perfect:0f^bet cor perfect  / hands and correlation per system
    by name,handle from .pit.bets;
  :update score:basic|omega|perfect from s;                                                        / the best of them
 };

.pit.recordScores:{                                                                                / keep this round's scores
  .pit.scores,:`time`round xcols update time:.z.p,round:.pit.rnd from 0!.pit.correlations[];       / stamped with the time and round
 };

.pit.insurers:{                                                                                    / players who've only insured at a high count; basic strategy never insures
  :select insures:count i by name,handle from .pit.insured                                         / insured hands per player, if all at a high count
    where(all;basic>=.pit.insureCount)fby name;
 };

.pit.ramps:{                                                                                       / per player: bets at a good and a bad count, and how much bigger the good-count ones are
  :select good:sum basic>=.pit.goodCount,bad:sum basic<=.pit.badCount,                             / bets at each count, and their average ratio
    ramp:(avg bet where basic>=.pit.goodCount)%avg bet where basic<=.pit.badCount
    by name,handle from .pit.bets;
 };

.pit.flagged:{                                                                                     / players over the line this round, on any tell
  s:(lj/)(.pit.correlations[];.pit.insurers[];.pit.ramps[]);                                       / each player's scores, insurance record and bet ramp
  s:update follows:(hands>=.pit.minHands)&score>=.pit.suspectCor,                                  / bets follow the count; insures only at a high count
    insuresHigh:.pit.minInsures<=0^insures from s;
  s:update ramps:(.pit.minRampHands<=good&bad)&ramp>=.pit.minRamp from s;                          / bets clearly more when the count is good
  :select from s where follows|insuresHigh|ramps;                                                  / flagged on any of them
 };

.pit.updateStreaks:{                                                                               / count the rounds each player has been flagged in a row
  n:exec name from .pit.correlations[];                                                            / players with bets
  .pit.streak:n!(1+0^.pit.streak n)*n in exec name from .pit.flagged[];                            / extend a flagged player's streak, reset the rest
 };

.pit.suspects:{0!select from .pit.flagged[]where .pit.persist<=.pit.streak name};                  / players flagged .pit.persist rounds in a row; one round can be chance

.pit.report:{[s]                                                                                   / [suspect] flag a suspected counter to the server
  m:"bet/count correlation ",.Q.f[2;s`score]," over ",string[s`hands]," hands; ";                  / why they're suspected
  m,:"bets ",.Q.f[1;0^s`ramp],"x as much at a good count; ";                                       / their bet ramp
  m,:"insured only at a high count ",string[0^s`insures]," times";                                 / their insurance record
  .log.warn"Suspected card counter: ",string[s`name]," (",m,")";
  delete from`.pit.bets where name=s`name;                                                         / start their record afresh
  delete from`.pit.insured where name=s`name;                                                      / and their insurance record
  .pit.streak _:s`name;                                                                            / reset their streak
  neg[.pit.h](`.bjk.eject;s`handle);                                                               / ask the server to eject them
 };

.pit.handFacts:{[t]                                                                                / [table] flag tells: plays 6-deck H17 basic strategy wouldn't make
  t:update up:"I"$string .crd.cardDict first each dealer,                                          / add each hand's up-card value, two-card total, softness, count and dealer blackjack
    two:{sum"I"$string .crd.cardDict 2#x}each cards,
    soft:{`A in 2#x}each cards,
    theCount:basic_cnt,
    dealerBJ:{(2=count x)&21=sum"I"$string .crd.cardDict x}each dealer
    from t;
  :update doubleTell:double&(two within 18 20)&not soft&((two=18)&up within 2 6)|(two=19)&up=6,    / flag tells: doubling 18-20 (but not soft 18 v 2-6 or soft 19 v 6), splitting tens, sticking on two-card 15/16 that's soft or v 7+ (unless a dealer blackjack ended the hand), insuring
    splitTell:split&(first each cards)in`10`J`Q`K,
    stickTell:not[dealerBJ]&(2=count each cards)&(cnt in 15 16)&(not split&`A=first each cards)&soft|up>=7,
    insureTell:insurance>0
    from t;
 };

.pit.getPlayTrend:{[t]                                                                             / [table] record the tells in finished hands
  if[0=count t;:()];                                                                               / nothing new
  t:.pit.handFacts t;                                                                              / flag tells
  .pit.double,:select round,name,handle,cards,cnt,dealer,theCount from t where doubleTell;         / doubles that were tells
  .pit.split,:select round,name,handle,cards,cnt,dealer,theCount from t where splitTell;           / splits that were tells
  .pit.stick,:select round,name,handle,cards,cnt,dealer,theCount from t where stickTell;           / sticks that were tells
  .pit.insure,:select round,name,handle,cards,cnt,dealer,theCount,insurance                        / insurance taken
    from t where insureTell;
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
  .log.info"Loading pitboss";
  if[not system"p";system"p 5556"];
  s:`$string[.pit.server],":pitboss";                                                              / the server, as the pitboss user
  .pit.h:@[hopen;s;{.log.error"Unable to connect to blackjack.q: ",x;exit 1}];                     / connect, or exit
  .pit.startCards:.pit.shoeSize .pit.h;                                                            / full shoe size
 };

.util.run[`pitboss.q;`.pit.init];                                                                  / init when run as the entry script

