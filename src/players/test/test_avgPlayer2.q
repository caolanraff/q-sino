.tst.desc["avgPlayer2 help: ace handling"]{
  should["A,9,5 is a hittable soft 15, not a bust"]{
    .utl.load each`:src/players/lib/strategy.q`:src/players/lib/avgPlayer2.q;
    .stg.help[`A`9`5`2] musteq`H;
  };
 };

.tst.desc["avgPlayer2 .stg.getBet"]{
  before{
    .utl.load each`:src/players/lib/strategy.q`:src/players/lib/avgPlayer2.q;
    .stg.uid:"G"$"00000000-0000-0000-0000-000000000005";
  };
  should["bets its own previous hand's profit, ignoring other players' rows"]{
    u:"G"$"00000000-0000-0000-0000-00000000000",/:"56";
    .stg.res:([]round:1 1 2 2;handle:5 6 5 6i;uid:u 0 1 0 1;name:`bob_5`amy_6`bob_5`amy_6;profit:10 40 15 -10f);
    .stg.getBet[] mustmatch 15;
  };
  should["ignores the winnings of an earlier player who had the same handle"]{
    u:"G"$"00000000-0000-0000-0000-0000000000",/:("15";"05");
    .stg.res:([]round:1 2;handle:5i;uid:u;name:`bob_5;profit:40 -10f);
    .stg.getBet[] musteq 10;
  };
  should["falls back to 10 after a losing or push hand"]{
    .stg.res:([]round:1 2;handle:5i;uid:.stg.uid;name:`bob_5;profit:15 -10f);
    .stg.getBet[] musteq 10;
  };
  should["bets 10 before any hand has been played, when the pushed results are still untyped"]{
    .stg.res:([]round:"j"$();player:"j"$();name:`$();handle:"i"$();uid:"g"$();cards:();cnt:"i"$();dealer:();dealerCnt:"i"$();bet:"j"$();return:"f"$();profit:"f"$();split:"b"$();double:"b"$();insurance:"f"$();forced:"b"$());
    .stg.getBet[] musteq 10;
  };
 };
