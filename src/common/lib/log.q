.log.msg:{[h;lvl;x]h ssr[string .z.p;"D";" "]," ",lvl,raze x};
.log.info:.log.msg[-1;"INFO ";];
.log.warn:.log.msg[-2;"WARN ";];
.log.error:.log.msg[-2;"ERROR ";];
