/ playerCore.q has no network/side effects at load time, so it's safe to
/ `system "l"` directly and exercise the real Help[] function. It's reloaded
/ inside each `should` body (not just once at file scope) because the
/ avgPlayer*.q test files in this shared process redefine the global `Help`
/ - without the reload, a should body here could run after one of those and
/ silently exercise the wrong (avgPlayer) `Help` instead of playerCore's.
.tst.desc["playerCore.Help"]{
  should["A,A,9 vs dealer 6 is a made soft 21 and should Stand"]{
    system "l src/client/lib/playerCore.q";
    Help[`A`A`9`6] musteq `S;
    };
  should["A,9,+hit A vs dealer 2 is a soft 21 and should Stand"]{
    system "l src/client/lib/playerCore.q";
    Help[`A`9`A`2] musteq `S;
    };
  should["still correctly recommends Stand on a plain made 20"]{
    system "l src/client/lib/playerCore.q";
    Help[`10`Q`6] musteq `S;
    };
  should["still correctly recommends Hit on a hard 12 vs a strong dealer up-card"]{
    system "l src/client/lib/playerCore.q";
    Help[`10`2`10] musteq `H;
    };
 };
