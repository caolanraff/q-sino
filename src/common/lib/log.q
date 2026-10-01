.log.str:{$[10h=abs type x;x;0h=type x;raze x;.Q.s x]};                                            / message as a string; lists of strings are joined
.log.msg:{[h;lvl;x]h@\:ssr[string .z.p;"D";" "]," ",lvl,.log.str x};                               / [handles;level;message] timestamped, levelled line to each handle, e.g. .log.msg[-1;"INFO ";"dealing"]
.log.info:.log.msg[-1;"INFO ";];                                                                   / info to stdout, e.g. .log.info"dealing"
.log.warn:.log.msg[-2;"WARN ";];                                                                   / warning to stderr
.log.error:.log.msg[-1 -2;"ERROR ";];                                                              / error to stdout and stderr
