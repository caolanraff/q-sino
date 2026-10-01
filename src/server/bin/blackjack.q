if[not`utl in key`;system"l vendor/qutil/bootstrap.q";.utl.QPATH:`:vendor`:src];
.utl.require"common";

.bjk.hd:1b;                                                                                        / no hand in progress
.bjk.bd:.bjk.double:0b;                                                                            / no bets placed yet; not mid-double
.bjk.rnd:0;                                                                                        / round number
.bjk.pit:0Ni;                                                                                      / pitboss's handle, null until it connects
.bjk.ejectCounters:0b;                                                                             / eject players the pitboss flags (--pitboss)
.bjk.public:`stake`hit`stick`double`split`insure`buyin`hist;                                       / the only commands a player can call

.bjk.deckTemplate:raze 4#enlist key .crd.cardDict;                                                 / one 52-card deck
.bjk.shuffleCnt:0;                                                                                 / shuffles so far
.bjk.hitSoft17:1b;                                                                                 / dealer hits soft 17
.bjk.rules:`maxSplitHands`deckCnt`minBet`maxBet`minBuyIn!4 6 10 500 100;                           / table rules, pushed to clients
.bjk.chips:(`int$())!`float$();                                                                    / each player's chips, once they've bought in
.bjk.chipsDue:(`int$())!`timestamp$();                                                             / players who need chips, and when they must have bought them by
.bjk.timeout:0D00:00:15;                                                                           / time allowed to bet, insure or act
.bjk.betDeadline:0Np;                                                                              / betting clock, null when not running
.bjk.insuring:0b;                                                                                  / insurance window open
.bjk.insureDeadline:0Np;                                                                           / insurance clock, null when not running
.bjk.turnDeadline:0Np;                                                                             / turn clock, null when not running

.bjk.cp:()!();                                                                                     / handle to player name
.bjk.users:(`int$())!`symbol$();                                                                   / handle to connecting username
.bjk.banned:`symbol$();                                                                            / usernames banned this session
.bjk.joined:(`int$())!`long$();                                                                    / round each handle joined; kdb reuses handle numbers
.bjk.res:.bjk.tab:.bjk.hist:flip`round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double`insurance!(();();();();();();();();`long$();();();();();()); / hands in play, this shoe's results, earlier shoes' results
.bjk.stake:([name:();handle:()]bet:`long$());                                                      / each player's bet for the next hand

.bjk.intro:{                                                                                       / help text sent to each new player
  show"Welcome to Qsino Blackjack!";
  show"Functions;";
  show" stake     - How much you want to bet. Default is no bet";
  show" hit       - Gives you another card";
  show" stick     - Stay with your current hand";
  show" split     - Split your hand";
  show" double    - Double your hand.";
  show" insure    - Take insurance when the dealer shows an ace";
  show" buyin     - Buy chips, at least $100 (do this before you bet)";
  show" hist      - Hand results so far";
 };

hist:{.bjk.hist,.bjk.res};                                                                         / every hand result so far

.bjk.committed:{[h]exec sum(0^bet)+0^insurance from .bjk.tab where handle=h};                      / [handle] what a player has on the table this round
.bjk.available:{[h](0^.bjk.chips h)-.bjk.committed h};                                             / [handle] chips a player can still put on the table
.bjk.outOfChips:{[h]not[null c]&.bjk.rules[`minBet]>c:.bjk.chips h};                               / [handle] has chips, but not enough for the minimum bet

.bjk.needChips:{[h]null[.bjk.chips h]|.bjk.outOfChips h};                                          / [handle] no chips, or not enough to bet

.bjk.chipsWindow:{[h]                                                                              / [handle] give a player without chips the timeout to buy some
  .bjk.chipsDue[h]:.z.p+.bjk.timeout;                                                              / their deadline
  m:$[null .bjk.chips h;"Please buy some chips";"You're out of chips"];                            / no chips yet, or run out
  .bjk.sendMsg[m,": buyin[amount] within ",string["j"$.bjk.timeout%0D00:00:01]," seconds, or you'll be asked to leave";h]; / tell them
 };

.bjk.betPrompt:{[h]                                                                                / [handle] ask a player to bet, with their chips
  if[.bjk.needChips h;:.bjk.chipsWindow h];                                                        / they need chips first
  .bjk.sendMsg["Please place your bets via the stake[] function, ",.bjk.limits[],"; your chips: $",.Q.f[2;.bjk.chips h];h]; / ask them to bet
 };

.bjk.start:{                                                                                       / seat players and ask for bets
  if[not .bjk.hd;:.bjk.sendMsg["Please wait until the hand is over";.z.w]];                        / a hand is in progress
  if[0=count .bjk.cp;:.log.info"No users are connected"];                                          / nobody to deal to
  .log.info $[.bjk.seated[]~.bjk.cp;"No new users have joined the table";"New users have joined the table"];
  .bjk.seat[];                                                                                     / seat everyone connected
  unbet:exec handle from .bjk.tab where null bet;                                                  / players without a bet
  .bjk.betPrompt each unbet;                                                                       / ask them to bet
  .bjk.trigger[`.plr.stake]each unbet;                                                             / prompt their stake handler
 };

.bjk.seated:{exec first name by handle from .bjk.tab};                                             / handle to name of everyone seated

.bjk.seat:{                                                                                        / reseat everyone connected, keeping their bets
  .bjk.tab:0#.bjk.tab;                                                                             / clear the table
  `.bjk.tab upsert([]player:1+til count .bjk.cp;name:value .bjk.cp;handle:key .bjk.cp);            / one row per connection
  .bjk.tab:.bjk.tab lj .bjk.stake;                                                                 / attach their bets
 };

.bjk.forfeit:{[h]                                                                                  / [handle] record a leaver's unfinished hands as lost
  t:update return:0f from(select from .bjk.tab where handle=h)where not out;                       / their hands still in play, returning nothing
  if[0=count t;:()];                                                                               / nothing in play
  t:update"j"$player,dealer:enlist each dealer,"f"$return from delete out,wait,turn from t;        / match the results schema
  upsert[`.bjk.res;update profit:(return-bet)-0f^insurance from t];                                / record them, losing bet and insurance
 };

