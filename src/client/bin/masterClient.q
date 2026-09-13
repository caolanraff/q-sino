\c 20 200
args:.Q.opt .z.x;
pt:`avgPlayer1`avgPlayer2`avgPlayer3`basicCardCounter`smallSpreadBasicCardCounter`omegaCardCounter`perfectCardCounter;
if[not `player in key args;show"[ERROR] Missing player in command line, options - ",","sv string pt;exit 1];
p:$[count py:`$raze args[`player];py;`];
if[(null p)|(not p in pt);show"[ERROR] Unknown player, options - ",","sv string pt;exit 1];

port:$[`port in key args;"I"$raze args[`port];5555i];

cli:first system "dirname $(dirname $(realpath ",(1_string hsym .z.f),"))";
ld:{
  system"l ",cli,"/lib/playerCore.q";
  system"l ",cli,"/lib/",string[x],".q";
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

ld[p];
h:@[hopen;port;{show"Sorry, no tables currently available";exit 1}];
mh:h`.z.w;