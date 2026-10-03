.utl.load`:src/common/lib/cards.q;

.tst.round:{[r;c1;c2;d]([]round:r,r;name:`a_5`b_6;cards:(c1;c2);dealer:(d;d))};

.tst.desc[".crd.cardsSeen"]{
  should["counts the dealer's cards once per round, however many player rows repeat them"]{
    t:.tst.round[1;`K`5;`2`3`4;`10`8],.tst.round[2;`A`9;`6`6;`7`K];
    asc[.crd.cardsSeen t] mustmatch asc `K`5`2`3`4`10`8`A`9`6`6`7`K;
  };
  should["takes the longest dealer hand in a round, since a forfeit row only holds the up-card"]{
    t:([]round:3 3;cards:(`K`6;`9`10);dealer:(enlist`9;`9`8));
    asc[.crd.cardsSeen t] mustmatch asc `K`6`9`10`9`8;
  };
  should["ignores seats with no cards dealt yet"]{
    t:([]round:0N 0N;cards:(();());dealer:``);
    count[.crd.cardsSeen t] musteq 0;
  };
 };

.tst.desc[".crd.hiLo, .crd.omega and .crd.perfect"]{
  should["each count a full deck to zero, so the count starts and ends a shoe at zero"]{
    deck:raze 4#enlist key .crd.cardDict;
    (sum each(.crd.hiLo;.crd.omega;.crd.perfect)@\:deck) mustmatch 0 0 0;
  };
 };

.tst.desc[".crd.trueCount"]{
  should["divides the running count by the decks left in the shoe"]{
    .crd.trueCount[.crd.hiLo;`K`5`2`3`4`10`8;312] musteq 2%(312-7)%52;
  };
  should["scores the same cards differently under each count"]{
    seen:`5`5`6`K;
    .crd.trueCount[.crd.omega;seen;104] musteq 4%(104-4)%52;
    .crd.trueCount[.crd.perfect;seen;104] musteq 17%(104-4)%52;
  };
 };
