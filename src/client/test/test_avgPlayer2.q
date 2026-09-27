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
    .stg.getBet[] mustmatch 15;
  };
  should["falls back to 10 after a losing or push hand"]{
    .stg.res:([]round:1 2;handle:5 5i;name:`bob_5`bob_5;profit:15 -10f);
    .stg.mh:5i;
    .stg.getBet[] musteq 10;
  };
  should["bets 10 before any hand has been played, when the pushed results are still untyped"]{
    .stg.res:flip`round`hand`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
    .stg.mh:5i;
    .stg.getBet[] musteq 10;
  };
 };
