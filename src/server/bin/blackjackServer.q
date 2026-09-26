/// Init ///
\c 100 200

.bs.hd:1b;
.bs.bd:.bs.double:0b;
.bs.rnd:0;
.bs.da:0Ni;	    //detection algo handle

.bs.cardDict:`A`K`Q`J`10`9`8`7`6`5`4`3`2!`11`10`10`10`10`9`8`7`6`5`4`3`2;
.bs.deckTemplate:raze 4#enlist key .bs.cardDict;
.bs.deckCnt:6;
.bs.shuffleCnt:0;
.bs.hitSoft17:1b;   //1b: dealer hits soft 17 (H17, as on the Las Vegas Strip); 0b: stands on all 17s (S17)
.bs.maxSplitHands:4;   //split up to 3 times, i.e. at most 4 hands per player
.bs.betTimeout:0D00:00:30;   //once the first bet is down, anyone still unbet after this long sits the hand out
.bs.betDeadline:0Np;

.bs.cp:()!();
.bs.joined:(`int$())!`long$();   //handle -> .bs.rnd when that connection joined, so a reused handle doesn't inherit an earlier session's results
.bs.res:.bs.tab:.bs.hist:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(();();();();();();();();`long$();();();();());
.bs.stake:([name:();handle:()]bet:());

/// Start up functions ///
system "l src/server/lib/messaging.q";

.bs.intro:{
  show "Welcome to Qsino Blackjack!";
  show "Functions;";
  show " stake     - How much you want to bet. Default is no bet";
  show " hit       - Gives you another card";
  show " stick     - Stay with your current hand";
  show " split     - Split your hand";
  show " double    - Double your hand.";
  show " hist      - Hand results so far";
  };

hist:{.bs.hist,.bs.res};

.bs.start:{
  if[not .bs.hd;.bs.sendMsg"Please wait until the hand is over";:()];
  if[0=count .bs.cp;.bs.lg"No users are connected";:()];
  cpn:(!) . value flip distinct select handle,name from .bs.tab;
  $[cpn~.bs.cp;
    .bs.lg"No new users have joined the table";
    .bs.lg"New users have joined the table"];
  .bs.tab:0#.bs.tab;
  `.bs.tab upsert ([]player:1+til count .bs.cp;name:value .bs.cp;handle:key .bs.cp);
  / keep bets already placed this round (a player joining mid-betting mustn't wipe them); only prompt those still to bet
  .bs.tab:.bs.tab lj .bs.stake;
  unbet:exec handle from .bs.tab where null bet;
  .bs.sendMsg["Please place your bets via the stake[] function"]each unbet;
  .bs.excFunc[`.mc.stake;`]each unbet;
  };

/ a player leaving mid-hand forfeits it: record their hands in .bs.res (settled ones keep their result, the rest lose their bet)
/ so hist[], their session total and the detection algo all see them
.bs.forfeit:{[h]
  t:update return:0f from (select from .bs.tab where handle=h) where not out;
  if[0=count t;:()];
  t:update "j"$player,dealer:enlist each dealer,"f"$return from delete out,wait,turn from t;
  upsert[`.bs.res;update profit:return-bet from t];
  };

.bs.leave:{[h]
  if[not .bs.hd;.bs.forfeit h];
  won:sum 0f,exec profit from hist[] where handle=h,round>.bs.joined h;
  .[.bs.sendMsg;("Your net winnings this session are ",$[won<0;"-$";"$"],.Q.f[2;abs won];h);{}];
  .[.bs.sendMsg;("Thanks for playing Qasino Blackjack";h);{}];
  p:exec first player from .bs.tab where handle=h;
  .bs.lg string[p]," has left the table";
  hadTurn:$[.bs.hd;0b;h in exec handle from .bs.tab where turn];
  .bs.cp:.bs.cp _ h;
  .bs.joined:.bs.joined _ h;
  delete from `.bs.tab where handle=h;
  delete from `.bs.stake where handle=h;
  / between hands: the leaver may have been the last player the deal was waiting on
  if[.bs.hd;.bs.dealIfReady[];:()];
  / mid-hand: pass on the turn if it was theirs, else nobody would ever act again
  if[not hadTurn;:()];
  update turn:1b from `.bs.tab where player=(exec first player from .bs.tab where out=0b,wait=0b);
  .bs.nextTurn[];
  };

.z.po:{.bs.regConn[.z.w];if[not .bs.isDA[];.bs.start[];neg[.z.w](.bs.intro;`)]};
.z.pc:{$[x=.bs.da;.bs.da:0Ni;.bs.leave x]};
.z.ts:{.bs.betTimer[]};

/// Deck functions ///
system "l src/server/lib/deck.q";

/// Deal function ///
system "l src/server/lib/deal.q";

/// Turn actions ///
system "l src/server/lib/actions.q";

/// Start ///
init:{
  args:.Q.opt .z.x;
  seed:$[`seed in key args;"I"$raze args[`seed];(first "I"$(system "date +%s"))+"i"$.z.t];
  system "S ",string seed;

  system "p 5555";
  system "t 1000";  / drives .bs.betTimer

  show "Welcome to Qsino Blackjack!";
  .bs.buildDeck[];
  .bs.shuffle[];
  };

if[(not null .z.f) and "blackjackServer.q"~last "/" vs string .z.f;init[]];
