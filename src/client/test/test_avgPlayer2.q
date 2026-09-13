/ playerCore.q and avgPlayer2.q have no network/side effects at load time,
/ so they're safe to `system "l"` directly. avgPlayer2.q is reloaded inside
/ each `should` body (not just once at file scope) because other test files
/ in this shared process also redefine the global `Help`/`getBet` - without
/ the reload, whichever file's definition loaded last would silently win by
/ the time qspec actually runs this spec.
system "l src/client/lib/playerCore.q";

.tst.desc["avgPlayer2.Help ace handling"]{
  should["A,9,5 is a hittable soft 15, not a bust"]{
    system "l src/client/lib/avgPlayer2.q";
    Help[`A`9`5`2] musteq `H;
    };
 };
