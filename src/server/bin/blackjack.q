if[not`utl in key`;system"l vendor/qutil/bootstrap.q";.utl.QPATH:`:vendor`:src];
.utl.require"common";

.bjk.hd:1b;
.bjk.bd:.bjk.double:0b;
.bjk.rnd:0;
.bjk.pit:0Ni;
.bjk.public:`stake`hit`stick`double`split`insure`hist;

.bjk.deckTemplate:raze 4#enlist key .crd.cardDict;
.bjk.shuffleCnt:0;
.bjk.hitSoft17:1b;
.bjk.rules:`maxSplitHands`deckCnt!4 6;
.bjk.betTimeout:0D00:00:15;
.bjk.betDeadline:0Np;
.bjk.insuring:0b;
.bjk.insureDeadline:0Np;

.bjk.cp:()!();
.bjk.joined:(`int$())!`long$();                                                                     / kdb reuses handle numbers
.bjk.res:.bjk.tab:.bjk.hist:flip`round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
.bjk.stake:([name:();handle:()]bet:`long$());

.bjk.intro:{
  show"Welcome to Qsino Blackjack!";
  show"Functions;";
  show" stake     - How much you want to bet. Default is no bet";
  show" hit       - Gives you another card";
  show" stick     - Stay with your current hand";
  show" split     - Split your hand";
  show" double    - Double your hand.";
  show" insure    - Take insurance when the dealer shows an ace";
  show" hist      - Hand results so far";
 };

hist:{.bjk.hist,.bjk.res};

.bjk.start:{
  if[not .bjk.hd;:.bjk.sendMsg["Please wait until the hand is over";.z.w]];
  if[0=count .bjk.cp;:.log.info"No users are connected"];
  .log.info $[.bjk.seated[]~.bjk.cp;"No new users have joined the table";"New users have joined the table"];
  .bjk.seat[];
  unbet:exec handle from .bjk.tab where null bet;
  .bjk.sendMsg["Please place your bets via the stake[] function"]each unbet;
  .bjk.trigger[`.plr.stake]each unbet;
 };

.bjk.seated:{exec first name by handle from .bjk.tab};

.bjk.seat:{
  .bjk.tab:0#.bjk.tab;
  `.bjk.tab upsert([]player:1+til count .bjk.cp;name:value .bjk.cp;handle:key .bjk.cp);
  .bjk.tab:.bjk.tab lj .bjk.stake;
 };

.bjk.forfeit:{[h]
  t:update return:0f from(select from .bjk.tab where handle=h)where not out;
  if[0=count t;:()];
  t:update"j"$player,dealer:enlist each dealer,"f"$return from delete out,wait,turn from t;
  upsert[`.bjk.res;update profit:(return-bet)-0f^insurance from t];
 };

.bjk.logLeaver:{[h]
  won:sum 0f,exec profit from hist[] where handle=h,round>.bjk.joined h;
  .log.info string[.bjk.cp h]," has left the table, net winnings this session ",$[won<0;"-$";"$"],.Q.f[2;abs won];
 };

.bjk.unseat:{[h]
  .bjk.cp:.bjk.cp _ h;
  .bjk.joined:.bjk.joined _ h;
  delete from`.bjk.tab where handle=h;
  delete from`.bjk.stake where handle=h;
 };

.bjk.leave:{[h]
  if[not .bjk.hd;.bjk.forfeit h];
  .bjk.logLeaver h;
  hadTurn:$[.bjk.hd;0b;h in exec handle from .bjk.tab where turn];
  .bjk.unseat h;
  if[.bjk.insuring;:.bjk.closeInsuranceIfDone[]];
  if[.bjk.hd;:.bjk.dealIfReady[]];
  if[not hadTurn;:()];
  .bjk.nextTurn[];
 };

.z.po:{
  .bjk.regConn .z.w;
  if[.bjk.isPit[];:()];
  .bjk.start[];
  neg[.z.w](.bjk.intro;`);
 };

/ .bjk.command"stake 10"
.bjk.command:{
  c:$[10h=type x;parse x;x];
  if[not(type[c]in 0 11h)&2=count c;'"Send a command, e.g. stake[10] or hit[]"];
  if[not$[-11h=type first c;first[c]in .bjk.public;0b];'"Only ",(", "sv string .bjk.public)," can be called"];
  if[not(a~(::))|(a~`)|type[a:last c]in -5 -6 -7 -8 -9h;'"A command takes a single number, or nothing"];
  :c;
 };

.bjk.run:{value$[.bjk.isPit[];x;.bjk.command x]};
.bjk.logFailure:{[e].log.warn string[.z.u],"'s request failed: ",e};

.bjk.pg:{@[.bjk.run;x;{.bjk.logFailure x;'x}]};
.bjk.ps:{@[.bjk.run;x;{.bjk.logFailure x;.bjk.sendMsg["That didn't work: ",x;.z.w]}]};

.z.pc:{
  if[x=.bjk.pit;:.bjk.pit:0Ni];
  if[not x in key .bjk.cp;:()];                                                                    / e.g. handle 0, when the console's stdin closes
  .bjk.leave x;
 };

.z.ts:{.bjk.betTimer[];.bjk.insureTimer[]};

.bjk.libs:`:src/server/lib/messaging.q`:src/server/lib/deck.q`:src/server/lib/deal.q`:src/server/lib/actions.q;
.bjk.loadLibs:{.utl.require each .bjk.libs};

.bjk.init:{
  .utl.addOptDef["seed";"I";"i"$.z.i+.z.t;`.bjk.seed];
  .utl.parseArgs[];
  system"S ",string .bjk.seed;
  if[not system"p";system"p 5555"];
  system"t 1000";
  .bjk.loadLibs[];
  .z.pg:.bjk.pg;
  .z.ps:.bjk.ps;
  .log.info"Welcome to Qsino Blackjack!";
  .bjk.buildDeck[];
  .bjk.shuffle[];
 };

.util.run[`blackjack.q;`.bjk.init];
