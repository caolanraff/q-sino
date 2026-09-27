.tst.desc["avgPlayer2 help: ace handling"]{
  should["A,9,5 is a hittable soft 15, not a bust"]{
    system"l src/client/lib/avgPlayer2.q";
    .stg.help[`A`9`5`2] musteq`H;
  };
 };

.tst.desc["avgPlayer2 .stg.getBet"]{
  before{system"l src/client/lib/avgPlayer2.q"};
  should["bets its own previous hand's profit, ignoring other players' rows"]{
    .stg.res:([]round:1 1 2 2;handle:5 6 5 6i;name:`bob_5`amy_6`bob_5`amy_6;profit:10 40 15 -10f);
    .stg.mh:5i;
    .stg.getBet[] musteq 15i;
  };
  should["falls back to 10 after a losing or push hand"]{
    .stg.res:([]round:1 2;handle:5 5i;name:`bob_5`bob_5;profit:15 -10f);
    .stg.mh:5i;
    .stg.getBet[] musteq 10;
  };
  should["bets 10 when there are no results yet this shoe"]{
    .stg.res:([]round:0#0;handle:0#0i;name:0#`;profit:0#0f);
    .stg.mh:5i;
    .stg.getBet[] musteq 10;
  };
 };
