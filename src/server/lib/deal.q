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
