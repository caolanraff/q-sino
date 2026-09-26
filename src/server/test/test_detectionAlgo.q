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
    .da.gameover[`res`rnd!(r1;1)];
    .da.gameover[`res`rnd!(r2;2)];
    (exec round from .da.res) musteq 1 1 2 2;
    };
  should["scores each round's bets against the count from earlier rounds only"]{
    `.da.getPlayTrend mock {};
    .da.startCards:312; .da.res:([]round:`long$()); .da.betTrend:0#.da.betTrend;
    r1:.tst.daRound[1;`K`5;`2`3`4;`10`8];
    r2:r1,.tst.daRound[2;`A`9;`6`6;`7`K];
    .da.gameover[`res`rnd!(r1;1)];
    .da.gameover[`res`rnd!(r2;2)];
    (exec basic_cnt from .da.res where round=1) musteq 0 0f;
    (exec basic_cnt from .da.res where round=2) musteq 2 2*1%(312-7)%52;
    };
 };

.tst.desc[".da.shoeSize"]{
  should["reports a full shoe, not the cards left in the deck"]{
    .bs.deckCnt:6;
    .bs.deck:10#`2;  / mid-shoe: only 10 cards left
    .da.shoeSize[0] musteq 312;  / handle 0 evaluates the query in this process
    };
 };

/ one result row per hand for .da.getPlayTrend: cards, final count, dealer's hand, and whether it doubled/split
.tst.daPlays:{[c;n;d;dbl;spl]([]round:1+til count c;name:(count c)#`a_5;handle:(count c)#5i;cards:c;cnt:n;dealer:d;double:dbl;split:spl;surrender:(count c)#0b;basic_cnt:0.5*1+til count c)};

.tst.desc[".da.getPlayTrend doubles"]{
  should["flags doubling 18-20 that basic strategy wouldn't"]{
    .da.hist:(); .da.res:.tst.daPlays[(`A`7`2;`A`8`9;`A`9`3;`10`8`2);21 18 13 20i;(`7`K;`5`K;`4`3;`6`K);1111b;0000b];
    .da.getPlayTrend[];
    (exec cards from .da.double) mustmatch (`A`7`2;`A`8`9;`A`9`3;`10`8`2);  / soft 18 vs 7, soft 19 vs 5, soft 20, hard 18
    };
  should["leaves out soft 18 vs 2-6 and soft 19 vs 6, which basic strategy doubles"]{
    .da.hist:(); .da.res:.tst.daPlays[(`A`7`3;`A`7`2;`A`8`2);21 20 21i;(`2`K;`6`K;`6`K);111b;000b];
    .da.getPlayTrend[];
    (count .da.double) musteq 0;
    };
 };

.tst.desc[".da.getPlayTrend stands"]{
  should["flags standing on a two-card hard 15/16 against 7-A"]{
    .da.hist:(); .da.res:.tst.daPlays[(`10`6;`9`6;`10`5);16 15 15i;(`10`8;`7`K;`A`6);000b;000b];
    .da.getPlayTrend[];
    (count .da.stand) musteq 3;
    };
  should["leaves out standing on hard 15/16 against 2-6, which basic strategy does"]{
    .da.hist:(); .da.res:.tst.daPlays[(`10`6;`9`6);16 15i;(`6`K;`2`K);00b;00b];
    .da.getPlayTrend[];
    (count .da.stand) musteq 0;
    };
  should["flags standing on a soft 15/16 against any up-card"]{
    .da.hist:(); .da.res:.tst.daPlays[(`A`5;`A`4);16 15i;(`6`K;`2`K);00b;00b];
    .da.getPlayTrend[];
    (count .da.stand) musteq 2;
    };
  should["leaves out split aces, which stand by rule"]{
    .da.hist:(); .da.res:.tst.daPlays[enlist`A`5;enlist 16i;enlist`9`K;enlist 0b;enlist 1b];
    .da.getPlayTrend[];
    (count .da.stand) musteq 0;
    };
 };

.tst.desc[".da.getPlayTrend splits"]{
  should["flags splitting tens, and not other splits"]{
    .da.hist:(); .da.res:.tst.daPlays[(`K`5;`10`9;`8`3);15 19 11i;(`6`K;`6`K;`6`K);000b;111b];
    .da.getPlayTrend[];
    (exec cards from .da.split) mustmatch (`K`5;`10`9);
    };
 };

.tst.desc[".da.getPlayTrend theCount"]{
  should["reports the basic count the round was played at, not a constant"]{
    .da.hist:(); .da.res:.tst.daPlays[(`A`9`3;`10`6);13 16i;(`4`3;`10`8);10b;00b];
    .da.getPlayTrend[];
    (exec theCount from .da.double) musteq enlist 0.5;
    (exec theCount from .da.stand) musteq enlist 1f;
    };
  should["includes earlier shoes from .da.hist"]{
    .da.hist:.tst.daPlays[enlist`10`6;enlist 16i;enlist`10`8;enlist 0b;enlist 0b];
    .da.res:update round:2 from .tst.daPlays[enlist`9`6;enlist 15i;enlist`A`8;enlist 0b;enlist 0b];
    .da.getPlayTrend[];
    (exec round from .da.stand) musteq 1 2;
    };
 };

.tst.desc[".da.getPlayTrend surrenders"]{
  should["doesn't read a surrendered two-card 15/16 as standing on it"]{
    .da.hist:(); .da.res:update surrender:1b from .tst.daPlays[enlist`10`6;enlist 16i;enlist`10`8;enlist 0b;enlist 0b];
    .da.getPlayTrend[];
    (count .da.stand) musteq 0;
    };
 };
