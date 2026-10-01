.log.str:{$[10h=abs type x;x;0h=type x;raze x;.Q.s x]};                                            / message as a string; lists of strings are joined
.log.line:{[lvl;x]ssr[string .z.p;"D";" "]," ",lvl," ",.log.str x};                                / [level;message] timestamped, levelled log line
.log.msg:{[lvl;x] -1 .log.line[lvl;x]};                                                            / [level;message] log line to stdout
.log.info:.log.msg["INFO";];                                                                       / info
.log.warn:.log.msg["WARN";];                                                                       / warning
.log.error:.log.msg["ERROR";];                                                                     / error
