.bs.hd:1b;
.bs.bd:.bs.double:0b;
.bs.rnd:0;
.bs.da:0Ni;

.bs.cardDict:`A`K`Q`J`10`9`8`7`6`5`4`3`2!`11`10`10`10`10`9`8`7`6`5`4`3`2;
.bs.deckTemplate:raze 4#enlist key .bs.cardDict;
.bs.deckCnt:6;
.bs.shuffleCnt:0;
.bs.hitSoft17:1b;
.bs.maxSplitHands:4;
.bs.betTimeout:0D00:00:15;
.bs.betDeadline:0Np;
.bs.insuring:0b;
.bs.insureDeadline:0Np;

.bs.cp:()!();
.bs.joined:(`int$())!`long$();                                                                     / kdb reuses handle numbers
.bs.res:.bs.tab:.bs.hist:flip`round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
.bs.stake:([name:();handle:()]bet:());

.bs.intro:{
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

hist:{.bs.hist,.bs.res};

.bs.start:{
  if[not .bs.hd;:.bs.sendMsg["Please wait until the hand is over";.z.w]];
  if[0=count .bs.cp;:.bs.lg"No users are connected"];
  .bs.lg $[.bs.seated[]~.bs.cp;"No new users have joined the table";"New users have joined the table"];
  .bs.seat[];
  unbet:exec handle from .bs.tab where null bet;
  .bs.sendMsg["Please place your bets via the stake[] function"]each unbet;
  .bs.trigger[`.mc.stake]each unbet;
 };

.bs.seated:{exec first name by handle from .bs.tab};

.bs.seat:{
  .bs.tab:0#.bs.tab;
  `.bs.tab upsert([]player:1+til count .bs.cp;name:value .bs.cp;handle:key .bs.cp);
  .bs.tab:.bs.tab lj .bs.stake;
 };

.bs.forfeit:{[h]
  t:update return:0f from(select from .bs.tab where handle=h)where not out;
  if[0=count t;:()];
  t:update"j"$player,dealer:enlist each dealer,"f"$return from delete out,wait,turn from t;
  upsert[`.bs.res;update profit:(return-bet)-0f^insurance from t];
 };

.bs.logLeaver:{[h]
  won:sum 0f,exec profit from hist[] where handle=h,round>.bs.joined h;
  .bs.lg string[.bs.cp h]," has left the table, net winnings this session ",$[won<0;"-$";"$"],.Q.f[2;abs won];
 };

.bs.unseat:{[h]
  .bs.cp:.bs.cp _ h;
  .bs.joined:.bs.joined _ h;
  delete from`.bs.tab where handle=h;
  delete from`.bs.stake where handle=h;
 };

.bs.leave:{[h]
  if[not .bs.hd;.bs.forfeit h];
  .bs.logLeaver h;
  hadTurn:$[.bs.hd;0b;h in exec handle from .bs.tab where turn];
  .bs.unseat h;
  if[.bs.insuring;:.bs.closeInsuranceIfDone[]];
  if[.bs.hd;:.bs.dealIfReady[]];
  if[not hadTurn;:()];
  update turn:1b from`.bs.tab where player=(exec first player from .bs.tab where out=0b,wait=0b);
  .bs.nextTurn[];
 };

.z.po:{
  .bs.regConn .z.w;
  if[.bs.isDA[];:()];
  .bs.start[];
  neg[.z.w](.bs.intro;`);
 };

.z.pc:{$[x=.bs.da;.bs.da:0Ni;.bs.leave x]};
.z.ts:{.bs.betTimer[];.bs.insureTimer[]};

.bs.loadLibs:{
  system"l src/server/lib/messaging.q";
  system"l src/server/lib/deck.q";
  system"l src/server/lib/deal.q";
  system"l src/server/lib/actions.q";
 };

.bs.init:{
  args:.Q.opt .z.x;
  system"c 100 200";
  system"S ",string $[`seed in key args;"I"$raze args`seed;"i"$.z.i+.z.t];
  system"p 5555";
  system"t 1000";
  .bs.loadLibs[];
  .bs.lg"Welcome to Qsino Blackjack!";
  .bs.buildDeck[];
  .bs.shuffle[];
 };

if[not[null .z.f]&"blackjackServer.q"~last"/"vs string .z.f;.bs.init[]];
