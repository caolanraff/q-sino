\c 20 200

.mc.pt:`avgPlayer1`avgPlayer2`avgPlayer3`basicCardCounter`smallSpreadBasicCardCounter`omegaCardCounter`perfectCardCounter;

/// Play functions ///

.mc.handDict:`H`S`D`SP`SR!`hit`stick`double`split`surrender;

// log-only defaults for a manual player; -player loads a strategy (which loads playerCore.q),
// overriding these with the real auto-play logic (see .mc.init[] below)
.mc.stake:{-1"It's your turn to stake - run stake[bet] when ready"};
.mc.play:{-1"It's your turn to play - run hit[]/stick[]/double[]/split[] when ready"};
.mc.shuffle:{-1"Deck reshuffled"};

.mc.dispatch:{[f;x].mc.h(f;x)};
stake:{.mc.dispatch[`stake;x]};
hit:{.mc.dispatch[`hit;x]};
stick:{.mc.dispatch[`stick;x]};
double:{.mc.dispatch[`double;x]};
split:{.mc.dispatch[`split;x]};
surrender:{.mc.dispatch[`surrender;x]};
hist:{.mc.dispatch[`hist;x]};

/// start ///

.mc.init:{
  args:.Q.opt .z.x;
  p:`;
  if[`player in key args;
    p:$[count py:`$raze args[`player];py;`];
    if[(null p)|(not p in .mc.pt);show"[ERROR] Unknown player, options - ",","sv string .mc.pt;exit 1]];
  // number of hands this client plays before disconnecting; only meaningful in auto mode
  // (playerCore.q's .mc.stake counts them) - a manual player just disconnects themselves
  .mc.toth:$[`hands in key args;"I"$raze args[`hands];1000i];
  // each strategy file in src/client/lib/ loads its own playerCore.q dependency at its top,
  // so a new player file only needs to be dropped in here - it isn't coupled to this loader
  if[not null p;system"l src/client/lib/",string[p],".q"];
  .mc.h:@[hopen;5555;{show"Sorry, no tables currently available";exit 1}];
  };

if[(not null .z.f) and "masterClient.q"~last "/" vs string .z.f;.mc.init[]];
