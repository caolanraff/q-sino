if[not`utl in key`;system"l vendor/qutil/bootstrap.q";.utl.QPATH:`:vendor`:src];
.utl.require"common";

.plr.pt:`avgPlayer1`avgPlayer2`avgPlayer3;                                                         / valid --player strategies: average players
.plr.pt,:`basicCardCounter`smallSpreadBasicCardCounter`omegaCardCounter`perfectCardCounter;        / and card counters
.plr.handDict:`H`S`D`SP!`hit`stick`double`split;                                                   / strategy chart code to server action

.plr.stake:.plr.play:.plr.insure:{.plr.state:x};                                                   / manual play: keep the pushed state; a strategy replaces these
.plr.shuffle:{-1"Deck reshuffled"};                                                                / note a reshuffle; a loaded strategy replaces it

.plr.state:()!();                                                                                  / the last state the server pushed; none until I've bought in

.plr.goodbye:{                                                                                     / the parting line, with what I leave with and my return
  m:"Thanks for playing q-sino blackjack!";                                                        / the thanks
  if[0=count s:.plr.state;:m];                                                                     / never bought in
  left:s[`chips]-exec sum(0^bet)+0^insurance from s[`tab]where handle=s`me;                        / less any bets still on the table, which leaving forfeits
  net:left-s`bought;                                                                               / my return
  :m," You leave with $",.Q.f[2;left]," in chips, ",$[net<0;"down";"up"]," $",.Q.f[2;abs net];     / say so
 };

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
  .utl.addOptDef["buyin";"J";1000;`.plr.buyin];                                                    / --buyin: chips to buy on joining
  .utl.parseArgs[];                                                                                / parse the command line
  if[not null .plr.player;                                                                         / a strategy was chosen
    if[not .plr.player in .plr.pt;                                                                 / unknown strategy: exit
      .log.error"Unknown player, options - ",.util.clist .plr.pt;
      exit 1;                                                                                      / quit
    ];
    .utl.require hsym`$"src/client/lib/",string[.plr.player],".q";
  ];
  .plr.h:@[hopen;.plr.server;{-1"Sorry, no tables currently available: ",x;exit 1}];               / connect, or exit
  neg[.plr.h](`buyin;.plr.buyin);                                                                  / buy in; async, so it reaches the server before my first bet
  .z.pc:{if[x=.plr.h;-1"Disconnected from the table";exit 0]};                                     / exit when the server disconnects
  .z.exit:{-1 .plr.goodbye[]};                                                                     / say goodbye however I leave
 };

.util.run[`player.q;`.plr.init];                                                                   / init when run as the entry script

