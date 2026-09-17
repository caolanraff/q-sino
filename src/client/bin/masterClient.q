\c 20 200

pt:`avgPlayer1`avgPlayer2`avgPlayer3`basicCardCounter`smallSpreadBasicCardCounter`omegaCardCounter`perfectCardCounter;

ld:{
  system"l src/client/lib/playerCore.q";
  system"l src/client/lib/",string[x],".q";
  };

/// Play functions ///

getTab:{set[`.mc.tab;h`.bs.tab]};
getRes:{set[`.mc.res;h`.bs.res]};

stake:{
  Count[];
  bet:getBet[];
  neg[h](`stake;bet);
  };

handDict:`H`S`D`SP!`hit`stick`double`split;

play:{
  getTab[];
  .mc.c:(raze exec cards from .mc.tab where turn=1),raze exec dealer from .mc.tab where turn=1;
  dec:handDict Help[.mc.c];
  .mc.dec,:select round,cards,cnt,enlist each dealer,dealerCnt,decision:dec from .mc.tab where handle=mh;
  neg[h](dec;`);
  };

/// start ///

init:{
  args:.Q.opt .z.x;
  if[not `player in key args;show"[ERROR] Missing player in command line, options - ",","sv string pt;exit 1];
  p:$[count py:`$raze args[`player];py;`];
  if[(null p)|(not p in pt);show"[ERROR] Unknown player, options - ",","sv string pt;exit 1];
  ld[p];
  h::@[hopen;5555;{show"Sorry, no tables currently available";exit 1}];
  mh::h`.z.w;
  h"regAuto[]";
  };

if[(not null .z.f) and "masterClient.q"~last "/" vs string .z.f;init[]];
