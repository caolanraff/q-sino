/// Stake function ///
stake:{
  if[1>bet:x;.bs.sendMsg["Put some money down on the table or move on";.z.w];:()];
  if[not .bs.hd;.bs.sendMsg["Please wait until the current hand is complete";.z.w];:()];
  .bs.lg string[.z.u]," bets $",string bet;
  upsert[`.bs.stake;(.bs.user[];.z.w;bet)];
  .bs.bd:1b;
  .bs.tab:.bs.tab lj .bs.stake;
  if[0=count select from .bs.tab where null bet;
    .bs.lg"All players have placed their bet";
    .bs.lg"Time to deal";
    .bs.deal[]];
  };

/// Deal function ///
.bs.deal0:{
	if[0=count .bs.tab;.bs.lg"No players at the table";:()];
	if[(count .bs.deck)<78;.bs.lg"Deck needs reshuffled";.bs.buildDeck[];.bs.shuffle[]];

	.bs.hd:.bs.acelow:.bs.acelowD:.bs.wwch:0b;
	.bs.rnd+:1;num:count .bs.tab;
	update round:.bs.rnd,cnt:num#0Ni,out:num#0b,wait:num#0b,turn:num#0b,split:num#0b,double:num#0b from `.bs.tab;

	.bs.dealCard each select from .bs.tab where (count each cards)=0;

	DC1:.bs.getCard[];
	.bs.pubMsg["Dealers first card is ",(string DC1);key .bs.cp];
	update dealer:num#DC1 from `.bs.tab;
	.bs.dealerUpValue:.bs.cardDict[DC1];
	update dealerCnt:num#"I"$(string .bs.dealerUpValue) from `.bs.tab;

	.bs.dealCard each select from .bs.tab where (count each cards)=1;

	DC2:.bs.getCard[];
	.bs.pubMsg["Dealers second card is dealt face down";key .bs.cp];
	.bs.dc:DC1,DC2;

	.bs.deal1 each exec handle from .bs.tab where null cnt;
	};

.bs.deal1:{[h]
	UC:(first exec cards from .bs.tab where handle=h);
	.bs.sendMsg["Your hand is ",(string first UC),",",(string last UC);h];
	U:.bs.cardDict[UC];
	ucnt:("I"$(string first U))+("I"$(string last U));
	if[all U=`11`11;ucnt:12i];
	update cnt:ucnt from `.bs.tab where handle=h;
	dealerUp10:("I"$(string first .bs.dealerUpValue))>=10;
	pair:(first U)~(last U);

	if[(ucnt=21)&dealerUp10;
		stick[];
		:()];
	if[ucnt=21;
		.bs.sendMsg["Winner winner chicken dinner!";h];
		update return:`float$(((bet*3)%2)+bet),out:1b,turn:0b from `.bs.tab where handle=h;
		if[not count select from .bs.tab where not out;
			.bs.hd:1b;.bs.wwch:1b;
			.bs.dealer[]];
		:()];
	if[pair;
		.bs.sendMsg["Hit, stick or split?";h];
		:()];
	.bs.sendMsg["Hit or stick?";h];
	};

.bs.deal:{
	if[not .bs.hd;.bs.lg"Please finish the previous hand before dealing again";:()];
	if[not .bs.bd;.bs.lg"Please place your bets!";:()];
	if[count h:exec handle from .bs.tab where null bet;
		.bs.sendMsg["No bet placed, please wait until the next hand";h];
		delete from `.bs.tab where null bet];
	.bs.deal0[];
	if[not .bs.hd;
    update turn:1b from `.bs.tab where player=(exec first player from .bs.tab where out=0b);
    show .bs.tab;
    .bs.turn:select player,name,cards,cnt,dealer,dealerCnt,bet,return,out,wait,turn from .bs.tab;
    .bs.sendMsg[.bs.turn]each key .bs.cp;
    .bs.lg"The count is ",(string .bs.count);
    h:first exec handle from .bs.tab where turn;
    .bs.excFunc[`.mc.play;`;h]];
	};

/// Dealer function ///
.bs.dealer0:{
	.bs.pubMsg["Dealer has ",(string first .bs.dc),",",(string last .bs.dc);key .bs.cp];
	update dealer:(dealer,'(last .bs.dc)) from `.bs.tab;
	D:.bs.cardDict[.bs.dc];
	.bs.dealerCount:sum "I"$string D;
	if[all .bs.dc=`A`A;.bs.dealerCount:12i];
	.bs.pubMsg["Dealers hand count is ",(string .bs.dealerCount);key .bs.cp];
	update dealerCnt:.bs.dealerCount from `.bs.tab;
	DT:.bs.dc;

	while[.bs.dealerCount<17;
		DH:.bs.getCard[];
		.bs.pubMsg["Dealers gets a ",(string DH);key .bs.cp];
		update dealer:(dealer,'DH) from `.bs.tab;
		DH:.bs.cardDict[DH];
		.bs.dt:.bs.dc,DH;
		.bs.dealerCount:("I"$(string DH))+.bs.dealerCount;
		if[(DH=`11)&(.bs.dealerCount>21);.bs.dealerCount:.bs.dealerCount-10i];
		if[all((`A in .bs.dc);(.bs.dealerCount>21);(.bs.acelowD=0b));.bs.dealerCount:.bs.dealerCount-10i;.bs.acelowD:1b];
		.bs.pubMsg["Dealers hand count is now ",(string .bs.dealerCount);key .bs.cp];
		update dealerCnt:.bs.dealerCount from `.bs.tab];
	};

.bs.dealer1:{[p]
	d:first select from .bs.tab where player=p;
	ucnt:d[`cnt];h:d[`handle];nam:d[`name];bet:d[`bet];
	dBust:.bs.dealerCount>21;pBust:ucnt>21;

	if[dBust&not pBust;
		.bs.pubMsg["Dealer busts! Player wins!";h];
		:update return:`float$(bet*2) from `.bs.tab where player=p];
	if[dBust;
		.bs.pubMsg["Dealer busts also, no winner!";h];
		:update return:0f from `.bs.tab where player=p];
	if[pBust;
		.bs.pubMsg["Dealer wins!";h];
		:update return:0f from `.bs.tab where player=p];
	if[.bs.dealerCount=ucnt;
		.bs.pubMsg["Push! ",(string nam)," gets their money back!";h];
		:update return:`float$bet from `.bs.tab where player=p];
	if[.bs.dealerCount>ucnt;
		.bs.pubMsg["Dealer wins!";h];
		:update return:0f from `.bs.tab where player=p];
	if[all(ucnt=21;2=count d[`cards];2<count d[`dealer]);
		.bs.pubMsg[string[.z.u]," get's Blackjack!";h];
		:update return:`float$(((bet*3)%2)+bet) from `.bs.tab where player=p];

	.bs.pubMsg[(string .z.u)," wins";h];
	update return:`float$(bet*2) from `.bs.tab where player=p;
	};

