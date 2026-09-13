/// Init ///
\c 100 200

args:.Q.opt .z.x;
if[not `gameplay in key args;show"[ERROR] Missing gameplay in command line";exit 1];
gp:`$raze args[`gameplay];
if[not gp in `auto`manual;show"[ERROR] Unknown gameplay";exit 1];

seed:$[`seed in key args;"I"$raze args[`seed];(first "I"$(system "date +%s"))+"i"$.z.t];
system "S ",string seed;

toth:$[`hands in key args;"I"$raze args[`hands];1000i];

port:$[`port in key args;"I"$raze args[`port];5555i];
system "p ",string port;

.bs.hd:1b;
.bs.bd:.bs.double:0b;
.bs.rnd:0;
DA:0Ni;	    //detection algo handle

cardDict:`A`K`Q`J`10`9`8`7`6`5`4`3`2!`11`10`10`10`10`9`8`7`6`5`4`3`2;
deck:raze 4#enlist key cardDict;
deckCnt:6;
shufflecnt:0;

cp:()!();
.bs.res:.bs.tab:.bs.hist:flip `round`player`name`handle`cards`cnt`dealer`dealerCnt`bet`return`profit`split`double!();
.bs.stake:([name:();handle:()]bet:());

/// Start up functions ///
srv:first system "dirname $(dirname $(realpath ",(1_string hsym .z.f),"))";
system "l ",srv,"/lib/messaging.q";

intro:{
  show "Welcome to Qsino Blackjack!";
  show "Functions;";
  show " stake     - How much you want to bet. Default is no bet";
  show " hit       - Gives you another card";
  show " stick     - Stay with your current hand";
  show " split     - Split your hand";
  show " double    - Double your hand.";
  show " hist      - Hand results so far";
  show " shuffle   - Shuffle the cards";
  show " buildDeck - Builds the deck. Can input required amount, default is 6";
  };

.bs.start:{
  if[not .bs.hd;sendMsg"Please wait until the hand is over";:()];
  if[0=count cp;lg"No users are connected";:()];
  cpn:(!) . value flip distinct select handle,name from .bs.tab;
  $[cpn~cp;
    lg"No new users have joined the table";
    lg"New users have joined the table"];
  .bs.tab:0#.bs.tab;
  .bs.stake:0#.bs.stake;
  `.bs.tab upsert ([]player:1+til count cp;name:value cp;handle:key cp);
  sendMsg["Please place your bets via the stake[] function"]each key cp;
  if[gp=`auto;excFunc[`stake;`]each key cp];
  };

leave:{[h]
  .[sendMsg;("Your total winnings are - $",(string (exec sum return from .bs.res where handle=h));h);{}];
  .[sendMsg;("Thanks for playing Qasino Blackjack";h);{}];
  p:exec first player from .bs.tab where handle=h;
  lg string[p]," has left the table";
  cp::h _cp;
  delete from `.bs.tab where handle=h;
  };

.z.po:{regConn[.z.w];if[not isDA[];.bs.start[];neg[.z.w](intro;`)]};
.z.pc:{$[x=DA;DA::0Ni;leave x]};

/// Deck functions ///
system "l ",srv,"/lib/deck.q";

/// Stake function ///
stake:{
  if[1>bet:x;sendMsg["Put some money down on the table or move on";.z.w];:()];
  if[not .bs.hd;sendMsg["Please wait until the current hand is complete";.z.w];:()];
  lg string[.z.u]," bets $",string bet;
  upsert[`.bs.stake;(user[];.z.w;bet)];
  .bs.bd:1b;
  .bs.tab:.bs.tab lj .bs.stake;
  if[0=count select from .bs.tab where null bet;
    lg"All players have placed their bet";
    lg"Time to deal";
    .bs.deal[]];
  };

/// Deal function ///
.bs.deal0:{
	if[0=count .bs.tab;lg"No players at the table";:()];
	if[(count .bs.deck)<78;lg"Deck needs reshuffled";buildDeck[];shuffle[]];

	.bs.hd:acelow::acelowD::wwch::0b;
	.bs.rnd+:1;num:count .bs.tab;
	update round:.bs.rnd,cnt:num#0Ni,out:num#0b,wait:num#0b,turn:num#0b,split:num#0b,double:num#0b from `.bs.tab;

	while[count pd:select from .bs.tab where (count each cards)=0;dealCard[pd]];

	DC1:getCard[];
	pubMsg["Dealers first card is ",(string DC1);key cp];
	update dealer:num#DC1 from `.bs.tab;
	D:cardDict[DC1];
	update dealerCnt:num#"I"$(string D) from `.bs.tab;

	while[count pd:select from .bs.tab where (count each cards)=1;dealCard[pd]];

	DC2:getCard[];
	pubMsg["Dealers second card is dealt face down";key cp];
	DC::DC1,DC2;

	while[(count select from .bs.tab where null cnt)>0;
		h:first exec handle from .bs.tab where null cnt;
		UC:(first exec cards from .bs.tab where handle=h);
		sendMsg["Your hand is ",(string first UC),",",(string last UC);h];
		U::cardDict[UC];
		ucnt:("I"$(string first U))+("I"$(string last U));
		if[all U=`11`11;ucnt:12i];
		update cnt:ucnt from `.bs.tab where handle=h;
		$[ucnt=21;
			[$[("I"$(string first D))>=10;
					stick[];
					[sendMsg["Winner winner chicken dinner!";h];
					 update return:`float$(((bet*3)%2)+bet),out:1b,turn:0b from `.bs.tab where handle=h;
					 if[not count select from .bs.tab where not out;
					  .bs.hd:1b;wwch::1b;
					  .bs.dealer[]]]]];
			[$[(first U)~(last U);
				sendMsg["Hit, stick or split?";h];
				sendMsg["Hit or stick?";h]]]]];
	};

.bs.deal:{
	if[not .bs.hd;lg"Please finish the previous hand before dealing again";:()];
	if[not .bs.bd;lg"Please place your bets!";:()];
	if[count h:exec handle from .bs.tab where null bet;
		sendMsg["No bet placed, please wait until the next hand";h];
		delete from `.bs.tab where null bet];
	.bs.deal0[];
	if[not .bs.hd;
    update turn:1b from `.bs.tab where player=(exec first player from .bs.tab where out=0b);
    show .bs.tab;
    .bs.turn:select player,name,cards,cnt,dealer,dealerCnt,bet,return,out,wait,turn from .bs.tab;
    sendMsg[.bs.turn]each key cp;
    lg"The count is ",(string .bs.count);
    h:first exec handle from .bs.tab where turn;
    if[gp=`auto;neg[h](`play;`)]];
	};

/// Dealer function ///
.bs.dealer0:{
	pubMsg["Dealer has ",(string first DC),",",(string last DC);key cp];
	update dealer:(dealer,'(last DC)) from `.bs.tab;
	D::cardDict[DC];
	DCount::sum "I"$string D;
	if[all DC=`A`A;DCount::12i];
	pubMsg["Dealers hand count is ",(string DCount);key cp];
	update dealerCnt:DCount from `.bs.tab;
	DT:DC;

	while[DCount<17;
		DH:getCard[];
		pubMsg["Dealers gets a ",(string DH);key cp];
		update dealer:(dealer,'DH) from `.bs.tab;
		DH:cardDict[DH];
		DT::DC,DH;
		DCount::("I"$(string DH))+DCount;
		if[(DH=`11)&(DCount>21);DCount::DCount-10i];
		if[all((`A in DC);(DCount>21);(acelowD=0b));DCount::DCount-10i;acelowD::1b];
		pubMsg["Dealers hand count is now ",(string DCount);key cp];
		update dealerCnt:DCount from `.bs.tab];
	};

.bs.dealer1:{[p]
	d:first select from .bs.tab where player=p;
	ucnt:d[`cnt];h:d[`handle];nam:d[`name];

	if[DCount>21;
		$[ucnt<=21;
			[pubMsg["Dealer busts! Player wins!";h];
			 update return:`float$(bet*2) from `.bs.tab where player=p];
			[pubMsg["Dealer busts also, no winner!";h];
			  update return:0f from `.bs.tab where player=p]]];

	if[(DCount=ucnt)&ucnt<=21;
			pubMsg["Push! ",(string nam)," gets their money back!";h];
			update return:`float$bet from `.bs.tab where player=p];

	if[DCount<21;
		 if[DCount>ucnt;
			 pubMsg["Dealer wins!";h];
			 update return:0f from `.bs.tab where player=p];
		 if[DCount<ucnt;
			 $[ucnt>21;
				[pubMsg["Dealer wins!";h];
				 update return:0f from `.bs.tab where player=p];
				[$[all(ucnt=21;2=count first exec cards from .bs.tab where player=p;2<count first exec dealer from .bs.tab where player=p);
					[pubMsg[string[.z.u]," get's Blackjack!";h];
					  update return:`float$(((bet*3)%2)+bet) from `.bs.tab where player=p];
					[pubMsg[(string .z.u)," wins";h];
					  update return:`float$(bet*2) from `.bs.tab where player=p]]]]]];

	if[DCount=21;
		if[not ucnt=21;
			pubMsg["Dealer wins!";h];
			update return:0f from `.bs.tab where player=p]];
	};

.bs.dealer:{
	if[not wwch;
		$[0=count select from .bs.tab where out=0b;
			[pubMsg["Everyone's out!";key cp];
			 pubMsg["Dealer wins!";key cp];
		         update dealer:(dealer,'(last DC)) from `.bs.tab];
			[.bs.dealer0[];
			 while[(count select from .bs.tab where wait=1b)>0;
				p:first exec player from .bs.tab where wait=1b;
				.bs.dealer1[p];
				update wait:0b,out:1b from `.bs.tab where player=p]]]];

	lg"Hand stats;";
	show .bs.tab;
	if[wwch;update dealer:(enlist each dealer) from `.bs.tab];
	upsert[`.bs.res;update "j"$player,profit:return from delete out, wait, turn from .bs.tab];
	update profit:sums return by player from `.bs.res;
	.bs.sumtab:select player,name,cards,cnt,dealer,dealerCnt,bet,return from .bs.tab;
	sendMsg["Results table for the round;"]each key cp;
	sendMsg[.bs.sumtab]each key cp;
	update player:`int$player from `.bs.tab;
	.bs.bd:0b;.bs.hd:1b;
	pubMsg["~~~~~~~~~~~~ Game over ~~~~~~~~~~~~~~~";key cp];
	if[not null DA;excFunc[`gameover;.bs.res;DA]];
	$[(exec last round from .bs.res)>=toth;
		pubMsg["Total hands requested played";key cp];
		.bs.start[]];
	};

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
		 if[gp=`auto;neg[h](`play;`)]]];
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
			 if[gp=`auto;neg[h](`play;`)]]];
		 DT:DC];

	if[ucnt<21;
		$[.bs.double;
			stick[];
		  [sendMsg["Hit or Stick?";h];
		   if[gp=`auto;neg[h](`play;`)]]]];
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

/// Start ///
show "Welcome to Qsino Blackjack!";
buildDeck[];
shuffle[];
