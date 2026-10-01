.bjk.display:{[msg]($[10h=type msg;-1;show];msg)};                                                 / [message] message for a client to print: strings via -1, anything else via show
.bjk.sendMsg:{[msg;h]@[neg first h;.bjk.display msg;{.log.warn"Couldn't send a message: ",x}]};    / [message;handle] send a client a message, logging a failure
.bjk.pubMsg:{.log.info x;.bjk.sendMsg[x]each y};                                                   / log a message and send it to each handle
.bjk.excFunc:{[f;arg;h]@[neg first h;(f;arg);{.log.warn"Couldn't send a trigger: ",x}]};           / [function;argument;handle] call a function on a client, logging a failure
.bjk.clientState:{[h]`tab`res`me`rules`chips!(.bjk.tab;.bjk.res;h;.bjk.rules;.bjk.chips h)};       / [handle] game state pushed to a client, with their chips
.bjk.trigger:{[f;h].bjk.excFunc[f;.bjk.clientState h;h]};                                          / [function;handle] call a client's handler with its game state
.bjk.user:{`$string[.z.u],"_",string .z.w};                                                        / player name: username_handle
.bjk.isPit:{.z.u~`pitboss};                                                                        / is the caller the pitboss

.bjk.regConn:{[h]                                                                                  / [handle] register a new connection
  if[.bjk.isPit[];:.bjk.pit:h];                                                                    / record the pitboss handle; it does not sit
  .bjk.cp[h]:.bjk.user[];                                                                          / name them
  .bjk.users[h]:.z.u;                                                                              / their username
  .bjk.joined[h]:.bjk.rnd;                                                                         / round they joined
 };
