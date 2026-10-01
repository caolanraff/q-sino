.utl.load`:src/server/bin/pitboss.q;

/ .tst.pitRound[1;`K`5;`2`3`4;`10`8]
.tst.pitRound:{[r;c1;c2;d]([]round:r,r;player:1 2;name:`a_5`b_6;handle:5 6i;cards:(c1;c2);cnt:0 0i;dealer:(d;d);dealerCnt:0 0i;bet:10 20;return:0 0f;profit:0 0f;split:00b;double:00b)};

.tst.desc[".pit.count"]{
  should["gives the true count with each card seen counted once"]{
    .pit.startCards:312;
    t:.tst.pitRound[1;`K`5;`2`3`4;`10`8];                                                           / basic: K5 234 = +3, dealer 10 8 once = -1; 7 cards seen
    .pit.count[.crd.hiLo;t] musteq 2%(312-7)%52;
  };
 };

.tst.desc[".pit.gameover"]{
  should["holds each round once, though the server re-sends the whole shoe every round"]{
    `.pit.getPlayTrend mock {};
    .pit.startCards:312;
    .pit.res:([]round:`long$());
    .pit.betTrend:0#.pit.betTrend;
    r1:.tst.pitRound[1;`K`5;`2`3`4;`10`8];
    r2:r1,.tst.pitRound[2;`A`9;`6`6;`7`K];
    .pit.gameover[`res`rnd!(r1;1)];
    .pit.gameover[`res`rnd!(r2;2)];
    (exec round from .pit.res) musteq 1 1 2 2;
  };
  should["scores each round's bets against the count from earlier rounds only"]{
    `.pit.getPlayTrend mock {};
    .pit.startCards:312;
    .pit.res:([]round:`long$());
    .pit.betTrend:0#.pit.betTrend;
    r1:.tst.pitRound[1;`K`5;`2`3`4;`10`8];
    r2:r1,.tst.pitRound[2;`A`9;`6`6;`7`K];
    .pit.gameover[`res`rnd!(r1;1)];
    .pit.gameover[`res`rnd!(r2;2)];
    (exec basic_cnt from .pit.res where round=1) musteq 0 0f;
    (exec basic_cnt from .pit.res where round=2) musteq 2 2*1%(312-7)%52;
  };
  should["examines only the new round's hands, though the server re-sends the whole shoe"]{
    `.pit.getBetTrend mock {};
    .tst.examined:();
    `.pit.getPlayTrend mock {.tst.examined,:enlist exec distinct round from x};
    .pit.res:([]round:`long$());
    r1:.tst.pitRound[1;`K`5;`2`3`4;`10`8];
    .pit.gameover[`res`rnd!(r1;1)];
    .pit.gameover[`res`rnd!(r1,.tst.pitRound[2;`A`9;`6`6;`7`K];2)];
    .tst.examined mustmatch(enlist 1;enlist 2);
  };
  should["reports each tell once, and keeps an earlier shoe's tells after a shuffle"]{
    .pit.startCards:312;
    .pit.res:([]round:`long$());
    .pit.betTrend:0#.pit.betTrend;
    .pit.double:.pit.split:.pit.stick:.pit.insure:();
    r1:update cnt:15 9i,insurance:0f from .tst.pitRound[1;`K`5;`2`3`4;`10`8];
    .pit.gameover[`res`rnd!(r1;1)];
    .pit.gameover[`res`rnd!(r1,update insurance:0f from .tst.pitRound[2;`A`9;`6`6;`7`K];2)];
    .pit.shuffle[];
    .pit.gameover[`res`rnd!(update cnt:16 9i,insurance:0f from .tst.pitRound[3;`10`6;`2`3`4;`9`8];3)];
    (exec round from .pit.stick) musteq 1 3;
  };
 };