.bjk.logLeaver:{[h]                                                                                / [handle] log a leaver's net winnings
  won:sum 0f,exec profit from hist[] where handle=h,round>.bjk.joined h;                           / net profit since they joined
  .log.info string[.bjk.cp h]," has left the table, net winnings this session ",$[won<0;"-$";"$"],.Q.f[2;abs won],", leaving with $",.Q.f[2;0^$[.bjk.hd;.bjk.chips h;.bjk.available h]]," in chips";
 };

.bjk.unseat:{[h]                                                                                   / [handle] remove a player from the table
  .bjk.cp:.bjk.cp _ h;                                                                             / drop the connection
  .bjk.users:.bjk.users _ h;                                                                       / drop their username
  .bjk.joined:.bjk.joined _ h;                                                                     / drop their join round
  .bjk.chips:.bjk.chips _ h;                                                                       / drop their chips
  .bjk.chipsDue:.bjk.chipsDue _ h;                                                                 / drop any buy-in deadline
  delete from`.bjk.tab where handle=h;                                                             / drop their hands
  delete from`.bjk.stake where handle=h;                                                           / drop their bet
 };

.bjk.leave:{[h]                                                                                    / [handle] handle a player leaving
  if[not .bjk.hd;.bjk.forfeit h];                                                                  / forfeit a hand in progress
  .bjk.logLeaver h;
  hadTurn:$[.bjk.hd;0b;h in exec handle from .bjk.tab where turn];                                 / was it their turn
  .bjk.unseat h;                                                                                   / remove them
  if[.bjk.insuring;:.bjk.closeInsuranceIfDone[]];                                                  / insurance may now be settled
  if[.bjk.hd;:.bjk.dealIfReady[]];                                                                 / everyone left may now have bet
  if[not hadTurn;:()];                                                                             / play carries on
  .bjk.nextTurn[];                                                                                 / move to the next player
 };

.bjk.isBanned:{.z.u in .bjk.banned};                                                               / is the caller banned

.bjk.turnAway:{[h]                                                                                 / [handle] turn a banned user away
  .log.info string[.z.u]," is banned from the table and was turned away";
  .bjk.sendMsg["You've been asked to leave this table";h];                                         / tell them
  .bjk.disconnect h;                                                                               / close their connection
 };

