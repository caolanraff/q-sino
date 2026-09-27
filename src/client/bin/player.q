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
  system"c 20 200";
  args:.Q.opt .z.x;
  .plr.toth:$[`hands in key args;"I"$raze args`hands;1000i];                                        / auto mode only: strategy.q's .plr.stake counts hands
  if[`player in key args;
    p:$[count py:`$raze args`player;py;`];
    if[not p in .plr.pt;-1"[ERROR] Unknown player, options - ",","sv string .plr.pt;exit 1];
    system"l src/client/lib/",string[p],".q";
  ];
  .plr.h:@[hopen;5555;{-1"Sorry, no tables currently available: ",x;exit 1}];
 };

if[not[null .z.f]&"player.q"~last"/"vs string .z.f;.plr.init[]];

