\c 20 200

pt:`avgPlayer1`avgPlayer2`avgPlayer3`basicCardCounter`smallSpreadBasicCardCounter`omegaCardCounter`perfectCardCounter;

// each strategy file in src/client/lib/ loads its own playerCore.q dependency at its top,
// so a new player file only needs to be dropped in here - it isn't coupled to this loader
ld:{if[not null x;system"l src/client/lib/",string[x],".q"]};

/// Play functions ///

getTab:{set[`.mc.tab;h`.bs.tab]};
getRes:{set[`.mc.res;h`.bs.res]};

handDict:`H`S`D`SP!`hit`stick`double`split;

// log-only defaults for a manual player; -player loads a strategy (which loads playerCore.q),
// overriding these with the real auto-play logic (see ld[] and its use in init[] below)
.mc.stake:{-1"It's your turn to stake - run stake[bet] when ready"};
.mc.play:{-1"It's your turn to play - run hit[]/stick[]/double[]/split[] when ready"};
.mc.shuffle:{-1"Deck reshuffled"};

/// start ///

init:{
  args:.Q.opt .z.x;
  p:`;
  if[`player in key args;
    p:$[count py:`$raze args[`player];py;`];
    if[(null p)|(not p in pt);show"[ERROR] Unknown player, options - ",","sv string pt;exit 1]];
  ld[p];
  h::@[hopen;5555;{show"Sorry, no tables currently available";exit 1}];
  mh::h`.z.w;
  };

if[(not null .z.f) and "masterClient.q"~last "/" vs string .z.f;init[]];
