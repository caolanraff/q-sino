.tst.desc["avgPlayer3 help: ace handling"]{
  should["A,9,5 is a hittable soft 15, not a bust"]{
    system"l src/client/lib/avgPlayer3.q";
    .stg.help[`A`9`5`2] musteq`H;
  };
 };