.bs.dealer:{
	if[not .bs.wwch;
		$[0=count select from .bs.tab where out=0b;
			[.bs.pubMsg["Everyone's out!";key .bs.cp];
			 .bs.pubMsg["Dealer wins!";key .bs.cp];
		         update dealer:(dealer,'(last .bs.dc)) from `.bs.tab];
			[.bs.dealer0[];
			 {.bs.dealer1[x];update wait:0b,out:1b from `.bs.tab where player=x} each exec player from .bs.tab where wait=1b]]];

	.bs.lg"Hand stats;";
	show .bs.tab;
	if[.bs.wwch;update dealer:(enlist each dealer) from `.bs.tab];
	upsert[`.bs.res;update "j"$player,profit:return from delete out, wait, turn from .bs.tab];
	update profit:sums return by player from `.bs.res;
	.bs.sumtab:select player,name,cards,cnt,dealer,dealerCnt,bet,return from .bs.tab;
	.bs.sendMsg["Results table for the round;"]each key .bs.cp;
	.bs.sendMsg[.bs.sumtab]each key .bs.cp;
	update player:`int$player from `.bs.tab;
	.bs.bd:0b;.bs.hd:1b;
	.bs.pubMsg["~~~~~~~~~~~~ Game over ~~~~~~~~~~~~~~~";key .bs.cp];
	if[not null .bs.da;.bs.excFunc[`.da.gameover;.bs.res;.bs.da]];
	.bs.start[];
	};
