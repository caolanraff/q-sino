\c 100 200

.bs.hd:1b;                                                                                         / hand done: no hand in progress
.bs.bd:.bs.double:0b;                                                                              / bets done; current hit is part of a double
.bs.rnd:0;                                                                                         / current round number
.bs.da:0Ni;                                                                                        / detection algo handle

.bs.cardDict:`A`K`Q`J`10`9`8`7`6`5`4`3`2!`11`10`10`10`10`9`8`7`6`5`4`3`2;                          / card value by rank, ace high
.bs.deckTemplate:raze 4#enlist key .bs.cardDict;                                                   / one 52-card deck
.bs.deckCnt:6;                                                                                     / decks per shoe
.bs.shuffleCnt:0;                                                                                  / shuffles so far
.bs.hitSoft17:1b;                                                                                  / dealer hits soft 17 (H17); 0b stands on all 17s
.bs.maxSplitHands:4;                                                                               / most hands one player can split into
.bs.betTimeout:0D00:00:30;                                                                         / betting and insurance window once it opens
.bs.betDeadline:0Np;                                                                               / when betting closes this round
.bs.insuring:0b;                                                                                   / insurance window open
.bs.insureDeadline:0Np;                                                                            / when the insurance window closes

.bs.cp:()!();                                                                                      / connected players: handle -> name
.bs.joined:(`int$())!`long$();                                                                     / handle -> round that connection joined
.bs.res:.bs.tab:.bs.hist:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();());
.bs.stake:([name:();handle:()]bet:());                                                             / bets placed for the coming round

system "l src/server/lib/messaging.q";

.bs.intro:{                                                                                        / show a new player the welcome text and commands
  show "Welcome to Qsino Blackjack!";
  show "Functions;";
  show " stake     - How much you want to bet. Default is no bet";
  show " hit       - Gives you another card";
  show " stick     - Stay with your current hand";
  show " split     - Split your hand";
  show " double    - Double your hand.";
  show " insure    - Take insurance when the dealer shows an ace";
  show " hist      - Hand results so far";
  };

hist:{.bs.hist,.bs.res};                                                                           / every hand this run, current shoe included

.bs.start:{                                                                                        / seat every connection for a new round and prompt those yet to bet
  if[not .bs.hd;:.bs.sendMsg["Please wait until the hand is over";.z.w]];
  if[0=count .bs.cp;:.bs.lg"No users are connected"];
  .bs.lg $[.bs.seated[]~.bs.cp;"No new users have joined the table";"New users have joined the table"];
  .bs.seat[];
  unbet:exec handle from .bs.tab where null bet;
  .bs.sendMsg["Please place your bets via the stake[] function"]each unbet;
  .bs.trigger[`.mc.stake]each unbet;
  };

.bs.seated:{exec handle!name from distinct select handle,name from .bs.tab};                       / handle -> name of everyone seated

.bs.seat:{                                                                                         / one seat per connection, keeping bets already placed this round
  .bs.tab:0#.bs.tab;
  `.bs.tab upsert ([]player:1+til count .bs.cp;name:value .bs.cp;handle:key .bs.cp);
  .bs.tab:.bs.tab lj .bs.stake;
  };

.bs.forfeit:{[h]                                                                                   / [handle] record a mid-hand leaver's hands in the results
  t:update return:0f from (select from .bs.tab where handle=h) where not out;                      / unsettled hands lose their bet
  if[0=count t;:()];
  t:update "j"$player,dealer:enlist each dealer,"f"$return from delete out,wait,turn from t;
  upsert[`.bs.res;update profit:(return-bet)-0f^insurance from t];
  };

.bs.farewell:{[h]                                                                                  / [handle] send a leaving player their session winnings
  won:sum 0f,exec profit from hist[] where handle=h,round>.bs.joined h;
  .[.bs.sendMsg;("Your net winnings this session are ",$[won<0;"-$";"$"],.Q.f[2;abs won];h);{}];
  .[.bs.sendMsg;("Thanks for playing Qasino Blackjack";h);{}];
  };

.bs.unseat:{[h]                                                                                    / [handle] drop a player's connection, hands and pending bet
  .bs.cp:.bs.cp _ h;
  .bs.joined:.bs.joined _ h;
  delete from `.bs.tab where handle=h;
  delete from `.bs.stake where handle=h;
  };

.bs.leave:{[h]                                                                                     / [handle] handle a disconnect and keep the game moving
  if[not .bs.hd;.bs.forfeit h];
  .bs.farewell h;
  .bs.lg string[exec first player from .bs.tab where handle=h]," has left the table";
  hadTurn:$[.bs.hd;0b;h in exec handle from .bs.tab where turn];
  .bs.unseat h;
  if[.bs.insuring;:.bs.closeInsuranceIfDone[]];
  if[.bs.hd;:.bs.dealIfReady[]];                                                                   / they may have been the last bet the deal waited on
  if[not hadTurn;:()];
  update turn:1b from `.bs.tab where player=(exec first player from .bs.tab where out=0b,wait=0b);
  .bs.nextTurn[];
  };

.z.po:{.bs.regConn[.z.w];if[not .bs.isDA[];.bs.start[];neg[.z.w](.bs.intro;`)]};                   / register a connection; seat and greet players
.z.pc:{$[x=.bs.da;.bs.da:0Ni;.bs.leave x]};                                                        / forget the detection algo, or a player leaves
.z.ts:{.bs.betTimer[];.bs.insureTimer[]};                                                          / check the betting and insurance clocks

system "l src/server/lib/deck.q";
system "l src/server/lib/deal.q";
system "l src/server/lib/actions.q";

init:{                                                                                             / parse args, seed the RNG, listen, and build the first shoe
  args:.Q.opt .z.x;
  seed:$[`seed in key args;"I"$raze args[`seed];"i"$.z.i+.z.t];
  system "S ",string seed;
  system "p 5555";
  system "t 1000";                                                                                 / drives .z.ts
  show "Welcome to Qsino Blackjack!";
  .bs.buildDeck[];
  .bs.shuffle[];
  };

if[(not null .z.f) and "blackjackServer.q"~last "/" vs string .z.f;init[]];                        / run init only as the entry script

