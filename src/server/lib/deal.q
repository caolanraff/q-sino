stake:{[bet]
  if[not type[bet]in -5 -6 -7h;.bjk.sendMsg["Bets are whole dollars";.z.w];:()];
  if[1>bet;.bjk.sendMsg["Put some money down on the table or move on";.z.w];:()];
  if[not .bjk.hd;.bjk.sendMsg["Please wait until the current hand is complete";.z.w];:()];
  .bjk.lg string[.z.u]," bets $",string bet;
  upsert[`.bjk.stake;(.bjk.user[];.z.w;"j"$bet)];
  .bjk.bd:1b;
  .bjk.tab:.bjk.tab lj .bjk.stake;
  if[null .bjk.betDeadline;.bjk.armBetTimer[]];
  .bjk.dealIfReady[];
 };

.bjk.armBetTimer:{
  .bjk.betDeadline:.z.p+.bjk.betTimeout;
  .bjk.sendMsg["Betting closes in ",string["j"$.bjk.betTimeout%0D00:00:01]," seconds"]each exec handle from .bjk.tab where null bet;
 };

.bjk.betTimer:{
  if[null[.bjk.betDeadline]|.z.p<.bjk.betDeadline;:()];
  if[0=count select from .bjk.tab where not null bet;.bjk.betDeadline:0Np;:()];                      / every bettor has left: dealing now would unseat everyone
  .bjk.lg"Betting closed";
  .bjk.deal[];
 };

.bjk.dealIfReady:{
  if[0=count .bjk.tab;:()];
  if[count select from .bjk.tab where null bet;:()];
  .bjk.lg"All players have placed their bet - time to deal";
  .bjk.deal[];
 };

.bjk.newRound:{
  .bjk.hd:.bjk.wwch:0b;
  .bjk.rnd+:1;
  update round:.bjk.rnd,cnt:0Ni,out:0b,wait:0b,turn:0b,split:0b,double:0b,insurance:0f from`.bjk.tab;
 };

.bjk.dealUpCard:{
  c:.bjk.getCard[];
  .bjk.pubMsg["Dealers first card is ",string c;key .bjk.cp];
  update dealer:c,dealerCnt:"I"$string .bjk.cardDict c from`.bjk.tab;
  .bjk.dc:enlist c;
 };

.bjk.dealHoleCard:{
  .bjk.dc,:.bjk.getCard[];
  .bjk.pubMsg["Dealers second card is dealt face down";key .bjk.cp];
 };

.bjk.deal0:{
  if[0=count .bjk.tab;:.bjk.lg"No players at the table"];
  if[78>count .bjk.deck;.bjk.lg"Deck needs reshuffled";.bjk.buildDeck[];.bjk.shuffle[]];
  .bjk.newRound[];
  .bjk.dealCard each select from .bjk.tab where 0=count each cards;
  .bjk.dealUpCard[];
  .bjk.dealCard each select from .bjk.tab where 1=count each cards;
  .bjk.dealHoleCard[];
  update cnt:.bjk.handCount each cards from`.bjk.tab;
  if[`A=first .bjk.dc;:.bjk.offerInsurance[]];
  .bjk.settleDeal[];
 };

.bjk.settleDeal:{
  if[.bjk.isBJ .bjk.dc;:.bjk.dealerPeek[]];                                                           / dealer peek: a dealer blackjack ends the hand before anyone acts
  .bjk.deal1 each exec handle from .bjk.tab;
 };

.bjk.offerInsurance:{
  .bjk.insuring:1b;
  .bjk.insureDeadline:.z.p+.bjk.betTimeout;
  update insurance:0n from`.bjk.tab;
  .bjk.pubMsg["Dealer shows an ace - insurance? insure[amount] up to half your bet, or insure[0] to decline";key .bjk.cp];
  .bjk.trigger[`.plr.insure]each exec handle from .bjk.tab;
 };

.bjk.closeInsuranceIfDone:{
  if[.bjk.insuring&0=count select from .bjk.tab where null insurance;.bjk.closeInsurance[]];
 };

.bjk.insureTimer:{
  if[null[.bjk.insureDeadline]|.z.p<.bjk.insureDeadline;:()];
  .bjk.closeInsurance[];
 };

.bjk.closeInsurance:{
  .bjk.insuring:0b;
  .bjk.insureDeadline:0Np;
  update insurance:0f from`.bjk.tab where null insurance;
  .bjk.lg"Insurance closed";
  .bjk.settleDeal[];
  .bjk.startTurns[];
 };

.bjk.dealerPeek:{
  .bjk.pubMsg["Dealer has blackjack!";key .bjk.cp];
  update wait:1b from`.bjk.tab;
  .bjk.dealer[];
 };

.bjk.payNatural:{[h]
  .bjk.sendMsg["Winner winner chicken dinner!";h];
  update return:2.5*bet,out:1b,turn:0b from`.bjk.tab where handle=h;
  if[all exec out from .bjk.tab;
    .bjk.hd:.bjk.wwch:1b;
    .bjk.dealer[];
  ];
 };

.bjk.deal1:{[h]
  hand:first exec cards from .bjk.tab where handle=h;
  .bjk.sendMsg["Your hand is ",","sv string hand;h];
  if[21=first exec cnt from .bjk.tab where handle=h;:.bjk.payNatural h];                             / the dealer has already peeked, so a natural can't be beaten
  if[(~/).bjk.cardDict hand;:.bjk.sendMsg["Hit, stick or split?";h]];
  .bjk.sendMsg["Hit or stick?";h];
 };

.bjk.sitOutUnbet:{
  .bjk.sendMsg["No bet placed, please wait until the next hand"]each exec handle from .bjk.tab where null bet;
  delete from`.bjk.tab where null bet;
 };

.bjk.deal:{
  if[not .bjk.hd;:.bjk.lg"Please finish the previous hand before dealing again"];
  if[not .bjk.bd;:.bjk.lg"Please place your bets!"];
  .bjk.betDeadline:0Np;
  .bjk.sitOutUnbet[];
  .bjk.deal0[];
  if[not .bjk.insuring;.bjk.startTurns[]];
 };

.bjk.startTurns:{
  if[.bjk.hd;:()];
  update turn:1b from`.bjk.tab where player=(exec first player from .bjk.tab where not out);
  .bjk.lg .Q.s .bjk.tab;
  .bjk.turn:select player,name,cards,cnt,dealer,dealerCnt,bet,return,out,wait,turn from .bjk.tab;
  .bjk.sendMsg[.bjk.turn]each key .bjk.cp;
  .bjk.trigger[`.plr.play;first exec handle from .bjk.tab where turn];
 };

.bjk.dealerDraws:{[c]
  n:.bjk.handCount c;
  :(n<17)|.bjk.hitSoft17&(n=17)&.bjk.isSoft c;
 };

.bjk.dealerHit:{[s]
  c:.bjk.getCard[];
  .bjk.pubMsg["Dealers gets a ",string c;key .bjk.cp];
  update dealer:(dealer,'c)from`.bjk.tab;
  hand:first[s],c;
  total:.bjk.handCount hand;
  .bjk.pubMsg["Dealers hand count is now ",string total;key .bjk.cp];
  update dealerCnt:total from`.bjk.tab;
  :(hand;total);
 };

.bjk.dealer0:{
  update dealer:(dealer,'last .bjk.dc)from`.bjk.tab;
  total:.bjk.handCount .bjk.dc;
  .bjk.pubMsg["Dealer has ",(","sv string .bjk.dc),", hand count ",string total;key .bjk.cp];
  update dealerCnt:total from`.bjk.tab;
  .bjk.dealerCount:last .bjk.dealerHit/[{.bjk.dealerDraws first x};(.bjk.dc;total)];
 };

.bjk.settleHand:{[p;h;msg;ret]
  .bjk.pubMsg[msg;h];
  update return:ret from`.bjk.tab where player=p;
 };

.bjk.dealer1:{[p]
  d:first select from .bjk.tab where player=p;
  s:.bjk.settleHand[p;d`handle];
  dBJ:.bjk.isBJ d`dealer;
  pBJ:not[d`split]&.bjk.isBJ d`cards;
  push:"Push! ",string[d`name]," gets their money back!";
  if[d[`cnt]>21;:s["Dealer wins!";0f]];
  if[dBJ&pBJ;:s[push;"f"$d`bet]];
  if[dBJ;:s["Dealer has blackjack, dealer wins!";0f]];
  if[pBJ;:s[string[d`name]," gets Blackjack!";2.5*d`bet]];
  if[.bjk.dealerCount>21;:s["Dealer busts! Player wins!";2f*d`bet]];
  if[.bjk.dealerCount=d`cnt;:s[push;"f"$d`bet]];
  if[.bjk.dealerCount>d`cnt;:s["Dealer wins!";0f]];
  s[string[d`name]," wins";2f*d`bet];
 };

.bjk.settleWaiting:{[p]
  .bjk.dealer1 p;
  update wait:0b,out:1b from`.bjk.tab where player=p;
 };

.bjk.resolveHands:{
  if[.bjk.wwch;:()];
  if[all exec out from .bjk.tab;
    .bjk.pubMsg["Everyone's out!";key .bjk.cp];
    .bjk.pubMsg["Dealer wins!";key .bjk.cp];
    :update dealer:(dealer,'last .bjk.dc)from`.bjk.tab;
  ];
  .bjk.dealer0[];
  .bjk.settleWaiting each exec player from .bjk.tab where wait;
 };

.bjk.recordRound:{
  .bjk.lg"Hand stats;\n",.Q.s .bjk.tab;
  if[.bjk.wwch;update dealer:enlist each dealer from`.bjk.tab];
  upsert[`.bjk.res;update"j"$player,profit:(return-bet)+(-1 2f .bjk.isBJ .bjk.dc)*0f^insurance from delete out,wait,turn from .bjk.tab];
  .bjk.sendMsg["Results table for the round;\n",.Q.s select player,name,cards,cnt,dealer,dealerCnt,bet,return from .bjk.tab]each key .bjk.cp;
 };

.bjk.endHand:{
  update player:`int$player from`.bjk.tab;
  .bjk.bd:0b;
  .bjk.hd:1b;
  .bjk.stake:0#.bjk.stake;
  .bjk.pubMsg["~~~~~~~~~~~~ Game over ~~~~~~~~~~~~~~~";key .bjk.cp];
  if[not null .bjk.pit;.bjk.excFunc[`.pit.gameover;`res`rnd!(.bjk.res;.bjk.rnd);.bjk.pit]];
  .bjk.start[];
 };

.bjk.dealer:{
  .bjk.resolveHands[];
  .bjk.recordRound[];
  .bjk.endHand[];
 };

