/ playerCore.q has no network/side effects at load time, so it's safe to
/ `system "l"` directly and exercise the real Help[] function.
system "l src/client/playerCore.q";

.tst.desc["playerCore.Help"]{

  should["confirms review finding: multi-ace hands are undercounted - A,A,9 vs dealer 6 is a made soft 21 but is scored/played as if it were 11"]{
    / Help[x]: x is (player cards...; dealer up-card). A,A,9 = ace+ace+9.
    / Correct blackjack value: one ace counts as 11, the other as 1 -> 21,
    / which should Stand. playerCore.q:84 instead drops *every* ace from
    / 11 to 1 in a single pass whenever the naive (all-aces-high) total
    / busts, so this hand gets scored as 1+1+9=11 and told to Hit.
    Help[`A`A`9`6] musteq `H;
    };

  should["confirms review finding: multi-ace hands are undercounted - A,9,+hit A vs dealer 2 is a soft 21 but is scored/played as if it were 11"]{
    Help[`A`9`A`2] musteq `H;
    };

  should["sanity: still correctly recommends Stand on a plain made 20"]{
    Help[`10`Q`6] musteq `S;
    };

  should["sanity: still correctly recommends Hit on a hard 12 vs a strong dealer up-card"]{
    Help[`10`2`10] musteq `H;
    };

 };
