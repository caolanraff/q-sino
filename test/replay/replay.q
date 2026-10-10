if[not`utl in key`;system"l vendor/qutil/bootstrap.q";.utl.QPATH:`:vendor`:src];
.utl.require"common";
.utl.require`:src/players/bin/player.q;
.utl.require`:src/house/bin/pitboss.q;

.rep.seats:`avgPlayer1`avgPlayer2`avgPlayer3`basicCardCounter;                                     / one seat per strategy, in seat order
.rep.seats,:`smallSpreadBasicCardCounter`omegaCardCounter`perfectCardCounter;                      / and the other counters
.rep.cols:`round`name`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance;         / results columns compared
.rep.dir:"test/replay/";                                                                           / golden copies under golden/, this run under out/
.rep.stg:.rep.plr:(enlist 0Ni)!enlist(::);                                                         / each seat's .stg and .plr namespaces by handle; a null keeps them lists
.rep.who:("i"$())!`$();                                                                            / each seat's strategy, by handle
.rep.queue:();                                                                                     / pushes to seats, waiting to be played
.rep.ready:0b;                                                                                     / every seat has bought in
.rep.left:([]seat:`$();why:());                                                                    / seats that left, and why
.rep.flags:([]round:"j"$();name:`$());                                                             / players the pitboss reported, and when

.rep.server:{                                                                                      / start the server on .rep.port with .rep.seed
  q:getenv[`QHOME],"/",string[.z.o],"/q";                                                          / the q binary
  o:" -p ",string[.rep.port]," --seed ",string .rep.seed;                                          / its options
  system q," src/house/bin/blackjack.q",o," </dev/null >",.rep.dir,"out/server.log 2>&1 &";
 };

.rep.try:{[a;s]                                                                                    / [address;state] one attempt to connect; state is (tries;handle)
  h:@[hopen;a;0Ni];                                                                                / connect, or null
  if[null h;system"sleep 0.1"];
  :(1+s 0;h);                                                                                      / the state after this attempt
 };

.rep.open:{[u]                                                                                     / [user] connect to the server as a user, waiting up to 5s for it to start
  a:`$":localhost:",string[.rep.port],":",string u;                                                / the server, as this user
  h:last{(null x 1)&50>x 0}.rep.try[a]/(0;0Ni);                                                    / try until connected, or 50 times
  if[null h;-2"Couldn't connect to the server on port ",string .rep.port;exit 1];                  / give up
  :h;                                                                                              / the handle
 };

.rep.push:{[f;s]                                                                                   / [handler;state] queue a push to a seat; play the queue once every seat is in
  .rep.queue,:enlist(.z.w;f;s);                                                                    / queue it, with the seat it came to
  if[.rep.ready;.rep.drain[]];                                                                     / play it
 };

.rep.drain:{                                                                                       / play every queued push, in the order they came
  q:.rep.queue;                                                                                    / the queue
  .rep.queue:();                                                                                   / emptied
  {.rep.run . x}each q;                                                                            / play each
 };

.rep.run:{[h;f;s]                                                                                  / [handle;handler;state] run a seat's own handler, with its own state
  if[not h in key .rep.plr;:()];                                                                   / the seat has left
  `.stg set .rep.stg h;                                                                            / its strategy state
  `.plr set .rep.plr h;                                                                            / its player state and handlers
  .plr[f]s;                                                                                        / run the handler
  if[h in key .rep.plr;.rep.stg[h]:get`.stg;.rep.plr[h]:get`.plr];                                 / keep its state, unless it left
  `.plr set .rep.routers;                                                                          / route the next push
 };

.rep.leave:{[msg]                                                                                  / [message] a seat leaves: note why and hang up; replaces .plr.leave, which exits
  h:.plr.h;                                                                                        / the seat
  .rep.left,:([]seat:enlist .rep.who h;why:enlist msg);                                            / note it
  .rep.plr:.rep.plr _ h;                                                                           / forget it
  .rep.stg:.rep.stg _ h;                                                                           / and its strategy state
  hclose h;                                                                                        / hang up
 };

.rep.seat:{[s]                                                                                     / [strategy] seat a strategy: connect, load it, keep its state, buy in
  h:.rep.open s;                                                                                   / connect as the strategy's name
  .utl.load each(`:src/players/lib/strategy.q;hsym`$"src/players/lib/",string[s],".q");
  .plr.h:h;                                                                                        / its handle
  .plr.buyin:1000;                                                                                 / its buy-in
  .plr.toth:.rep.hands;                                                                            / hands to play before leaving
  .plr.leave:.rep.leave;                                                                           / leave without exiting
  .rep.who[h]:s;                                                                                   / its strategy
  .rep.stg[h]:get`.stg;                                                                            / its strategy state
  .rep.plr[h]:get`.plr;                                                                            / its player state and handlers
  `.plr set .rep.routers;                                                                          / route pushes
  h(`buyin;1000);                                                                                  / buy in; sync, so every seat is in before anyone bets
 };

