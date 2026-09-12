show"welcome to beating raffs blackjack";
show"we're starting the count at zero";
show"Your starting bet should be 25";

// init
theCount:0f;
bet:25;
decks:6;
startCards:decks*52;

// hard hand
h:3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21;
TWO:`H`H`H`H`H`H`D`D`D`H`S`S`S`S`S`S`S`S`S;
THREE:`H`H`H`H`H`H`D`D`D`H`S`S`S`S`S`S`S`S`S;
FOUR:`H`H`H`H`H`H`D`D`D`S`S`S`S`S`S`S`S`S`S;
FIVE:`H`H`H`H`H`D`D`D`D`S`S`S`S`S`S`S`S`S`S;
SIX:`H`H`H`H`H`D`D`D`D`S`S`S`S`S`S`S`S`S`S;
SEVEN:`H`H`H`H`H`H`H`D`D`H`H`H`H`H`S`S`S`S`S;
EIGHT:`H`H`H`H`H`H`H`D`D`H`H`H`H`H`S`S`S`S`S;
NINE:`H`H`H`H`H`H`H`D`D`H`H`H`H`H`S`S`S`S`S;
TEN:`H`H`H`H`H`H`H`H`D`H`H`H`H`H`S`S`S`S`S;
ACE:`H`H`H`H`H`H`H`H`D`H`H`H`H`H`S`S`S`S`S;
hard:([h]TWO;THREE;FOUR;FIVE;SIX;SEVEN;EIGHT;NINE;TEN;ACE);

// if player has an ACE the hand is considered a soft hand
h:13 14 15 16 17 18 19 20 21;
TWO:`H`H`H`H`D`S`S`S`S;
THREE:`H`H`H`H`D`D`S`S`S;
FOUR:`D`D`D`D`D`D`S`S`S;
FIVE:`D`D`D`D`D`D`S`S`S;
SIX:`D`D`D`D`D`D`D`S`S;
SEVEN:`H`H`H`H`H`S`S`S`S;
EIGHT:`H`H`H`H`H`S`S`S`S;
NINE:`H`H`H`H`H`H`S`S`S;
TEN:`H`H`H`H`H`H`S`S`S;
ACE:`H`H`H`H`H`S`S`S`S;
soft:([h]TWO;THREE;FOUR;FIVE;SIX;SEVEN;EIGHT;NINE;TEN;ACE);

//if we are dealt pairs
h:2 3 4 5 6 7 8 9 10 11;
TWO:`SP`SP`H`D`SP`SP`SP`SP`S`SP;
THREE:`SP`SP`H`D`SP`SP`SP`SP`S`SP;
FOUR:`SP`SP`SP`D`SP`SP`SP`SP`S`SP;
FIVE:`SP`SP`SP`D`SP`SP`SP`SP`S`SP;
SIX:`SP`SP`SP`D`SP`SP`SP`SP`S`SP;
SEVEN:`SP`SP`H`D`SP`SP`SP`S`S`SP;
EIGHT:`H`SP`H`D`H`SP`SP`SP`S`SP;
NINE:`H`H`H`D`H`H`SP`SP`S`SP;
TEN:`H`H`H`H`H`S`SP`S`S`SP;
ACE:`H`H`H`H`H`H`SP`S`S`SP;
pair:([h]TWO;THREE;FOUR;FIVE;SIX;SEVEN;EIGHT;NINE;TEN;ACE);

//mapping dealers cards to table headers
dealerDict:(`2`3`4`5`6`7`8`9`10`J`Q`K`11)!`TWO`THREE`FOUR`FIVE`SIX`SEVEN`EIGHT`NINE`TEN`TEN`TEN`TEN`ACE;

// used to get count
basic:`2`3`4`5`6`7`8`9`10`J`Q`K`A!1 1 1 1 1 0 0 0 -1 -1 -1 -1 -1;
omega:`2`3`4`5`6`7`8`9`10`J`Q`K`A!1 1 2 2 2 1 0 -1 -2 -2 -2 -2 0;
perfect:`2`3`4`5`6`7`8`9`10`J`Q`K`A!4 5 6 9 6 4 1 -2 -8 -8 -8 -8 -3;

setCountDict:{`countDict set value x};
setCountDict[`basic]; /can be overriden in player script

// keeps the current count of the cards. This should determine the players bet.
Count:{
  getTab[];getRes[];
  acr:(,//)value exec cards,dealer from .mc.res;
  act:(,//)value exec cards,dealer from .mc.tab;
  runCount:sum countDict acr,act;
  theCount::runCount%(startCards-count acr)%52;	//true count
  };

shuffle:{theCount::0f};

// links www.blackjackinfo.com - lesson 14 part 2
// tells the player whether to hit or stick
cardDict:`A`K`Q`J`10`9`8`7`6`5`4`3`2!`11`10`10`10`10`9`8`7`6`5`4`3`2;

Help:{
  dc:cardDict[-1#x];
  pc:"I"$string cardDict[-1_x];
  csum:sum pc;
  if[all 11=distinct pc;:`SP];
  if[(11 in pc)&(csum>21);pc[where pc=11]:1;csum:sum pc];
  r:first $[any 11 in pc;
      ?[soft;enlist(=;`h;csum);();first dealerDict[dc]];
    (pc[0]~pc[1])&(3>count pc);  //lost chance to split if count x>3 as we must have already hit
      ?[pair;enlist(=;`h;pc[1]);();first dealerDict[dc]];
      ?[hard;enlist(=;`h;csum);();first dealerDict[dc]]];
  if[(r=`D)&(2<count pc);:`H];
  if[(r=`SP)&(2<count pc);:`S];
  r
  };