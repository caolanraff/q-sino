if[not`utl in key`;system"l vendor/qutil/bootstrap.q";.utl.QPATH:`:vendor`:src];
.utl.require"common";

.plr.pt:`avgPlayer1`avgPlayer2`avgPlayer3`basicCardCounter`smallSpreadBasicCardCounter`omegaCardCounter`perfectCardCounter;
.plr.handDict:`H`S`D`SP!`hit`stick`double`split;

.plr.stake:{-1"It's your turn to stake - run stake[bet] when ready"};                               / manual-play default; a strategy's strategy.q replaces it
.plr.play:{-1"It's your turn to play - run hit[]/stick[]/double[]/split[] when ready"};
.plr.insure:{-1"Dealer shows an ace - run insure[amount] (up to half your bet, or insure[0] to decline) when ready"};
.plr.shuffle:{-1"Deck reshuffled"};

.plr.dispatch:{[f;arg].plr.h(f;arg)};
stake:{.plr.dispatch[`stake;x]};
hit:{.plr.dispatch[`hit;x]};
stick:{.plr.dispatch[`stick;x]};
double:{.plr.dispatch[`double;x]};
split:{.plr.dispatch[`split;x]};
insure:{.plr.dispatch[`insure;x]};
hist:{.plr.dispatch[`hist;x]};

.plr.init:{
  .utl.addOptDef["player";"S";`;`.plr.player];
  .utl.addOptDef["server";"S";`:localhost:5555;{`.plr.server set hsym x}];
  .utl.addOptDef["hands";"I";1000i;`.plr.toth];                                                    / auto mode only: strategy.q's .plr.stake counts hands
  .utl.parseArgs[];
  if[not null .plr.player;
    if[not .plr.player in .plr.pt;-1"[ERROR] Unknown player, options - ",","sv string .plr.pt;exit 1];
    .utl.require hsym`$"src/client/lib/",string[.plr.player],".q";
  ];
  .plr.h:@[hopen;.plr.server;{-1"Sorry, no tables currently available: ",x;exit 1}];
 };

if[.cmn.isMain`player.q;.plr.init[]];

