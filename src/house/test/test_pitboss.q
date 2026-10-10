.utl.load`:src/house/bin/pitboss.q;

.tst.uid:{"G"$"00000000-0000-0000-0000-",-12#"00000000000",string x};

/ .tst.pitRound[1;`K`5;`2`3`4;`10`8]
.tst.pitRound:{[r;c1;c2;d]([]round:r,r;player:1 2;name:`a_5`b_6;handle:5 6i;uid:.tst.uid each 5 6;cards:(c1;c2);cnt:0i;dealer:(d;d);dealerCnt:0i;bet:10 20;return:0f;profit:0f;split:0b;double:0b;insurance:0f;forced:0b)};

.tst.desc[".pit.count"]{
  should["gives the true count with each card seen counted once"]{
    .pit.startCards:312;
    t:.tst.pitRound[1;`K`5;`2`3`4;`10`8];                                                           / basic: K5 234 = +3, dealer 10 8 once = -1; 7 cards seen
    .pit.count[.crd.hiLo;t] musteq 2%(312-7)%52;
  };
 };

.tst.desc[".pit.gameover"]{
  before{
    .pit.res:([]round:"j"$());
  };
  should["holds each round once, though the server re-sends the whole shoe every round"]{
    `.pit.getPlayTrend mock {};
    .pit.startCards:312;
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
    .pit.betTrend:0#.pit.betTrend;
    r1:.tst.pitRound[1;`K`5;`2`3`4;`10`8];
    r2:r1,.tst.pitRound[2;`A`9;`6`6;`7`K];
    .pit.gameover[`res`rnd!(r1;1)];
    .pit.gameover[`res`rnd!(r2;2)];
    (exec basic_cnt from .pit.res where round=1) musteq 0 0f;
    (exec basic_cnt from .pit.res where round=2) musteq 2 2*1%(312-7)%52;
  };
  should["counts every round it's sent at once, so joining mid-shoe scores the shoe so far"]{
    `.pit.getPlayTrend mock {};
    .pit.startCards:312;
    .pit.window:100;
    .pit.betTrend:0#.pit.betTrend;
    .pit.bets:0#.pit.bets;
    r:.tst.pitRound[1;`K`5;`2`3`4;`10`8],.tst.pitRound[2;`A`9;`6`6;`7`K];
    .pit.gameover[`res`rnd!(r;2)];
    (exec basic_cnt from .pit.res where round=1) musteq 0 0f;
    (exec basic_cnt from .pit.res where round=2) musteq 2 2*1%(312-7)%52;
    (exec bet from .pit.bets) musteq 10 20 10 20;
  };
  should["examines only the new round's hands, though the server re-sends the whole shoe"]{
    `.pit.getBetTrend mock {};
    .tst.examined:();
    `.pit.getPlayTrend mock {.tst.examined,:enlist exec distinct round from x};
    r1:.tst.pitRound[1;`K`5;`2`3`4;`10`8];
    .pit.gameover[`res`rnd!(r1;1)];
    .pit.gameover[`res`rnd!(r1,.tst.pitRound[2;`A`9;`6`6;`7`K];2)];
    .tst.examined mustmatch(enlist 1;enlist 2);
  };
  should["reports each tell once, and keeps an earlier shoe's tells after a shuffle"]{
    .pit.startCards:312;
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
  before{
    `.pit.getPlayTrend mock {};
    .pit.startCards:312;
    .pit.res:([]round:"j"$());
    .pit.betTrend:0#.pit.betTrend;
  };
  should["scores a flat bettor's correlation as 0 on every count, not just basic"]{
    r1:.tst.pitRound[1;`K`5;`2`3`4;`10`8];
    .pit.gameover[`res`rnd!(r1;1)];
    .pit.gameover[`res`rnd!(r1,.tst.pitRound[2;`A`9;`6`6;`7`K];2)];
    (exec basic_cor from .pit.betTrend where round=2) musteq 0 0f;
    (exec omega_cor from .pit.betTrend where round=2) musteq 0 0f;
    (exec perfect_cor from .pit.betTrend where round=2) musteq 0 0f;
  };
  should["keeps a real correlation"]{
    r1:.tst.pitRound[1;`K`5;`2`3`4;`10`8];
    .pit.gameover[`res`rnd!(r1;1)];
    .pit.gameover[`res`rnd!(r1,update bet:30 20 from .tst.pitRound[2;`A`9;`6`6;`7`K];2)];
    (exec basic_cor from .pit.betTrend where round=2,name=`a_5) musteq 1f;
    (exec omega_cor from .pit.betTrend where round=2,name=`a_5) musteq 1f;
    (exec perfect_cor from .pit.betTrend where round=2,name=`a_5) musteq 1f;
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
.tst.pitPlays:{[c;n;d;dbl;spl]([]round:1+til count c;name:`a_5;uid:.tst.uid 5;cards:c;cnt:n;dealer:d;double:dbl;split:spl;insurance:0f;forced:0b;basic_cnt:0.5*1+til count c)};

.tst.desc[".pit.getPlayTrend doubles"]{
  before{
    .pit.double:.pit.split:.pit.stick:.pit.insure:();
  };
  should["flags doubling 18-20 that basic strategy wouldn't"]{
    .pit.res:.tst.pitPlays[(`A`7`2;`A`8`9;`A`9`3;`10`8`2);21 18 13 20i;(`7`K;`5`K;`4`3;`6`K);1111b;0000b];
    .pit.getPlayTrend .pit.res;
    (exec cards from .pit.double) mustmatch (`A`7`2;`A`8`9;`A`9`3;`10`8`2);                         / soft 18 vs 7, soft 19 vs 5, soft 20, hard 18
  };
  should["leaves out soft 18 vs 2-6 and soft 19 vs 6, which basic strategy doubles"]{
    .pit.res:.tst.pitPlays[(`A`7`3;`A`7`2;`A`8`2);21 20 21i;(`2`K;`6`K;`6`K);111b;000b];
    .pit.getPlayTrend .pit.res;
    count[.pit.double] musteq 0;
  };
 };

.tst.desc[".pit.getPlayTrend sticks"]{
  before{
    .pit.double:.pit.split:.pit.stick:.pit.insure:();
  };
  should["flags sticking on a two-card hard 15/16 against 7-A"]{
    .pit.res:.tst.pitPlays[(`10`6;`9`6;`10`5);16 15 15i;(`10`8;`7`K;`A`6);000b;000b];
    .pit.getPlayTrend .pit.res;
    count[.pit.stick] musteq 3;
  };
  should["leaves out sticking on hard 15/16 against 2-6, which basic strategy does"]{
    .pit.res:.tst.pitPlays[(`10`6;`9`6);16 15i;(`6`K;`2`K);00b;00b];
    .pit.getPlayTrend .pit.res;
    count[.pit.stick] musteq 0;
  };
  should["flags sticking on a soft 15/16 against any up-card"]{
    .pit.res:.tst.pitPlays[(`A`5;`A`4);16 15i;(`6`K;`2`K);00b;00b];
    .pit.getPlayTrend .pit.res;
    count[.pit.stick] musteq 2;
  };
  should["leaves out split aces, which stick by rule"]{
    .pit.res:.tst.pitPlays[enlist`A`5;enlist 16i;enlist`9`K;enlist 0b;enlist 1b];
    .pit.getPlayTrend .pit.res;
    count[.pit.stick] musteq 0;
  };
  should["leaves out a round the dealer's blackjack ended, where nobody got to play"]{
    .pit.res:.tst.pitPlays[(`10`6;`A`5);16 16i;(`A`K;`10`A);00b;00b];
    .pit.getPlayTrend .pit.res;
    count[.pit.stick] musteq 0;
  };
  should["leaves out a hand the turn clock stuck or a leaver forfeited, which the player didn't choose"]{
    .pit.res:update forced:1b from .tst.pitPlays[(`10`6;`A`5);16 16i;(`10`8;`2`K);00b;00b];
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
  before{
    .pit.double:.pit.split:.pit.stick:.pit.insure:();
  };
  should["reports the basic count the round was played at, not a constant"]{
    .pit.res:.tst.pitPlays[(`A`9`3;`10`6);13 16i;(`4`3;`10`8);10b;00b];
    .pit.getPlayTrend .pit.res;
    (exec theCount from .pit.double) musteq enlist 0.5;
    (exec theCount from .pit.stick) musteq enlist 1f;
  };
  should["keeps earlier rounds' tells as later rounds are added"]{
    .pit.getPlayTrend .tst.pitPlays[enlist`10`6;enlist 16i;enlist`10`8;enlist 0b;enlist 0b];
    .pit.getPlayTrend update round:2 from .tst.pitPlays[enlist`9`6;enlist 15i;enlist`A`8;enlist 0b;enlist 0b];
    (exec round from .pit.stick) musteq 1 2;
  };
 };

.tst.desc[".pit.getPlayTrend insurance"]{
  before{
    .pit.double:.pit.split:.pit.stick:.pit.insure:();
  };
  should["flags every insured hand with the count it was taken at, since basic strategy never insures"]{
    .pit.res:update insurance:5 0 5f from .tst.pitPlays[(`9`7;`10`8;`A`K);16 18 21i;(`A`6;`A`6;`A`6);000b;000b];
    .pit.getPlayTrend .pit.res;
    (exec cards from .pit.insure) mustmatch (`9`7;`A`K);
    (exec theCount from .pit.insure) musteq 0.5 1.5;
    (exec insurance from .pit.insure) musteq 5 5f;
  };
  should["flags nothing when nobody insures"]{
    .pit.res:.tst.pitPlays[(`9`7;`10`8);16 18i;(`A`6;`A`6);00b;00b];
    .pit.getPlayTrend .pit.res;
    count[.pit.insure] musteq 0;
  };
  should["keeps insured hands from earlier rounds as later rounds are added"]{
    .pit.getPlayTrend update insurance:5f from .tst.pitPlays[enlist`9`7;enlist 16i;enlist`A`6;enlist 0b;enlist 0b];
    .pit.getPlayTrend update round:2,insurance:10f from .tst.pitPlays[enlist`10`8;enlist 18i;enlist`A`K;enlist 0b;enlist 0b];
    (exec round from .pit.insure) musteq 1 2;
  };
 };

.tst.desc[".pit.recordBets"]{
  before{
    .pit.bets:0#.pit.bets;
  };
  should["adds the round's scored bets to each player's history"]{
    .pit.window:100;
    .pit.rnd:2;
    .pit.res:([]round:1 2 2;name:`a_5`a_5`b_6;uid:.tst.uid each 5 5 6;bet:10 20 30;basic_cnt:0 1 1f;omega_cnt:0 2 2f;perfect_cnt:0 3 3f;insurance:0f);
    .pit.recordBets enlist 2;
    .pit.bets mustmatch([]name:`a_5`b_6;uid:.tst.uid each 5 6;bet:20 30;basic:1f;omega:2f;perfect:3f);
  };
  should["keeps every round it's given, such as a whole shoe when the pitboss joins mid-shoe"]{
    .pit.window:100;
    .pit.res:([]round:1 2 3;name:`a_5;uid:.tst.uid 5;bet:10 20 30;basic_cnt:0 1 2f;omega_cnt:0f;perfect_cnt:0f;insurance:0f);
    .pit.recordBets 1 2 3;
    (exec bet from .pit.bets) mustmatch 10 20 30;
  };
  should["keeps only each player's latest window of hands"]{
    .pit.window:3;
    .pit.res:([]round:1 2 3 4;name:`a_5;uid:.tst.uid 5;bet:10 20 30 40;basic_cnt:0f;omega_cnt:0f;perfect_cnt:0f;insurance:0f);
    {.pit.recordBets enlist x}each 1 2 3 4;
    (exec bet from .pit.bets) mustmatch 20 30 40;
  };
 };

.tst.desc[".pit.correlations"]{
  should["scores each player by whichever count their bets follow most closely"]{
    .pit.bets:([]name:`a_5;uid:.tst.uid 5;bet:10 10 20 20 40 40;basic:0f;omega:0 1 0 1 0 1f;perfect:1 2 3 4 5 6f);
    s:.pit.correlations[];
    (exec hands from s) musteq enlist 6;
    (exec score from s) musteq enlist 10 10 20 20 40 40f cor 1 2 3 4 5 6f;
  };
  should["keeps each count's correlation, so they can be charted"]{
    .pit.bets:([]name:`a_5;uid:.tst.uid 5;bet:10 10 20 20 40 40;basic:0f;omega:0 1 0 1 0 1f;perfect:1 2 3 4 5 6f);
    s:.pit.correlations[];
    (exec basic from s) musteq enlist 0f;
    (exec omega from s) musteq enlist 10 10 20 20 40 40f cor 0 1 0 1 0 1f;
    (exec perfect from s) musteq enlist 10 10 20 20 40 40f cor 1 2 3 4 5 6f;
  };
  should["scores a flat bettor 0, not null"]{
    .pit.bets:([]name:`a_5;uid:.tst.uid 5;bet:20;basic:1 2 3f;omega:1 2 3f;perfect:1 2 3f);
    (exec score from .pit.correlations[]) musteq enlist 0f;
  };
 };

.tst.desc[".pit.flagged"]{
  should["flags a player once they've enough hands and their bets follow the count closely enough"]{
    .pit.minHands:20;
    .pit.suspectCor:0.5;
    `.pit.insurers mock {([name:`$();uid:"g"$()]insures:"j"$())};
    `.pit.ramps mock {([name:`$();uid:"g"$()]good:"j"$();bad:"j"$();ramp:"f"$())};
    `.pit.correlations mock {([name:`a_5`b_6`c_7;uid:.tst.uid each 5 6 7]hands:25 25 10;score:0.6 0.3 0.9)};
    (exec name from .pit.flagged[]) mustmatch enlist`a_5;
  };
 };

.tst.desc[".pit.updateStreaks"]{
  should["counts the rounds in a row each player has been flagged, resetting anyone who isn't"]{
    `.pit.correlations mock {([name:`a_5`b_6`c_7;uid:.tst.uid each 5 6 7]hands:25;score:0.6 0.3 0.9)};
    `.pit.flagged mock {([name:`a_5`c_7;uid:.tst.uid each 5 7]hands:25;score:0.6 0.9)};
    .pit.streak:(.tst.uid each 5 6)!2 4;
    .pit.updateStreaks[];
    .pit.streak mustmatch(.tst.uid each 5 6 7)!3 0 1;
  };
  should["forgets a player who has no scores any more"]{
    `.pit.correlations mock {([name:enlist`a_5;uid:.tst.uid 5]hands:enlist 25;score:0.6)};
    `.pit.flagged mock {([name:enlist`a_5;uid:.tst.uid 5]hands:enlist 25;score:0.6)};
    .pit.streak:(.tst.uid each 5 9)!1 7;
    .pit.updateStreaks[];
    .pit.streak mustmatch enlist[.tst.uid 5]!enlist 2;
  };
 };

.tst.desc[".pit.suspects"]{
  should["only suspects a player who has stayed flagged for .pit.persist rounds in a row"]{
    .pit.persist:5;
    `.pit.flagged mock {([name:`a_5`c_7;uid:.tst.uid each 5 7]hands:25;score:0.6 0.9)};
    .pit.streak:(.tst.uid each 5 7)!5 4;
    (exec name from .pit.suspects[]) mustmatch enlist`a_5;
  };
 };

.tst.desc[".pit.report"]{
  before{
    .pit.h:0i;
  };
  should["asks the server to eject the player, and starts their history afresh"]{
    .tst.ejected:();
    `.bjk.eject mock {.tst.ejected,:x};
    `.log.warn mock {[x]};
    .pit.bets:([]name:`a_5`b_6;uid:.tst.uid each 5 6;bet:10 20;basic:0f;omega:0f;perfect:0f);
    .pit.streak:(.tst.uid each 5 6)!5 3;
    .pit.insured:([]name:`a_5`b_6;uid:.tst.uid each 5 6;basic:3 4f);
    .pit.report`name`uid`hands`score`insures`ramp!(`a_5;.tst.uid 5;25;0.6;0N;2.5);
    .tst.ejected mustmatch enlist .tst.uid 5;
    (exec name from .pit.insured) mustmatch enlist`b_6;
    .pit.streak mustmatch enlist[.tst.uid 6]!enlist 3;
    (exec name from .pit.bets) mustmatch enlist`b_6;
  };
  should["keeps the history of a newcomer given the reported player's handle, and so their name"]{
    `.bjk.eject mock {};
    `.log.warn mock {[x]};
    .pit.bets:([]name:`a_5`a_5;uid:.tst.uid each 5 15;bet:10 20;basic:0f;omega:0f;perfect:0f);
    .pit.streak:(.tst.uid each 5 15)!5 1;
    .pit.insured:([]name:`a_5`a_5;uid:.tst.uid each 5 15;basic:3 4f);
    .pit.report`name`uid`hands`score`insures`ramp!(`a_5;.tst.uid 5;25;0.6;0N;2.5);
    (exec uid from .pit.bets) mustmatch enlist .tst.uid 15;
    (exec uid from .pit.insured) mustmatch enlist .tst.uid 15;
    .pit.streak mustmatch enlist[.tst.uid 15]!enlist 1;
  };
  should["logs the suspicion with the evidence"]{
    .tst.logged:();
    `.log.warn mock {.tst.logged,:enlist x};
    `.bjk.eject mock {};
    .pit.bets:0#.pit.bets;
    .pit.report`name`uid`hands`score`insures`ramp!(`a_5;.tst.uid 5;25;0.6;0N;2.5);
    .tst.logged mustlike"Suspected card counter: a_5 (bet/count correlation 0.60 over 25 hands; bets 2.5x as much at a good count; insured only at a high count 0 times)";
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
    `.pit.suspects mock {([]name:`a_5`c_7;uid:.tst.uid each 5 7;hands:25 30;score:0.6 0.7)};
    .pit.res:([]round:enlist 1);
    .pit.getDetect enlist 1;
    .tst.reported mustmatch`a_5`c_7;
  };
 };

.tst.desc[".pit.recordScores"]{
  should["adds each player's scores for the round, stamped with the time it was played"]{
    .pit.scores:0#.pit.scores;
    .pit.rnd:7;
    .pit.res:([]round:7;uid:.tst.uid each 5 6);
    `.pit.correlations mock {([name:`a_5`b_6;uid:.tst.uid each 5 6]hands:20 25;basic:.1 .2;omega:.3 .4;perfect:.5 .6;score:.5 .6)};
    t0:.z.p;
    .pit.recordScores[];
    (exec name from .pit.scores) mustmatch`a_5`b_6;
    (exec round from .pit.scores) mustmatch 7 7;
    (exec perfect from .pit.scores) mustmatch .5 .6;
    (all (exec time from .pit.scores) within t0,.z.p) musteq 1b;
  };
  should["leaves out a player who has left, so the chart shows the newcomer given their handle and name"]{
    .pit.scores:0#.pit.scores;
    .pit.suspectCor:0.5;
    .pit.rnd:7;
    .pit.res:([]round:6 7;uid:.tst.uid each 5 15);
    `.pit.correlations mock {([name:`a_5`a_5;uid:.tst.uid each 5 15]hands:20 25;basic:.1 .2;omega:.3 .4;perfect:.5 .6;score:.5 .6)};
    .pit.recordScores[];
    (exec uid from .pit.scores) mustmatch enlist .tst.uid 15;
    .pit.chart[][`a_5_perfect] mustmatch enlist .6;
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
    .pit.scores:([]time:t0,t0,t0+0D00:00:01;round:1 1 2;name:`a_5`b_6`a_5;uid:.tst.uid each 5 6 5;hands:20 20 21;basic:.1 .2 .3;omega:.4 .5 .6;perfect:.7 .8 .9;score:.7 .8 .9);
    c:.pit.chart[];
    cols[c] mustmatch`time`a_5_basic`b_6_basic`a_5_omega`b_6_omega`a_5_perfect`b_6_perfect`alert;
    c[`time] mustmatch(t0;t0+0D00:00:01);
    c[`a_5_perfect] mustmatch .7 .9;
    c[`b_6_basic] mustmatch .2 0n;
    c[`alert] mustmatch .5 .5;
  };
 };

.tst.desc[".pit.betTrend"]{
  should["has lowercase round, name and uid columns"]{
    (3#cols .pit.betTrend)mustmatch`round`name`uid;
  };
 };

.tst.desc[".pit.recordBets insurance"]{
  should["records each insured hand with the Hi-Lo count it was bet at"]{
    .pit.bets:0#.pit.bets;
    .pit.insured:0#.pit.insured;
    .pit.window:100;
    .pit.rnd:2;
    .pit.res:([]round:2;name:`a_5`b_6;uid:.tst.uid each 5 6;bet:10 20;basic_cnt:3.5 1f;omega_cnt:0f;perfect_cnt:0f;insurance:5 0f);
    .pit.recordBets enlist 2;
    .pit.insured mustmatch([]name:enlist`a_5;uid:.tst.uid 5;basic:3.5);
  };
 };

.tst.desc[".pit.insurers"]{
  should["lists players who've only ever insured at a high count, with how often"]{
    .pit.insureCount:3;
    .pit.insured:([]name:`a_5`a_5`b_6`b_6;uid:.tst.uid each 5 5 6 6;basic:3 4.5 3 -1f);
    s:0!.pit.insurers[];
    (exec name from s) mustmatch enlist`a_5;
    (exec insures from s) musteq enlist 2;
  };
 };

.tst.desc[".pit.flagged insurance"]{
  before{
    .pit.minHands:20;.pit.suspectCor:0.5;.pit.minInsures:2;.pit.minRampHands:5;.pit.minRamp:1.5;
    `.pit.ramps mock {([name:`$();uid:"g"$()]good:"j"$();bad:"j"$();ramp:"f"$())};
  };
  should["flags a player who only insures at a high count, even if their bets don't follow the count"]{
    `.pit.correlations mock {([name:enlist`a_5;uid:.tst.uid 5]hands:enlist 25;score:0.1)};
    `.pit.insurers mock {([name:enlist`a_5;uid:.tst.uid 5]insures:enlist 2;highOnly:1b)};
    (exec name from .pit.flagged[]) mustmatch enlist`a_5;
  };
  should["doesn't flag a player with too few high-count insurances"]{
    `.pit.correlations mock {([name:enlist`a_5;uid:.tst.uid 5]hands:enlist 25;score:0.1)};
    `.pit.insurers mock {([name:enlist`a_5;uid:.tst.uid 5]insures:enlist 1;highOnly:1b)};
    count[.pit.flagged[]] musteq 0;
  };
  should["still flags on the bet/count correlation alone"]{
    `.pit.correlations mock {([name:enlist`a_5;uid:.tst.uid 5]hands:enlist 25;score:0.6)};
    `.pit.insurers mock {([name:`$();uid:"g"$()]insures:"j"$();highOnly:"b"$())};
    (exec name from .pit.flagged[]) mustmatch enlist`a_5;
  };
 };

.tst.desc[".pit.ramps"]{
  should["compares each player's average bet at a good count with a bad one"]{
    .pit.goodCount:2;
    .pit.badCount:0;
    .pit.bets:([]name:`a_5;uid:.tst.uid 5;bet:10 10 20 40 40 20;basic:-1 0 1 2 3 0.5;omega:0f;perfect:0f);
    s:0!.pit.ramps[];
    (exec good from s) musteq enlist 2;
    (exec bad from s) musteq enlist 2;
    (exec ramp from s) musteq enlist 4f;
  };
 };

.tst.desc[".pit.flagged bet ramp"]{
  before{
    .pit.minHands:20;.pit.suspectCor:0.5;.pit.minInsures:2;.pit.minRampHands:5;.pit.minRamp:1.5;
    `.pit.correlations mock {([name:enlist`a_5;uid:.tst.uid 5]hands:enlist 25;score:0.2)};
    `.pit.insurers mock {([name:`$();uid:"g"$()]insures:"j"$())};
  };
  should["flags a player who bets clearly more at a good count, even if they've never insured"]{
    `.pit.ramps mock {([name:enlist`a_5;uid:.tst.uid 5]good:enlist 6;bad:9;ramp:3f)};
    (exec name from .pit.flagged[]) mustmatch enlist`a_5;
  };
  should["doesn't flag on too few bets at a good or a bad count"]{
    `.pit.ramps mock {([name:enlist`a_5;uid:.tst.uid 5]good:enlist 4;bad:9;ramp:3f)};
    count[.pit.flagged[]] musteq 0;
  };
  should["doesn't flag a player whose bets barely change with the count"]{
    `.pit.ramps mock {([name:enlist`a_5;uid:.tst.uid 5]good:enlist 6;bad:9;ramp:1.2)};
    count[.pit.flagged[]] musteq 0;
  };
 };

.tst.desc[".pit.flagged bet ramp defaults"]{
  before{
    .utl.load`:src/house/bin/pitboss.q;
    `.pit.correlations mock {([name:enlist`a_5;uid:.tst.uid 5]hands:enlist 100;score:0.3)};
    `.pit.insurers mock {([name:`$();uid:"g"$()]insures:"j"$())};
  };
  should["doesn't flag a player who presses their wins, whose bets run about twice as big at a good count"]{
    `.pit.ramps mock {([name:enlist`a_5;uid:.tst.uid 5]good:enlist 15;bad:60;ramp:2f)};
    count[.pit.flagged[]] musteq 0;
  };
  should["flags a counter who spreads their bets"]{
    `.pit.ramps mock {([name:enlist`a_5;uid:.tst.uid 5]good:enlist 15;bad:60;ramp:4f)};
    (exec name from .pit.flagged[]) mustmatch enlist`a_5;
  };
 };

.tst.desc[".pit.flagged bet correlation defaults"]{
  before{
    .utl.load`:src/house/bin/pitboss.q;
    `.pit.insurers mock {([name:`$();uid:"g"$()]insures:"j"$())};
    `.pit.ramps mock {([name:`$();uid:"g"$()]good:"j"$();bad:"j"$();ramp:"f"$())};
  };
  should["doesn't flag bets that follow the count only as far as wins and losses do"]{
    `.pit.correlations mock {([name:enlist`a_5;uid:.tst.uid 5]hands:enlist 40;score:0.5)};
    count[.pit.flagged[]] musteq 0;
  };
  should["flags bets that follow the count closely"]{
    `.pit.correlations mock {([name:enlist`a_5;uid:.tst.uid 5]hands:enlist 40;score:0.8)};
    (exec name from .pit.flagged[]) mustmatch enlist`a_5;
  };
 };

.tst.desc[".pit.forget"]{
  before{
    .pit.bets:([]name:`a_5`b_6;uid:.tst.uid each 5 6;bet:10 20;basic:0f;omega:0f;perfect:0f);
    .pit.insured:([]name:`a_5`b_6;uid:.tst.uid each 5 6;basic:3 4f);
    .pit.streak:(.tst.uid each 5 6)!3 4;
    .pit.gone:"g"$();
  };
  should["forgets the bets, insurance and streak of players who have left, and no one else"]{
    .pit.left .tst.uid 5;
    .pit.forget[];
    (exec uid from .pit.bets) mustmatch enlist .tst.uid 6;
    (exec uid from .pit.insured) mustmatch enlist .tst.uid 6;
    .pit.streak mustmatch enlist[.tst.uid 6]!enlist 4;
    count[.pit.gone] musteq 0;
  };
  should["forgets nothing when no one has left"]{
    .pit.forget[];
    count[.pit.bets] musteq 2;
    count[.pit.streak] musteq 2;
  };
 };

.tst.desc[".pit.left"]{
  should["forgets a leaver's hands that arrive after they've gone, like a forfeit"]{
    `.pit.getPlayTrend mock {};
    `.pit.report mock {};
    .pit.startCards:312;
    .pit.window:100;
    .pit.res:([]round:"j"$());
    .pit.betTrend:0#.pit.betTrend;
    .pit.bets:0#.pit.bets;
    .pit.insured:0#.pit.insured;
    .pit.streak:("g"$())!"j"$();
    .pit.gone:"g"$();
    .pit.left .tst.uid 5;
    .pit.gameover[`res`rnd!(.tst.pitRound[1;`K`5;`2`3`4;`10`8];1)];
    (exec uid from .pit.bets) mustmatch enlist .tst.uid 6;
    (key .pit.streak) mustmatch enlist .tst.uid 6;
  };
  should["doesn't report a suspect who has left"]{
    .tst.reported:();
    `.pit.report mock {.tst.reported,:enlist x`uid};
    `.pit.getBetTrend mock {};
    `.pit.recordScores mock {};
    `.pit.getPlayTrend mock {};
    .pit.persist:5;
    .pit.res:([]round:enlist 1);
    .pit.gone:"g"$();
    .pit.bets:([]name:`a_5;uid:.tst.uid 5;bet:10*1+til 25;basic:1f*til 25;omega:0f;perfect:0f);
    .pit.insured:0#.pit.insured;
    .pit.streak:enlist[.tst.uid 5]!enlist 9;
    .pit.left .tst.uid 5;
    .pit.getDetect enlist 1;
    count[.tst.reported] musteq 0;
  };
 };
