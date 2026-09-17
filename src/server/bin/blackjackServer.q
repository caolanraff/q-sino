/// Init ///
\c 100 200

.bs.hd:1b;
.bs.bd:.bs.double:0b;
.bs.rnd:0;
DA:0Ni;	    //detection algo handle

cardDict:`A`K`Q`J`10`9`8`7`6`5`4`3`2!`11`10`10`10`10`9`8`7`6`5`4`3`2;
deck:raze 4#enlist key cardDict;
deckCnt:6;
shufflecnt:0;

cp:()!();
autoH:`long$();	    //handles registered (via regAuto) to receive auto-play triggers
.bs.res:.bs.tab:.bs.hist:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!(();();();();();();();();`long$();();();();());
.bs.stake:([name:();handle:()]bet:());

/// Start up functions ///
system "l src/server/lib/messaging.q";

intro:{
  show "Welcome to Qsino Blackjack!";
  show "Functions;";
  show " stake     - How much you want to bet. Default is no bet";
  show " hit       - Gives you another card";
  show " stick     - Stay with your current hand";
  show " split     - Split your hand";
  show " double    - Double your hand.";
  show " hist      - Hand results so far";
  show " shuffle   - Shuffle the cards";
  show " buildDeck - Builds the deck. Can input required amount, default is 6";
  };

hist:{.bs.hist,.bs.res};

.bs.start:{
  if[not .bs.hd;sendMsg"Please wait until the hand is over";:()];
  if[0=count cp;lg"No users are connected";:()];
  cpn:(!) . value flip distinct select handle,name from .bs.tab;
  $[cpn~cp;
    lg"No new users have joined the table";
    lg"New users have joined the table"];
  .bs.tab:0#.bs.tab;
  .bs.stake:0#.bs.stake;
  `.bs.tab upsert ([]player:1+til count cp;name:value cp;handle:key cp);
  sendMsg["Please place your bets via the stake[] function"]each key cp;
  excFunc[`stake;`]each autoH;
  };

leave:{[h]
  .[sendMsg;("Your total winnings are - $",(string (exec sum return from .bs.res where handle=h));h);{}];
  .[sendMsg;("Thanks for playing Qasino Blackjack";h);{}];
  p:exec first player from .bs.tab where handle=h;
  lg string[p]," has left the table";
  cp::cp _ h;
  autoH::autoH except h;
  delete from `.bs.tab where handle=h;
  };

.z.po:{regConn[.z.w];if[not isDA[];.bs.start[];neg[.z.w](intro;`)]};
.z.pc:{$[x=DA;DA::0Ni;leave x]};

/// Deck functions ///
system "l src/server/lib/deck.q";

/// Deal function ///
system "l src/server/lib/deal.q";

/// Turn actions ///
system "l src/server/lib/actions.q";

/// Start ///
init:{
  args:.Q.opt .z.x;
  seed::$[`seed in key args;"I"$raze args[`seed];(first "I"$(system "date +%s"))+"i"$.z.t];
  system "S ",string seed;

  toth::$[`hands in key args;"I"$raze args[`hands];1000i];

  system "p 5555";

  show "Welcome to Qsino Blackjack!";
  buildDeck[];
  shuffle[];
  };

if[(not null .z.f) and "blackjackServer.q"~last "/" vs string .z.f;init[]];