.rep.report:.pit.report;                                                                           / the pitboss's report
.pit.report:{.rep.flags,:([]round:enlist .pit.rnd;name:enlist x`name);.rep.report x};              / note each report too

.rep.table:{[r]                                                                                    / [results] the compared columns, with players by strategy and hands as text
  t:(.rep.cols inter cols r)#r;                                                                    / the columns every version has
  :update name:.rep.strategy name," "sv'string cards," "sv'string dealer from t;                   / handles vary by run; cards as text, e.g. "K 5"
 };

.rep.strategy:{`$first each"_"vs'string x};                                                        / strategy from a player name, e.g. avgPlayer1_7

.rep.summary:{[r]                                                                                  / [results] per strategy: hands, results and plays, and when the pitboss flagged them
  r:update seat:.rep.strategy name from r;                                                         / each hand's strategy
  s:select rounds:count distinct round,hands:count i,staked:sum bet,net:sum profit,                / results and plays
    won:sum profit>0,lost:sum profit<0,doubles:sum double,splits:sum split,insured:sum insurance>0
    by seat from r;
  f:select flagged:count i,firstFlag:min round by seat:.rep.strategy name from .rep.flags;         / the pitboss's flags
  :0!(s lj f)lj`seat xkey .rep.left;                                                               / with the pitboss's flags and why each left
 };

.rep.diff:{[f;new]                                                                                 / [file;lines] how a file differs from its golden copy, if at all
  old:@[read0;hsym`$.rep.dir,"golden/",f;()];                                                      / the golden copy
  if[old~new;:()];                                                                                 / no difference
  n:max count each(old;new);                                                                       / the longer of the two
  i:first where not(n#old,n#enlist"")~'n#new,n#enlist"";                                           / first line that differs, padding the shorter
  c:string count each(old;new);                                                                    / line counts
  m:f,": ",c[0]," lines before, ",c[1]," now; first difference on line ",string 1+i;               / what changed
  :(m;"  was: ",old i;"  now: ",new i);                                                            / with both versions of that line
 };

.rep.finish:{                                                                                      / write this run, compare it with the golden copy, stop the server
  system"t 0";
  r:.rep.pit"hist[]";                                                                              / every hand played
  out:(`hands.csv;`summary.csv)!(csv 0:.rep.table r;csv 0:.rep.summary r);                         / this run
  {hsym[`$.rep.dir,"out/",string x]0:y}'[key out;value out];                                       / save it
  d:raze .rep.diff'[string key out;value out];                                                     / differences from the golden copy
  neg[.rep.pit]"exit 0";                                                                           / stop the server
  neg[.rep.pit][];
  -1 .Q.s .rep.summary r;
  if[.rep.update;{hsym[`$.rep.dir,"golden/",string x]0:y}'[key out;value out]];                    / replace the golden copy
  if[.rep.update;-1"Golden copy updated";exit 0];
  if[0=count d;-1"Same as the golden copy";exit 0];
  -1"Differs from the golden copy:";
  -1 d;
  exit 1;
 };

.rep.timer:{                                                                                       / finish once every seat has left, or give up after 2 minutes
  if[.rep.ready&all null key .rep.plr;:.rep.finish[]];                                             / every seat has left
  if[.z.p>.rep.deadline;-2"Still playing after 2 minutes; see ",.rep.dir,"out/server.log";exit 1];
 };

.rep.init:{                                                                                        / replay a fixed-seed game and compare it with the golden copy
  .utl.addOptDef["port";"I";7311i;`.rep.port];                                                     / --port: the server's port
  .utl.addOptDef["seed";"I";42i;`.rep.seed];                                                       / --seed: the server's seed
  .utl.addOptDef["hands";"J";1000;`.rep.hands];                                                    / --hands: hands each seat plays
  .utl.addOptDef["update";"B";0b;`.rep.update];                                                    / --update: make this run the golden copy
  .utl.parseArgs[];                                                                                / parse the command line
  system"mkdir -p ",.rep.dir,"out ",.rep.dir,"golden";
  .rep.server[];                                                                                   / start the server
  .log.info:.log.warn:{};                                                                          / quieten the pitboss: the summary has its flags
  .z.ps:{if[-11h=type first x;value x]};                                                           / run pushed handlers; drop the messages the server prints
  .plr.stake:{.rep.push[`stake;x]};                                                                / route each push to its seat
  .plr.play:{.rep.push[`play;x]};
  .plr.insure:{.rep.push[`insure;x]};
  .plr.shuffle:{.rep.push[`shuffle;x]};
  .rep.routers:get`.plr;                                                                           / the routing handlers
  .rep.pit:.pit.h:.rep.open`pitboss;                                                               / the pitboss, connected before anyone plays
  .pit.startCards:.pit.shoeSize .pit.h;                                                            / full shoe size
  .rep.seat each .rep.seats;                                                                       / seat every strategy
  .rep.ready:1b;                                                                                   / everyone is in
  .rep.drain[];                                                                                    / play the first bets
  .rep.deadline:.z.p+0D00:02;                                                                      / give up after 2 minutes
  .z.ts:.rep.timer;                                                                                / check for the end
  system"t 100";
 };

.util.run[`replay.q;`.rep.init];                                                                   / init when run as the entry script
