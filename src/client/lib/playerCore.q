show"welcome to beating raffs blackjack";
show"we're starting the count at zero";
show"Your starting bet should be 25";

// init
theCount:0f;
bet:25;
decks:6;
startCards:decks*52;

// basic strategy for a 4-8 deck shoe, dealer hits soft 17, double after split, late surrender.
// each column is the dealer up-card; rows run over the table's hTotal. DS = double if allowed, else stand;
// R/RS/RP = surrender if allowed, else hit/stand/split
// hard hand
hTotal:3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21;
TWO:`H`H`H`H`H`H`H`D`D`H`S`S`S`S`S`S`S`S`S;
THREE:`H`H`H`H`H`H`D`D`D`H`S`S`S`S`S`S`S`S`S;
FOUR:`H`H`H`H`H`H`D`D`D`S`S`S`S`S`S`S`S`S`S;
FIVE:`H`H`H`H`H`H`D`D`D`S`S`S`S`S`S`S`S`S`S;
SIX:`H`H`H`H`H`H`D`D`D`S`S`S`S`S`S`S`S`S`S;
SEVEN:`H`H`H`H`H`H`H`D`D`H`H`H`H`H`S`S`S`S`S;
EIGHT:`H`H`H`H`H`H`H`D`D`H`H`H`H`H`S`S`S`S`S;
NINE:`H`H`H`H`H`H`H`D`D`H`H`H`H`R`S`S`S`S`S;
TEN:`H`H`H`H`H`H`H`H`D`H`H`H`R`R`S`S`S`S`S;
ACE:`H`H`H`H`H`H`H`H`D`H`H`H`R`R`RS`S`S`S`S;
hard:([hTotal]TWO;THREE;FOUR;FIVE;SIX;SEVEN;EIGHT;NINE;TEN;ACE);

// if player has an ACE the hand is considered a soft hand
hTotal:13 14 15 16 17 18 19 20 21;
TWO:`H`H`H`H`H`DS`S`S`S;
THREE:`H`H`H`H`D`DS`S`S`S;
FOUR:`H`H`D`D`D`DS`S`S`S;
FIVE:`D`D`D`D`D`DS`S`S`S;
SIX:`D`D`D`D`D`DS`DS`S`S;
SEVEN:`H`H`H`H`H`S`S`S`S;
EIGHT:`H`H`H`H`H`S`S`S`S;
NINE:`H`H`H`H`H`H`S`S`S;
TEN:`H`H`H`H`H`H`S`S`S;
ACE:`H`H`H`H`H`H`S`S`S;
soft:([hTotal]TWO;THREE;FOUR;FIVE;SIX;SEVEN;EIGHT;NINE;TEN;ACE);

//if we are dealt pairs
hTotal:2 3 4 5 6 7 8 9 10 11;
TWO:`SP`SP`H`D`SP`SP`SP`SP`S`SP;
THREE:`SP`SP`H`D`SP`SP`SP`SP`S`SP;
FOUR:`SP`SP`H`D`SP`SP`SP`SP`S`SP;
FIVE:`SP`SP`SP`D`SP`SP`SP`SP`S`SP;
SIX:`SP`SP`SP`D`SP`SP`SP`SP`S`SP;
SEVEN:`SP`SP`H`D`H`SP`SP`S`S`SP;
EIGHT:`H`H`H`D`H`H`SP`SP`S`SP;
NINE:`H`H`H`D`H`H`SP`SP`S`SP;
TEN:`H`H`H`H`H`H`SP`S`S`SP;
ACE:`H`H`H`H`H`H`RP`S`S`SP;
pair:([hTotal]TWO;THREE;FOUR;FIVE;SIX;SEVEN;EIGHT;NINE;TEN;ACE);

