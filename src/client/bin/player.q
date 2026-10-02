if[not`utl in key`;system"l vendor/qutil/bootstrap.q";.utl.QPATH:`:vendor`:src];
.utl.require"common";

.plr.pt:`avgPlayer1`avgPlayer2`avgPlayer3;                                                         / valid --player strategies: average players
.plr.pt,:`basicCardCounter`smallSpreadBasicCardCounter`omegaCardCounter`perfectCardCounter;        / and card counters
.plr.handDict:`H`S`D`SP!`hit`stick`double`split;                                                   / strategy chart code to server action

.plr.stake:{-1"It's your turn to stake - run stake[bet] when ready"};                              / prompt to stake; a loaded strategy replaces it
.plr.play:{-1"It's your turn to play - run hit[]/stick[]/double[]/split[] when ready"};            / prompt to play; a loaded strategy replaces it
.plr.insure:{                                                                                      / prompt to insure; a loaded strategy replaces it
  -1"Dealer shows an ace - run insure[amount] (up to half your bet, or insure[0] to decline) when ready";
 };
.plr.shuffle:{-1"Deck reshuffled"};                                                                / note a reshuffle; a loaded strategy replaces it

.plr.dispatch:{[f;arg].plr.h(f;arg)};                                                              / [function;argument] call a server function and return its result
stake:{.plr.dispatch[`stake;x]};                                                                   / place a bet
hit:{.plr.dispatch[`hit;x]};                                                                       / take a card
stick:{.plr.dispatch[`stick;x]};                                                                   / stick
double:{.plr.dispatch[`double;x]};                                                                 / double
split:{.plr.dispatch[`split;x]};                                                                   / split
insure:{.plr.dispatch[`insure;x]};                                                                 / take insurance, up to half the bet
buyin:{.plr.dispatch[`buyin;x]};                                                                   / buy chips
hist:{.plr.dispatch[`hist;x]};                                                                     / hand results so far

.plr.init:{                                                                                        / start the client
  .utl.addOptDef["player";"S";`;`.plr.player];                                                     / --player: strategy to play; manual if omitted
  .utl.addOptDef["server";"S";`:localhost:5555;{`.plr.server set hsym x}];                         / --server: blackjack server address
  .utl.addOptDef["hands";"I";1000i;`.plr.toth];                                                    / --hands: hands to play before leaving; auto mode only
  .utl.addOptDef["buyin";"J";1000;`.plr.buyin];                                                    / --buyin: chips to buy when I sit down
  .utl.parseArgs[];                                                                                / parse the command line
  if[not null .plr.player;                                                                         / a strategy was chosen
    if[not .plr.player in .plr.pt;                                                                 / unknown strategy: exit
      .log.error"Unknown player, options - ",.util.clist .plr.pt;
      exit 1;                                                                                      / quit
    ];
    .utl.require hsym`$"src/client/lib/",string[.plr.player],".q";
  ];
  s:`$string[.plr.server],":",string[.z.u],":",string .plr.buyin;                                  / server address, with my buy-in as the password
  .plr.h:@[hopen;s;{-1"Sorry, no tables currently available: ",x;exit 1}];                         / connect, or exit
  .z.pc:{if[x=.plr.h;-1"Disconnected from the table";exit 0]};                                     / exit when the server disconnects
 };

.util.run[`player.q;`.plr.init];                                                                   / init when run as the entry script

