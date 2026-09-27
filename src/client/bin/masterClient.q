.mc.pt:`avgPlayer1`avgPlayer2`avgPlayer3`basicCardCounter`smallSpreadBasicCardCounter`omegaCardCounter`perfectCardCounter;
.mc.handDict:`H`S`D`SP!`hit`stick`double`split;

.mc.stake:{-1"It's your turn to stake - run stake[bet] when ready"};                               / manual-play default; a strategy's playerCore.q replaces it
.mc.play:{-1"It's your turn to play - run hit[]/stick[]/double[]/split[] when ready"};
.mc.insure:{-1"Dealer shows an ace - run insure[amount] (up to half your bet, or insure[0] to decline) when ready"};
.mc.shuffle:{-1"Deck reshuffled"};

.mc.dispatch:{[f;arg].mc.h(f;arg)};
stake:{.mc.dispatch[`stake;x]};
hit:{.mc.dispatch[`hit;x]};
stick:{.mc.dispatch[`stick;x]};
double:{.mc.dispatch[`double;x]};
split:{.mc.dispatch[`split;x]};
insure:{.mc.dispatch[`insure;x]};
hist:{.mc.dispatch[`hist;x]};

.mc.init:{
  system"c 20 200";
  args:.Q.opt .z.x;
  .mc.toth:$[`hands in key args;"I"$raze args`hands;1000i];                                        / auto mode only: playerCore.q's .mc.stake counts hands
  if[`player in key args;
    p:$[count py:`$raze args`player;py;`];
    if[not p in .mc.pt;-1"[ERROR] Unknown player, options - ",","sv string .mc.pt;exit 1];
    system"l src/client/lib/",string[p],".q";
  ];
  .mc.h:@[hopen;5555;{-1"Sorry, no tables currently available: ",x;exit 1}];
 };

if[not[null .z.f]&"masterClient.q"~last"/"vs string .z.f;.mc.init[]];

