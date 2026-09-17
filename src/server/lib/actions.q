/// Checks function ///
checks:{
  if[not .z.w=first exec handle from .bs.tab where turn,out=0;
    pubMsg[string[.z.u]," is trying to play ahead of his turn";.z.w];:0b];
  if[(first exec cnt from .bs.tab where turn)>21;
    pubMsg["Too late, games already over. Please wait until next hand ",(string .z.u);.z.w];:0b];
  1b
  };

/// Stick function ///
.bs.stick0:{
	pubMsg[(string .z.u)," has decided to stick";key cp];
	update wait:1b, turn:0b from `.bs.tab where turn;
	update turn:1b from `.bs.tab where player=(exec first player from .bs.tab where out=0b,wait=0b,not turn);
	.bs.turn:select player,name,cards,cnt,dealer,dealerCnt,bet,return,out,wait,turn from .bs.tab;
	acelow::0;
	$[(count select from .bs.tab where turn)=0;
		[pubMsg["Everyone has played their hand, now it's the dealers turn";key cp];
		 .bs.dealer[]];
		[h:first exec handle from .bs.tab where turn;
		 p:first exec name from .bs.tab where handle=h;
		 pubMsg["It's ",string[p],"'s turn";h];
		 {sendMsg[.bs.turn;x]}each key cp;
		 if[h in autoH;neg[h](`play;`)]]];
	};

stick:{
	if[not checks[];:()];
	.bs.stick0[];
	};

/// Hit function ///
.bs.hit0:{
	UH:getCard[];
	pubMsg["Hit by ",(string .z.u);key cp];
	pubMsg[(string .z.u)," got a ",(string UH);key cp];
	update cards:(cards,'UH) from `.bs.tab where handle=.z.w,turn;
	UH:cardDict[UH];
	ucnt:("I"$(string UH))+(first exec cnt from .bs.tab where turn);

	if[(UH=`11)&(ucnt>21);
		ucnt:ucnt-10i;acelow+::1];
	if[all((ucnt>21);((count a[where a=`A])>acelow);(`A in a:(raze exec cards from .bs.tab where turn)));
		ucnt:ucnt-10i;
		$[`A`A~(2#a);acelow+::2;acelow+::1]];

	pubMsg[(string .z.u),"'s count is now ",(string ucnt);key cp];
	update cnt:ucnt from `.bs.tab where handle=.z.w,turn;
	};

.bs.hit1:{
	h:first exec handle from .bs.tab where turn;
	ucnt:first exec cnt from .bs.tab where handle=.z.w,turn;

	if[ucnt=21;
		pubMsg[(string .z.u)," is on 21";key cp];
		stick[]];

	if[ucnt>21;
		pubMsg[(string .z.u)," is now bust!";key cp];
		update return:0f, out:1b, turn:0b from `.bs.tab where handle=h;
		update turn:1b from `.bs.tab where player=(exec first player from .bs.tab where out=0b, wait=0b);
		.bs.turn:select player,name,cards,cnt,dealer,dealerCnt,bet,return,out,wait,turn from .bs.tab;
		acelow::0;
		$[(count select from .bs.tab where turn)=0;
			[pubMsg["Everyone has played their hand, now it's the dealers turn";key cp];
			 .bs.dealer[]];
			[p:first exec name from .bs.tab where turn;
			 h:first exec handle from .bs.tab where turn;
			 sendMsg[(string p)," it's your turn";h];
			 {neg[x](show;.bs.turn)}'[key cp];
			 if[h in autoH;neg[h](`play;`)]]];
		 DT:DC];

	if[ucnt<21;
		$[.bs.double;
			stick[];
		  [sendMsg["Hit or Stick?";h];
		   if[h in autoH;neg[h](`play;`)]]]];
	};

hit:{
  if[not checks[];:()];
  .bs.hit0[];
  .bs.hit1[];
  };

/// Double function ///
double:{
  if[not checks[];:()];
  if[not 2=first exec count each cards from .bs.tab where turn;
    pubMsg["You can't double after getting a third card ",(string .z.u);.z.w];:()];
  pubMsg["Bet doubled by ",(string .z.u);key cp];
  update bet:bet*2,double:1b from `.bs.tab where turn;
  .bs.double:1b;
  hit[];
  .bs.double:0b;
  };

/// Split function ///
.bs.split0:{
	update player:`float$player from `.bs.tab;
	if[((first exec player from .bs.tab where turn)=1)|((first exec player from .bs.tab where turn)=2);
		update player:player+.01 from `.bs.tab where turn];
	current:select from .bs.tab where turn;
	pnum:(exec max player from .bs.tab where handle=.z.w)+.01;
	current:update player:pnum from current;
	upsert[`.bs.tab;enlist value exec from current];
	update cards:1#'cards,cnt:`int$(cnt%2) from `.bs.tab where turn;
	update turn:0b from `.bs.tab where turn,player=last player;
	update splithand:(1 2) from `.bs.tab where (count each cards)=1;
	`player xasc `.bs.tab;
	show .bs.tab;
	};

.bs.splitHit:{
  .bs.hit0[];
  update turn:0b from `.bs.tab where turn,splithand=1;
  update turn:1b from `.bs.tab where not turn,splithand=2;
  .bs.hit0[];
  update turn:1b from `.bs.tab where not turn,splithand=1;
  update turn:0b from `.bs.tab where turn,splithand=2;
  delete splithand from `.bs.tab;
  .bs.hit1[];
  };

split:{
  if[not checks[];:()];
  if[not 1=count distinct crds:cardDict[first exec cards from .bs.tab where turn];
  sendMsg["You can't split this hand ",(string .z.u);.z.w];:()];
  pubMsg[(string .z.u)," is splitting";key cp];
  if[all crds=`11`11;update cnt:22i from `.bs.tab where turn];
  update split:1b from `.bs.tab where turn;
  .bs.split0[];
  .bs.splitHit[];
  };
