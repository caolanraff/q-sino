.bs.checks:{
  if[.z.w<>first exec handle from .bs.tab where turn,not out;
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

stick:{
  if[not .bs.checks[];:()];
  .bs.pubMsg[string[.z.u]," has decided to stick";key .bs.cp];
  update wait:1b,turn:0b from`.bs.tab where turn;
  .bs.nextTurn[];
 };

.bs.dealTo:{[p]
  c:.bs.getCard[];
  update cards:(cards,'c)from`.bs.tab where player=p;
  total:.bs.handCount first exec cards from .bs.tab where player=p;
  .bs.pubMsg[string[.z.u]," hits and gets a ",string[c],", count now ",string total;key .bs.cp];
  update cnt:total from`.bs.tab where player=p;
 };

.bs.hit0:{.bs.dealTo first exec player from .bs.tab where turn};

.bs.hit1:{
  d:first select handle,cnt from .bs.tab where turn;
  if[d[`cnt]=21;
    .bs.pubMsg[string[.z.u]," is on 21";key .bs.cp];
    :stick[];
  ];
  if[d[`cnt]>21;
    .bs.pubMsg[string[.z.u]," is now bust!";key .bs.cp];
    update return:0f,out:1b,turn:0b from`.bs.tab where turn;
    :.bs.nextTurn[];
  ];
  if[.bs.double;:stick[]];
  .bs.sendMsg["Hit or Stick?";d`handle];
  .bs.trigger[`.mc.play;d`handle];
 };

hit:{if[.bs.checks[];.bs.hit0[];.bs.hit1[]]};

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

.bs.split0:{[p]
  update player:`float$player from`.bs.tab;
  q:.01+exec max player from .bs.tab where handle=.z.w;
  `.bs.tab upsert update player:q,turn:0b from select from .bs.tab where player=p;
  update cards:1#'cards from`.bs.tab where player in(p;q);
  `player xasc`.bs.tab;
  :q;
 };

.bs.standSplitAces:{
  .bs.pubMsg["Split aces get one card each - both hands stand";key .bs.cp];
  update wait:1b,turn:0b from`.bs.tab where handle=.z.w,split,not out,`A=first each cards;
  .bs.nextTurn[];
 };

.bs.refuseSplit:{.bs.sendMsg[x," ",string .z.u;.z.w];0b};

.bs.canSplit:{
  c:first exec cards from .bs.tab where turn;
  if[2<>count c;:.bs.refuseSplit"You can only split your first two cards"];
  if[1<count distinct .bs.cardDict c;:.bs.refuseSplit"You can't split this hand"];
  if[.bs.maxSplitHands<=count select from .bs.tab where handle=.z.w;:.bs.refuseSplit"You can't split more than ",string[.bs.maxSplitHands-1]," times"];
  :1b;
 };

split:{
  if[not .bs.checks[];:()];
  if[not .bs.canSplit[];:()];
  .bs.pubMsg[string[.z.u]," is splitting";key .bs.cp];
  p:"f"$first exec player from .bs.tab where turn;
  aces:`A`A~first exec cards from .bs.tab where player=p;
  update split:1b from`.bs.tab where player=p;
  .bs.dealTo each p,.bs.split0 p;
  $[aces;.bs.standSplitAces[];.bs.hit1[]];
 };
