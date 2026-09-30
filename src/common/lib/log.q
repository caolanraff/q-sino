.log.str:{$[10h=abs type x;x;0h=type x;raze x;.Q.s x]};
.log.msg:{[h;lvl;x]h ssr[string .z.p;"D";" "]," ",lvl,.log.str x};
.log.info:.log.msg[-1;"INFO ";];
.log.warn:.log.msg[-2;"WARN ";];
.log.error:.log.msg[-2;"ERROR ";];
