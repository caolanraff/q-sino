.bs.checks:{
  if[not .z.w=first exec handle from .bs.tab where turn,not out;
    .bs.pubMsg[string[.z.u]," is trying to play ahead of their turn";.z.w];
    :0b;
  ];
  if[21<first exec cnt from .bs.tab where turn;
    .bs.pubMsg["Too late, the game's already over. Please wait until next hand ",string .z.u;.z.w];
    :0b;
  ];
  :1b;
 };

.bs.nextTurn:{
  update turn:1b from`.bs.tab where player=(exec first player from .bs.tab where not out,not wait);
  .bs.turn:select player,name,cards,cnt,dealer,dealerCnt,bet,return,out,wait,turn from .bs.tab;
  if[not any exec turn from .bs.tab;
    .bs.pubMsg["Everyone has played their hand, now it's the dealers turn";key .bs.cp];
    :.bs.dealer[];
  ];
  h:first exec handle from .bs.tab where turn;
  .bs.pubMsg["It's ",string[first exec name from .bs.tab where handle=h],"'s turn";h];
  .bs.sendMsg[.bs.turn]each key .bs.cp;
  .bs.trigger[`.mc.play;h];
 };

.bs.stick0:{
  .bs.pubMsg[string[.z.u]," has decided to stick";key .bs.cp];
  update wait:1b,turn:0b from`.bs.tab where turn;
  .bs.nextTurn[];
 };

stick:{
  if[not .bs.checks[];:()];
  .bs.stick0[];
 };

.bs.hit0:{
  c:.bs.getCard[];
  update cards:(cards,'c)from`.bs.tab where handle=.z.w,turn;
  total:.bs.handCount first exec cards from .bs.tab where turn;
  .bs.pubMsg[string[.z.u]," hits and gets a ",string[c],", count now ",string total;key .bs.cp];
  update cnt:total from`.bs.tab where handle=.z.w,turn;
 };

.bs.hit1:{
  h:first exec handle from .bs.tab where turn;
  total:first exec cnt from .bs.tab where turn;
  if[total=21;
    .bs.pubMsg[string[.z.u]," is on 21";key .bs.cp];
    :stick[];
  ];
  if[total>21;
    .bs.pubMsg[string[.z.u]," is now bust!";key .bs.cp];
    update return:0f,out:1b,turn:0b from`.bs.tab where turn;
    :.bs.nextTurn[];
  ];
  if[.bs.double;:stick[]];
  .bs.sendMsg["Hit or Stick?";h];
  .bs.trigger[`.mc.play;h];
 };

hit:{
  if[not .bs.checks[];:()];
  .bs.hit0[];
  .bs.hit1[];
 };

double:{
  if[not .bs.checks[];:()];
  if[2<>first exec count each cards from .bs.tab where turn;
    .bs.pubMsg["You can't double after getting a third card ",string .z.u;.z.w];
    :();
  ];
  .bs.pubMsg["Bet doubled by ",string .z.u;key .bs.cp];
  update bet:bet*2,double:1b from`.bs.tab where turn;
  .bs.double:1b;
  hit[];
  .bs.double:0b;
 };

insure:{[amt]
  if[not .bs.insuring;.bs.sendMsg["Insurance isn't on offer right now";.z.w];:()];
  if[not .z.w in exec handle from .bs.tab where null insurance;.bs.sendMsg["You've no hand waiting on insurance";.z.w];:()];
  if[null[amt]|(amt<0)|amt>0.5*first exec bet from .bs.tab where handle=.z.w;
    .bs.sendMsg["Insurance is between 0 and half your bet";.z.w];
    :();
  ];
  .bs.pubMsg[string[.z.u],$[amt=0;" declines insurance";" insures for $",string amt];key .bs.cp];
  update insurance:`float$amt from`.bs.tab where handle=.z.w;
  .bs.closeInsuranceIfDone[];
 };

.bs.split0:{
  update player:`float$player from`.bs.tab;
  if[(first exec player from .bs.tab where turn)in 1 2f;update player:player+.01 from`.bs.tab where turn];
  `.bs.tab upsert update player:.01+exec max player from .bs.tab where handle=.z.w from select from .bs.tab where turn;
  update cards:1#'cards,cnt:`int$cnt%2 from`.bs.tab where turn;
  update turn:0b from`.bs.tab where turn,player=last player;
  update splithand:1 2 from`.bs.tab where 1=count each cards;
  `player xasc`.bs.tab;
  .bs.lg .Q.s .bs.tab;
 };

.bs.splitHit:{
  .bs.hit0[];
  update turn:0b from`.bs.tab where turn,splithand=1;
  update turn:1b from`.bs.tab where not turn,splithand=2;
  .bs.hit0[];
  update turn:1b from`.bs.tab where not turn,splithand=1;
  update turn:0b from`.bs.tab where turn,splithand=2;
  delete splithand from`.bs.tab;
 };

.bs.standSplitAces:{
  .bs.pubMsg["Split aces get one card each - both hands stand";key .bs.cp];
  update wait:1b,turn:0b from`.bs.tab where handle=.z.w,split,not out,`A=first each cards;
  .bs.nextTurn[];
 };

.bs.splitRefusal:{
  c:first exec cards from .bs.tab where turn;
  if[2<>count c;:"You can only split your first two cards"];
  if[1<count distinct .bs.cardDict c;:"You can't split this hand"];
  if[.bs.maxSplitHands<=count select from .bs.tab where handle=.z.w;:"You can't split more than ",string[.bs.maxSplitHands-1]," times"];
  :"";
 };

split:{
  if[not .bs.checks[];:()];
  if[count r:.bs.splitRefusal[];:.bs.sendMsg[r," ",string .z.u;.z.w]];
  .bs.pubMsg[string[.z.u]," is splitting";key .bs.cp];
  aces:`A`A~first exec cards from .bs.tab where turn;
  if[aces;update cnt:22i from`.bs.tab where turn];
  update split:1b from`.bs.tab where turn;
  .bs.split0[];
  .bs.splitHit[];
  $[aces;.bs.standSplitAces[];.bs.hit1[]];
 };
