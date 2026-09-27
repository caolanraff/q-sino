.bjk.checks:{
  if[.z.w<>first exec handle from .bjk.tab where turn,not out;
    .bjk.pubMsg[string[.z.u]," is trying to play ahead of their turn";.z.w];
    :0b;
  ];
  if[21<first exec cnt from .bjk.tab where turn;
    .bjk.pubMsg["Too late, the game's already over. Please wait until next hand ",string .z.u;.z.w];
    :0b;
  ];
  :1b;
 };

.bjk.nextTurn:{
  update turn:1b from`.bjk.tab where player=(exec first player from .bjk.tab where not out,not wait);
  .bjk.turn:select player,name,cards,cnt,dealer,dealerCnt,bet,return,out,wait,turn from .bjk.tab;
  if[not any exec turn from .bjk.tab;
    .bjk.pubMsg["Everyone has played their hand, now it's the dealers turn";key .bjk.cp];
    :.bjk.dealer[];
  ];
  h:first exec handle from .bjk.tab where turn;
  .bjk.pubMsg["It's ",string[first exec name from .bjk.tab where handle=h],"'s turn";h];
  .bjk.sendMsg[.bjk.turn]each key .bjk.cp;
  .bjk.trigger[`.plr.play;h];
 };

stick:{
  if[not .bjk.checks[];:()];
  .bjk.pubMsg[string[.z.u]," has decided to stick";key .bjk.cp];
  update wait:1b,turn:0b from`.bjk.tab where turn;
  .bjk.nextTurn[];
 };

.bjk.dealTo:{[p]
  c:.bjk.getCard[];
  update cards:(cards,'c)from`.bjk.tab where player=p;
  total:.bjk.handCount first exec cards from .bjk.tab where player=p;
  .bjk.pubMsg[string[.z.u]," hits and gets a ",string[c],", count now ",string total;key .bjk.cp];
  update cnt:total from`.bjk.tab where player=p;
 };

.bjk.hit1:{
  d:first select handle,cnt from .bjk.tab where turn;
  if[21=d`cnt;
    .bjk.pubMsg[string[.z.u]," is on 21";key .bjk.cp];
    :stick[];
  ];
  if[21<d`cnt;
    .bjk.pubMsg[string[.z.u]," is now bust!";key .bjk.cp];
    update return:0f,out:1b,turn:0b from`.bjk.tab where turn;
    :.bjk.nextTurn[];
  ];
  if[.bjk.double;:stick[]];
  .bjk.sendMsg["Hit or Stick?";d`handle];
  .bjk.trigger[`.plr.play;d`handle];
 };

hit:{
  if[.bjk.checks[];
    .bjk.dealTo first exec player from .bjk.tab where turn;
    .bjk.hit1[];
  ];
 };

double:{
  if[not .bjk.checks[];:()];
  if[2<>first exec count each cards from .bjk.tab where turn;
    .bjk.pubMsg["You can't double after getting a third card ",string .z.u;.z.w];
    :();
  ];
  .bjk.pubMsg["Bet doubled by ",string .z.u;key .bjk.cp];
  update bet:bet*2,double:1b from`.bjk.tab where turn;
  .bjk.double:1b;
  hit[];
  .bjk.double:0b;
 };

insure:{[amt]
  if[not .bjk.insuring;.bjk.sendMsg["Insurance isn't on offer right now";.z.w];:()];
  if[not .z.w in exec handle from .bjk.tab where null insurance;.bjk.sendMsg["You've no hand waiting on insurance";.z.w];:()];
  if[any(null amt;amt<0;amt>0.5*first exec bet from .bjk.tab where handle=.z.w);
    .bjk.sendMsg["Insurance is between 0 and half your bet";.z.w];
    :();
  ];
  .bjk.pubMsg[string[.z.u],$[amt=0;" declines insurance";" insures for $",string amt];key .bjk.cp];
  update insurance:`float$amt from`.bjk.tab where handle=.z.w;
  .bjk.closeInsuranceIfDone[];
 };

.bjk.split0:{[p]
  update player:`float$player from`.bjk.tab;
  q:.01+exec max player from .bjk.tab where handle=.z.w;
  `.bjk.tab upsert update player:q,turn:0b from select from .bjk.tab where player=p;
  update cards:1#'cards from`.bjk.tab where player in(p;q);
  `player xasc`.bjk.tab;
  :q;
 };

.bjk.standSplitAces:{[p;q]
  .bjk.pubMsg["Split aces get one card each - both hands stand";key .bjk.cp];
  update wait:1b,turn:0b from`.bjk.tab where player in(p;q);
  .bjk.nextTurn[];
 };

.bjk.refuseSplit:{.bjk.sendMsg[x," ",string .z.u;.z.w];0b};

.bjk.canSplit:{
  c:first exec cards from .bjk.tab where turn;
  if[2<>count c;:.bjk.refuseSplit"You can only split your first two cards"];
  if[1<count distinct .bjk.cardDict c;:.bjk.refuseSplit"You can't split this hand"];
  if[.bjk.maxSplitHands<=count select from .bjk.tab where handle=.z.w;
    :.bjk.refuseSplit"You can't split more than ",string[.bjk.maxSplitHands-1]," times";
  ];
  :1b;
 };

split:{
  if[not$[.bjk.checks[];.bjk.canSplit[];0b];:()];
  .bjk.pubMsg[string[.z.u]," is splitting";key .bjk.cp];
  p:"f"$first exec player from .bjk.tab where turn;
  aces:`A`A~first exec cards from .bjk.tab where player=p;
  update split:1b from`.bjk.tab where player=p;
  q:.bjk.split0 p;
  .bjk.dealTo each p,q;
  $[aces;.bjk.standSplitAces[p;q];.bjk.hit1[]];
 };
