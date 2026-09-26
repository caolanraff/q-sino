system "l src/server/bin/detectionAlgo.q";

/ two players' rows for one round, each carrying its own copy of the dealer's hand d
.tst.daRound:{[r;c1;c2;d]([]round:r,r;player:1 2;name:`a_5`b_6;handle:5 6i;cards:(c1;c2);cnt:0 0i;dealer:(d;d);dealerCnt:0 0i;bet:10 20;return:0 0f;profit:0 0f;split:00b;double:00b)};

.tst.desc[".da.cardsSeen"]{
  should["counts the dealer's cards once per round, however many player rows repeat them"]{
    t:.tst.daRound[1;`K`5;`2`3`4;`10`8],.tst.daRound[2;`A`9;`6`6;`7`K];
    (asc .da.cardsSeen t) mustmatch asc `K`5`2`3`4`10`8`A`9`6`6`7`K;
    };
  should["takes the longest dealer hand in a round, since a forfeit row only holds the up-card"]{
    t:([]round:3 3;cards:(`K`6;`9`10);dealer:(enlist`9;`9`8));
    (asc .da.cardsSeen t) mustmatch asc `K`6`9`10`9`8;
    };
  should["ignores seats with no cards dealt yet"]{
    t:([]round:0N 0N;cards:(();());dealer:``);
    (count .da.cardsSeen t) musteq 0;
    };
 };

.tst.desc[".da.count"]{
  should["gives the true count with each card seen counted once"]{
    .da.startCards:312;
    t:.tst.daRound[1;`K`5;`2`3`4;`10`8];  / basic: K5 234 = +3, dealer 10 8 once = -1; 7 cards seen
    .da.count[.da.basic;t] musteq 2%(312-7)%52;
    };
 };

.tst.desc[".da.gameover"]{
  should["holds each round once, though the server re-sends the whole shoe every round"]{
    `.da.getPlayTrend mock {};
    .da.startCards:312; .da.res:([]round:`long$()); .da.betTrend:0#.da.betTrend;
    r1:.tst.daRound[1;`K`5;`2`3`4;`10`8];
    r2:r1,.tst.daRound[2;`A`9;`6`6;`7`K];
    .bs.rnd:1; .da.gameover[r1];
    .bs.rnd:2; .da.gameover[r2];
    (exec round from .da.res) musteq 1 1 2 2;
    };
  should["scores each round's bets against the count from earlier rounds only"]{
    `.da.getPlayTrend mock {};
    .da.startCards:312; .da.res:([]round:`long$()); .da.betTrend:0#.da.betTrend;
    r1:.tst.daRound[1;`K`5;`2`3`4;`10`8];
    r2:r1,.tst.daRound[2;`A`9;`6`6;`7`K];
    .bs.rnd:1; .da.gameover[r1];
    .bs.rnd:2; .da.gameover[r2];
    (exec basic_cnt from .da.res where round=1) musteq 0 0f;
    (exec basic_cnt from .da.res where round=2) musteq 2 2*1%(312-7)%52;
    };
 };