.z.po:{                                                                                            / new connection
  if[.bjk.isBanned[];:.bjk.turnAway .z.w];                                                         / turn away banned users
  .bjk.regConn .z.w;                                                                               / register it
  if[.bjk.isPit[];:()];                                                                            / the pitboss doesn't play
  .bjk.start[];                                                                                    / seat players and ask for bets
  neg[.z.w](.bjk.intro;`);                                                                         / send the help text
 };

.bjk.command:{                                                                                     / validate a player's message, e.g. .bjk.command"stake 10"
  c:$[10h=type x;parse x;x];                                                                       / parse a string command
  if[not(type[c]in 0 11h)&2=count c;'"Send a command, e.g. stake[10] or hit[]"];                   / must be one function and one argument
  if[not$[-11h=type first c;first[c]in .bjk.public;0b];'"Only ",(", "sv string .bjk.public)," can be called"]; / function must be public
  if[not(a~(::))|(a~`)|type[a:last c]in -5 -6 -7 -8 -9h;'"A command takes a single number, or nothing"]; / argument must be a number, :: or `
  :c;                                                                                              / validated parse tree
 };

.bjk.run:{value$[.bjk.isPit[];x;.bjk.command x]};                                                  / run a message, unchecked for the pitboss
.bjk.logFailure:{[e].log.warn string[.z.u],"'s request failed: ",e};                               / [error] log a failed request

.bjk.pg:{@[.bjk.run;x;{.bjk.logFailure x;'x}]};                                                    / sync handler: log a failure and return it
.bjk.ps:{@[.bjk.run;x;{.bjk.logFailure x;.bjk.sendMsg["That didn't work: ",x;.z.w]}]};             / async handler: log a failure and tell the sender

.bjk.disconnect:{[h]@[neg h;::;{}];hclose h};                                                      / [handle] flush pending messages and close

.bjk.askToLeave:{[h]                                                                               / [handle] see off a player who didn't buy chips in time
  .log.info string[.bjk.cp h]," was asked to leave: no chips";
  .bjk.sendMsg["You've been asked to leave the table: no chips";h];                                / tell them
  .bjk.leave h;                                                                                    / take them off the table
  .bjk.disconnect h;                                                                               / close their connection
 };

.bjk.chipsTimer:{.bjk.askToLeave each where .z.p>=.bjk.chipsDue};                                  / see off anyone past their buy-in deadline

.bjk.eject:{[h]                                                                                    / [handle] remove a suspected card counter
  if[not h in key .bjk.cp;:()];                                                                    / not seated
  n:string .bjk.cp h;                                                                              / their name
  if[not .bjk.ejectCounters;:.log.info"The pitboss suspects ",n," of counting cards (run with --pitboss 1 to eject)"]; / only log unless ejecting is on
  .log.warn"The pitboss has ejected ",n," for suspected card counting";
  .bjk.banned,:.bjk.users h;                                                                       / ban their username for the session
  .bjk.sendMsg["The pitboss has asked you to leave the table";h];                                  / tell them
  .bjk.leave h;                                                                                    / remove them from play
  .bjk.disconnect h;                                                                               / close their connection
 };

.z.pc:{                                                                                            / connection closed
  if[x=.bjk.pit;:.bjk.pit:0Ni];                                                                    / pitboss left
  if[not x in key .bjk.cp;:()];                                                                    / ignore handles that never joined, e.g. 0 when stdin closes
  .bjk.leave x;                                                                                    / remove them from play
 };

.z.ts:{.bjk.betTimer[];.bjk.insureTimer[];.bjk.turnTimer[];.bjk.chipsTimer[]};                     / run the bet, insurance, turn and buy-in clocks

.bjk.libs:`:src/server/lib/messaging.q`:src/server/lib/deck.q`:src/server/lib/deal.q`:src/server/lib/actions.q; / server libraries, loaded at init
.bjk.loadLibs:{.utl.require each .bjk.libs};

.bjk.init:{                                                                                        / start the server
  .utl.addOptDef["seed";"I";"i"$.z.i+.z.t;`.bjk.seed];                                             / --seed: random seed, time-based by default
  .utl.addOptDef["pitboss";"B";0b;`.bjk.ejectCounters];                                            / --pitboss: eject suspected card counters
  .utl.parseArgs[];                                                                                / parse the command line
  system"S ",string .bjk.seed;
  if[not system"p";system"p 5555"];
  system"t 1000";
  .bjk.loadLibs[];
  .z.pg:.bjk.pg;                                                                                   / validate sync messages
  .z.ps:.bjk.ps;                                                                                   / validate async messages
  .log.info"Welcome to Qsino Blackjack!";
  .bjk.buildDeck[];                                                                                / build the shoe
  .bjk.shuffle[];                                                                                  / shuffle it
 };

.util.run[`blackjack.q;`.bjk.init];                                                                / init when run as the entry script