.tst.desc[".pit.getBetTrend"]{
  should["scores a flat bettor's correlation as 0 on every count, not just basic"]{
    `.pit.getPlayTrend mock {};
    .pit.startCards:312;
    .pit.res:([]round:`long$());
    .pit.betTrend:0#.pit.betTrend;
    r1:.tst.pitRound[1;`K`5;`2`3`4;`10`8];
    .pit.gameover[`res`rnd!(r1;1)];
    .pit.gameover[`res`rnd!(r1,.tst.pitRound[2;`A`9;`6`6;`7`K];2)];
    (exec basic_cor from .pit.betTrend where Round=2) musteq 0 0f;
    (exec omega_cor from .pit.betTrend where Round=2) musteq 0 0f;
    (exec perfect_cor from .pit.betTrend where Round=2) musteq 0 0f;
  };
  should["keeps a real correlation"]{
    `.pit.getPlayTrend mock {};
    .pit.startCards:312;
    .pit.res:([]round:`long$());
    .pit.betTrend:0#.pit.betTrend;
    r1:.tst.pitRound[1;`K`5;`2`3`4;`10`8];
    .pit.gameover[`res`rnd!(r1;1)];
    .pit.gameover[`res`rnd!(r1,update bet:30 20 from .tst.pitRound[2;`A`9;`6`6;`7`K];2)];
    (exec basic_cor from .pit.betTrend where Round=2,Player=`a_5) musteq 1f;
    (exec omega_cor from .pit.betTrend where Round=2,Player=`a_5) musteq 1f;
    (exec perfect_cor from .pit.betTrend where Round=2,Player=`a_5) musteq 1f;
  };
 };

.tst.desc[".pit.shoeSize"]{
  should["reports a full shoe, not the cards left in the deck"]{
    .bjk.rules:`maxSplitHands`deckCnt!4 6;
    .bjk.deck:10#`2;                                                                                / mid-shoe: only 10 cards left
    .pit.shoeSize[0] musteq 312;                                                                    / handle 0 evaluates the query in this process
  };
 };

/ .tst.pitPlays[(`A`7`2;`10`6);21 16i;(`7`K;`10`8);10b;00b]
.tst.pitPlays:{[c;n;d;dbl;spl]([]round:1+til count c;name:(count c)#`a_5;handle:(count c)#5i;cards:c;cnt:n;dealer:d;double:dbl;split:spl;insurance:(count c)#0f;basic_cnt:0.5*1+til count c)};

.tst.desc[".pit.getPlayTrend doubles"]{
  should["flags doubling 18-20 that basic strategy wouldn't"]{
    .pit.double:.pit.split:.pit.stick:.pit.insure:();
    .pit.res:.tst.pitPlays[(`A`7`2;`A`8`9;`A`9`3;`10`8`2);21 18 13 20i;(`7`K;`5`K;`4`3;`6`K);1111b;0000b];
    .pit.getPlayTrend .pit.res;
    (exec cards from .pit.double) mustmatch (`A`7`2;`A`8`9;`A`9`3;`10`8`2);                         / soft 18 vs 7, soft 19 vs 5, soft 20, hard 18
  };
  should["leaves out soft 18 vs 2-6 and soft 19 vs 6, which basic strategy doubles"]{
    .pit.double:.pit.split:.pit.stick:.pit.insure:();
    .pit.res:.tst.pitPlays[(`A`7`3;`A`7`2;`A`8`2);21 20 21i;(`2`K;`6`K;`6`K);111b;000b];
    .pit.getPlayTrend .pit.res;
    count[.pit.double] musteq 0;
  };
 };

.tst.desc[".pit.getPlayTrend sticks"]{
  should["flags sticking on a two-card hard 15/16 against 7-A"]{
    .pit.double:.pit.split:.pit.stick:.pit.insure:();
    .pit.res:.tst.pitPlays[(`10`6;`9`6;`10`5);16 15 15i;(`10`8;`7`K;`A`6);000b;000b];
    .pit.getPlayTrend .pit.res;
    count[.pit.stick] musteq 3;
  };
  should["leaves out sticking on hard 15/16 against 2-6, which basic strategy does"]{
    .pit.double:.pit.split:.pit.stick:.pit.insure:();
    .pit.res:.tst.pitPlays[(`10`6;`9`6);16 15i;(`6`K;`2`K);00b;00b];
    .pit.getPlayTrend .pit.res;
    count[.pit.stick] musteq 0;
  };
  should["flags sticking on a soft 15/16 against any up-card"]{
    .pit.double:.pit.split:.pit.stick:.pit.insure:();
    .pit.res:.tst.pitPlays[(`A`5;`A`4);16 15i;(`6`K;`2`K);00b;00b];
    .pit.getPlayTrend .pit.res;
    count[.pit.stick] musteq 2;
  };
  should["leaves out split aces, which stick by rule"]{
    .pit.double:.pit.split:.pit.stick:.pit.insure:();
    .pit.res:.tst.pitPlays[enlist`A`5;enlist 16i;enlist`9`K;enlist 0b;enlist 1b];
    .pit.getPlayTrend .pit.res;
    count[.pit.stick] musteq 0;
  };
 };

.tst.desc[".pit.getPlayTrend splits"]{
  should["flags splitting tens, and not other splits"]{
    .pit.double:.pit.split:.pit.stick:.pit.insure:();
    .pit.res:.tst.pitPlays[(`K`5;`10`9;`8`3);15 19 11i;(`6`K;`6`K;`6`K);000b;111b];
    .pit.getPlayTrend .pit.res;
    (exec cards from .pit.split) mustmatch (`K`5;`10`9);
  };
 };

.tst.desc[".pit.getPlayTrend theCount"]{
  should["reports the basic count the round was played at, not a constant"]{
    .pit.double:.pit.split:.pit.stick:.pit.insure:();
    .pit.res:.tst.pitPlays[(`A`9`3;`10`6);13 16i;(`4`3;`10`8);10b;00b];
    .pit.getPlayTrend .pit.res;
    (exec theCount from .pit.double) musteq enlist 0.5;
    (exec theCount from .pit.stick) musteq enlist 1f;
  };
  should["keeps earlier rounds' tells as later rounds are added"]{
    .pit.double:.pit.split:.pit.stick:.pit.insure:();
    .pit.getPlayTrend .tst.pitPlays[enlist`10`6;enlist 16i;enlist`10`8;enlist 0b;enlist 0b];
    .pit.getPlayTrend update round:2 from .tst.pitPlays[enlist`9`6;enlist 15i;enlist`A`8;enlist 0b;enlist 0b];
    (exec round from .pit.stick) musteq 1 2;
  };
 };

.tst.desc[".pit.getPlayTrend insurance"]{
  should["flags every insured hand with the count it was taken at, since basic strategy never insures"]{
    .pit.double:.pit.split:.pit.stick:.pit.insure:();
    .pit.res:update insurance:5 0 5f from .tst.pitPlays[(`9`7;`10`8;`A`K);16 18 21i;(`A`6;`A`6;`A`6);000b;000b];
    .pit.getPlayTrend .pit.res;
    (exec cards from .pit.insure) mustmatch (`9`7;`A`K);
    (exec theCount from .pit.insure) musteq 0.5 1.5;
    (exec insurance from .pit.insure) musteq 5 5f;
  };
  should["flags nothing when nobody insures"]{
    .pit.double:.pit.split:.pit.stick:.pit.insure:();
    .pit.res:.tst.pitPlays[(`9`7;`10`8);16 18i;(`A`6;`A`6);00b;00b];
    .pit.getPlayTrend .pit.res;
    count[.pit.insure] musteq 0;
  };
  should["keeps insured hands from earlier rounds as later rounds are added"]{
    .pit.double:.pit.split:.pit.stick:.pit.insure:();
    .pit.getPlayTrend update insurance:5f from .tst.pitPlays[enlist`9`7;enlist 16i;enlist`A`6;enlist 0b;enlist 0b];
    .pit.getPlayTrend update round:2,insurance:10f from .tst.pitPlays[enlist`10`8;enlist 18i;enlist`A`K;enlist 0b;enlist 0b];
    (exec round from .pit.insure) musteq 1 2;
  };
 };

.tst.desc[".pit.recordBets"]{
  should["adds the round's scored bets to each player's history"]{
    .pit.bets:0#.pit.bets;
    .pit.window:100;
    .pit.rnd:2;
    .pit.res:([]round:1 2 2;name:`a_5`a_5`b_6;handle:5 5 6i;bet:10 20 30;basic_cnt:0 1 1f;omega_cnt:0 2 2f;perfect_cnt:0 3 3f);
    .pit.recordBets[];
    .pit.bets mustmatch([]name:`a_5`b_6;handle:5 6i;bet:20 30;basic:1 1f;omega:2 2f;perfect:3 3f);
  };
  should["keeps only each player's latest window of hands"]{
    .pit.bets:0#.pit.bets;
    .pit.window:3;
    .pit.res:([]round:1 2 3 4;name:4#`a_5;handle:4#5i;bet:10 20 30 40;basic_cnt:4#0f;omega_cnt:4#0f;perfect_cnt:4#0f);
    {.pit.rnd:x;.pit.recordBets[]}each 1 2 3 4;
    (exec bet from .pit.bets) mustmatch 20 30 40;
  };
 };

.tst.desc[".pit.correlations"]{
  should["scores each player by whichever count their bets follow most closely"]{
    .pit.bets:([]name:6#`a_5;handle:6#5i;bet:10 10 20 20 40 40;basic:6#0f;omega:0 1 0 1 0 1f;perfect:1 2 3 4 5 6f);
    s:.pit.correlations[];
    (exec hands from s) musteq enlist 6;
    (exec score from s) musteq enlist 10 10 20 20 40 40f cor 1 2 3 4 5 6f;
  };
  should["keeps each count's correlation, so they can be charted"]{
    .pit.bets:([]name:6#`a_5;handle:6#5i;bet:10 10 20 20 40 40;basic:6#0f;omega:0 1 0 1 0 1f;perfect:1 2 3 4 5 6f);
    s:.pit.correlations[];
    (exec basic from s) musteq enlist 0f;
    (exec omega from s) musteq enlist 10 10 20 20 40 40f cor 0 1 0 1 0 1f;
    (exec perfect from s) musteq enlist 10 10 20 20 40 40f cor 1 2 3 4 5 6f;
  };
  should["scores a flat bettor 0, not null"]{
    .pit.bets:([]name:3#`a_5;handle:3#5i;bet:3#20;basic:1 2 3f;omega:1 2 3f;perfect:1 2 3f);
    (exec score from .pit.correlations[]) musteq enlist 0f;
  };
 };

.tst.desc[".pit.flagged"]{
  should["flags a player once they've enough hands and their bets follow the count closely enough"]{
    .pit.minHands:20;
    .pit.suspectCor:0.5;
    `.pit.correlations mock {([name:`a_5`b_6`c_7;handle:5 6 7i]hands:25 25 10;score:0.6 0.3 0.9)};
    (exec name from .pit.flagged[]) mustmatch enlist`a_5;
  };
 };

.tst.desc[".pit.updateStreaks"]{
  should["counts the rounds in a row each player has been flagged, resetting anyone who isn't"]{
    `.pit.correlations mock {([name:`a_5`b_6`c_7;handle:5 6 7i]hands:25 25 25;score:0.6 0.3 0.9)};
    `.pit.flagged mock {([name:`a_5`c_7;handle:5 7i]hands:25 25;score:0.6 0.9)};
    .pit.streak:`a_5`b_6!2 4;
    .pit.updateStreaks[];
    .pit.streak mustmatch`a_5`b_6`c_7!3 0 1;
  };
  should["forgets a player who has no scores any more"]{
    `.pit.correlations mock {([name:enlist`a_5;handle:enlist 5i]hands:enlist 25;score:enlist 0.6)};
    `.pit.flagged mock {([name:enlist`a_5;handle:enlist 5i]hands:enlist 25;score:enlist 0.6)};
    .pit.streak:`a_5`gone_9!1 7;
    .pit.updateStreaks[];
    .pit.streak mustmatch enlist[`a_5]!enlist 2;
  };
 };

.tst.desc[".pit.suspects"]{
  should["only suspects a player who has stayed flagged for .pit.persist rounds in a row"]{
    .pit.persist:5;
    `.pit.flagged mock {([name:`a_5`c_7;handle:5 7i]hands:25 25;score:0.6 0.9)};
    .pit.streak:`a_5`c_7!5 4;
    (exec name from .pit.suspects[]) mustmatch enlist`a_5;
  };
 };

.tst.desc[".pit.report"]{
  should["asks the server to eject the player, and starts their history afresh"]{
    .tst.ejected:();
    `.bjk.eject mock {.tst.ejected,:x};
    `.log.warn mock {[x]};
    .pit.h:0i;
    .pit.bets:([]name:`a_5`b_6;handle:5 6i;bet:10 20;basic:0 0f;omega:0 0f;perfect:0 0f);
    .pit.streak:`a_5`b_6!5 3;
    .pit.report`name`handle`hands`score!(`a_5;5i;25;0.6);
    .tst.ejected mustmatch enlist 5i;
    .pit.streak mustmatch enlist[`b_6]!enlist 3;
    (exec name from .pit.bets) mustmatch enlist`b_6;
  };
  should["logs the suspicion with the evidence"]{
    .tst.logged:();
    `.log.warn mock {.tst.logged,:enlist x};
    `.bjk.eject mock {};
    .pit.h:0i;
    .pit.bets:0#.pit.bets;
    .pit.report`name`handle`hands`score!(`a_5;5i;25;0.6);
    .tst.logged mustlike"Suspected card counter: a_5 (bets follow the count, correlation 0.60 over 25 hands)";
  };
 };

.tst.desc[".pit.getDetect suspects"]{
  should["reports each suspect after scoring the round"]{
    `.pit.getBetTrend mock {};
    `.pit.recordScores mock {};
    `.pit.getPlayTrend mock {};
    `.pit.updateStreaks mock {};
    .tst.reported:();
    `.pit.report mock {.tst.reported,:enlist x`name};
    `.pit.suspects mock {([]name:`a_5`c_7;handle:5 7i;hands:25 30;score:0.6 0.7)};
    .pit.res:([]round:enlist 1);
    .pit.getDetect enlist 1;
    .tst.reported mustmatch`a_5`c_7;
  };
 };

.tst.desc[".pit.recordScores"]{
  should["adds each player's scores for the round, stamped with the time it was played"]{
    .pit.scores:0#.pit.scores;
    .pit.rnd:7;
    `.pit.correlations mock {([name:`a_5`b_6;handle:5 6i]hands:20 25;basic:.1 .2;omega:.3 .4;perfect:.5 .6;score:.5 .6)};
    t0:.z.p;
    .pit.recordScores[];
    (exec name from .pit.scores) mustmatch`a_5`b_6;
    (exec round from .pit.scores) mustmatch 7 7;
    (exec perfect from .pit.scores) mustmatch .5 .6;
    (all (exec time from .pit.scores) within t0,.z.p) musteq 1b;
  };
 };

.tst.desc[".pit.chart"]{
  should["gives nothing to chart before any round has been scored"]{
    .pit.scores:0#.pit.scores;
    .pit.chart[] mustmatch();
  };
  should["charts each player's score under each count against the time it was played, with the suspicion line"]{
    .pit.suspectCor:0.5;
    t0:2026.10.01D12:00:00;
    .pit.scores:([]time:t0,t0,t0+0D00:00:01;round:1 1 2;name:`a_5`b_6`a_5;handle:5 6 5i;hands:20 20 21;basic:.1 .2 .3;omega:.4 .5 .6;perfect:.7 .8 .9;score:.7 .8 .9);
    c:.pit.chart[];
    cols[c] mustmatch`time`a_5_basic`b_6_basic`a_5_omega`b_6_omega`a_5_perfect`b_6_perfect`alert;
    c[`time] mustmatch(t0;t0+0D00:00:01);
    c[`a_5_perfect] mustmatch .7 .9;
    c[`b_6_basic] mustmatch .2 0n;
    c[`alert] mustmatch .5 .5;
  };
 };
