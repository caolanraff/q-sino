system "l src/server/bin/detectionAlgo.q";

// shuffle/Count are root-level in detectionAlgo.q, matching production where it's its own
// process - but test/run.q loads every test file into one shared q process, so these collide
// with lib/deck.q's (server) and lib/playerCore.q's (client) same-named-but-different globals
// when the whole suite runs together. (cardDict is also root-level here, but is byte-identical
// across bin/blackjackServer.q, lib/playerCore.q and here - see architecture.md - so whichever
// copy wins doesn't matter.) Alias detectionAlgo.q's own shuffle/Count here, then restore the
// server's shuffle so test_deck.q isn't left with detectionAlgo's shuffle for the rest of the run.
daShuffle:shuffle;
daCount:Count;
system "l src/server/lib/deck.q";

.tst.desc["Count"]{
  should["divides the running point-count over the remaining decks"]{
    .da.res::([]cards:(enlist`2;enlist`3);dealer:(enlist`5;enlist`6));
    startCards::312;
    (daCount[basic]) musteq 4%((312-4)%52);
    };
 };

.tst.desc["getBetTrend"]{
  should["falls back to a 0 correlation for a single-row group (cor is null with one point)"]{
    .da.res::([]round:enlist 1;name:enlist`p1;handle:enlist 0i;bet:enlist 10f;cards:enlist`2`3;dealer:enlist`5);
    .da.rnd::1;
    startCards::312;
    .da.betTrend::flip `Round`Player`Handle`basic_cor`basic_cov`omega_cor`omega_cov`perfect_cor`perfect_cov!();
    getBetTrend[];
    (exec first basic_cor from .da.betTrend where Player=`p1) musteq 0f;
    (exec first Handle from .da.betTrend where Player=`p1) musteq 0i;
    };
  should["correlates bet against running count across a player's rows this round"]{
    .da.res::([]round:1 1;name:`p1`p1;handle:0 0i;bet:10 20f;cards:(enlist`2;enlist`10);dealer:(enlist`5;enlist`6));
    .da.rnd::1;
    startCards::312;
    .da.betTrend::flip `Round`Player`Handle`basic_cor`basic_cov`omega_cor`omega_cov`perfect_cor`perfect_cov!();
    getBetTrend[];
    (count .da.betTrend) musteq 1;
    (exec first Round from .da.betTrend) musteq 1;
    (null exec first basic_cor from .da.betTrend) musteq 0b;
    };
 };

.tst.desc["getPlayTrend"]{
  should["flags doubling on a made soft 18/19/20"]{
    .da.hist::();
    .da.res::([]round:enlist 1;name:enlist`p1;handle:enlist 0i;cards:enlist`A`7`3;dealer:enlist`5;cnt:enlist 21i;double:enlist 1b;split:enlist 0b);
    .bs.count::0f;
    getPlayTrend[];
    (count .da.double) musteq 1;
    };
  should["does not flag doubling on a made hard total outside 18-20"]{
    .da.hist::();
    .da.res::([]round:enlist 1;name:enlist`p1;handle:enlist 0i;cards:enlist`9`2`5;dealer:enlist`5;cnt:enlist 16i;double:enlist 1b;split:enlist 0b);
    .bs.count::0f;
    getPlayTrend[];
    (count .da.double) musteq 0;
    };
  should["flags splitting a pair of tens"]{
    .da.hist::();
    .da.res::([]round:enlist 1;name:enlist`p1;handle:enlist 0i;cards:enlist`10`10;dealer:enlist`5;cnt:enlist 20i;double:enlist 0b;split:enlist 1b);
    .bs.count::0f;
    getPlayTrend[];
    (count .da.split) musteq 1;
    };
  should["does not flag splitting a low pair"]{
    .da.hist::();
    .da.res::([]round:enlist 1;name:enlist`p1;handle:enlist 0i;cards:enlist`4`4;dealer:enlist`5;cnt:enlist 8i;double:enlist 0b;split:enlist 1b);
    .bs.count::0f;
    getPlayTrend[];
    (count .da.split) musteq 0;
    };
  should["flags standing on a made 15 or 16"]{
    .da.hist::();
    .da.res::([]round:enlist 1;name:enlist`p1;handle:enlist 0i;cards:enlist`9`6;dealer:enlist`5;cnt:enlist 15i;double:enlist 0b;split:enlist 0b);
    getPlayTrend[];
    (count .da.stand) musteq 1;
    };
  should["does not flag standing on a hand outside 15/16, or with more than two cards"]{
    .da.hist::();
    .da.res::([]round:enlist 1;name:enlist`p1;handle:enlist 0i;cards:enlist`9`8;dealer:enlist`5;cnt:enlist 17i;double:enlist 0b;split:enlist 0b);
    getPlayTrend[];
    (count .da.stand) musteq 0;
    };
 };

.tst.desc["detectionAlgo's shuffle"]{
  should["archives the current round into hist and resets .da.res/.bs.count"]{
    .bs.count::5f;
    .da.hist::();
    .da.res::([]round:enlist 1);
    daShuffle[];
    .bs.count musteq 0f;
    (count .da.hist) musteq 1;
    (count .da.res) musteq 0;
    };
 };

.tst.desc["getDetect"]{
  should["calls both getBetTrend and getPlayTrend"]{
    betCalls::0; playCalls::0;
    `getBetTrend mock {betCalls+::1};
    `getPlayTrend mock {playCalls+::1};
    getDetect[];
    betCalls musteq 1;
    playCalls musteq 1;
    };
 };

.tst.desc["gameover"]{
  should["accumulates the round's results, dedupes, and triggers detection"]{
    .bs.rnd::7;
    .da.res::0#([]round:`int$();name:`symbol$());
    detectCalls::0;
    `getDetect mock {detectCalls+::1};
    x:([]round:1 1;name:`p1`p1);  / duplicate row, gameover should distinct it away
    gameover[x];
    .da.rnd musteq 7;
    (count .da.res) musteq 1;
    detectCalls musteq 1;
    };
 };