//mapping dealers cards to table headers
dealerDict:(`2`3`4`5`6`7`8`9`10`J`Q`K`11)!`TWO`THREE`FOUR`FIVE`SIX`SEVEN`EIGHT`NINE`TEN`TEN`TEN`TEN`ACE;

// used to get count
basic:`2`3`4`5`6`7`8`9`10`J`Q`K`A!1 1 1 1 1 0 0 0 -1 -1 -1 -1 -1;
omega:`2`3`4`5`6`7`8`9`10`J`Q`K`A!1 1 2 2 2 1 0 -1 -2 -2 -2 -2 0;
perfect:`2`3`4`5`6`7`8`9`10`J`Q`K`A!4 5 6 9 6 4 1 -2 -8 -8 -8 -8 -3;

setCountDict:{`countDict set value x};
setCountDict[`basic]; /can be overriden in player script

// keeps the current count of the cards. This should determine the players bet.
// every card seen in a set of result rows: each hand's cards, plus the dealer's hand once per round -
// every player's row carries its own copy of the dealer's cards (a forfeit row only the up-card, so take the longest).
// keep in sync with .da.cardsSeen (detectionAlgo.q)
.mc.cardsSeen:{[t]
  c:raze[t`cards],raze value exec {x first idesc count each x} dealer by round from t;
  c where not null c
  };

.mc.Count:{
  seen:.mc.cardsSeen[.mc.res],.mc.cardsSeen .mc.tab;
  runCount:sum countDict seen;
  theCount::runCount%(startCards-count seen)%52;	//true count
  };

.mc.shuffle:{theCount::0f};

// real auto-play hooks the server pushes to every connected handle; loaded whenever a
// strategy file loads this, overriding masterClient.q's log-only defaults
.mc.handsPlayed:0;

.mc.rules:enlist[`surrender]!enlist 0b;
.mc.recv:{[s].mc.tab:s`tab;.mc.res:s`res;.mc.mh:s`me;.mc.rules:s`rules};

.mc.stake:{[s]
  .mc.recv s;
  if[(.mc.handsPlayed+:1)>.mc.toth;
    -1"Played ",string[.mc.toth]," hand",$[.mc.toth=1;"";"s"],", disconnecting";
    hclose .mc.h;
    exit 0];
  .mc.Count[];
  bet:getBet[];
  neg[.mc.h](`stake;bet);
  };

// the server caps each player at this many hands (keep in sync with .bs.maxSplitHands, blackjackServer.q)
.mc.maxSplitHands:4;

// Help's decision for cards x, given the player already holds `hands` hands. A split the server
// would refuse (at the hand cap) never gets another .mc.play push, so play the pair as a hard total instead
.mc.decide:{[x;hands]
  r:Help[x];
  if[r in `R`RS`RP;r:$[.mc.rules[`surrender]&hands=1;`R;(`R`RS`RP!`H`S`SP)r]];
  if[(r=`SP)&hands>=.mc.maxSplitHands;
    r:first ?[hard;enlist(=;`hTotal;sum "I"$string .mc.cardDict[-1_x]);();first dealerDict[.mc.cardDict[last x]]];
    if[r in `R`RS;r:(`R`RS!`H`S)r]];
  :r;
  };

.mc.play:{[s]
  .mc.recv s;
  .mc.c:(raze exec cards from .mc.tab where turn=1),raze exec dealer from .mc.tab where turn=1;
  dec:.mc.handDict .mc.decide[.mc.c;count select from .mc.tab where handle=.mc.mh];
  .mc.dec,:select round,cards,cnt,enlist each dealer,dealerCnt,decision:dec from .mc.tab where handle=.mc.mh;
  neg[.mc.h](dec;`);
  };

// links www.blackjackinfo.com - lesson 14 part 2
// tells the player whether to hit or stick
.mc.cardDict:`A`K`Q`J`10`9`8`7`6`5`4`3`2!`11`10`10`10`10`9`8`7`6`5`4`3`2;

Help:{
  dc:.mc.cardDict[-1#x];
  pc:"I"$string .mc.cardDict[-1_x];
  csum:sum pc;
  if[all 11=distinct pc;:`SP];
  pc[(0|(sum pc=11)&ceiling (csum-21)%10)#where pc=11]:1;
  csum:sum pc;
  r:first $[any 11 in pc;
      ?[soft;enlist(=;`hTotal;csum);();first dealerDict[dc]];
    (pc[0]~pc[1])&(3>count pc);  //lost chance to split if count x>3 as we must have already hit
      ?[pair;enlist(=;`hTotal;pc[1]);();first dealerDict[dc]];
      ?[hard;enlist(=;`hTotal;csum);();first dealerDict[dc]]];
  if[(r=`D)&(2<count pc);:`H];
  if[r=`DS;:$[2<count pc;`S;`D]];
  if[(r=`SP)&(2<count pc);:`S];
  if[(r in `R`RS)&2<count pc;:(`R`RS!`H`S)r];
  r
  };
