stake:{[bet]
  if[1>bet;.bs.sendMsg["Put some money down on the table or move on";.z.w];:()];
  if[not .bs.hd;.bs.sendMsg["Please wait until the current hand is complete";.z.w];:()];
  .bs.lg string[.z.u]," bets $",string bet;
  upsert[`.bs.stake;(.bs.user[];.z.w;bet)];
  .bs.bd:1b;
  .bs.tab:.bs.tab lj .bs.stake;
  if[null .bs.betDeadline;.bs.armBetTimer[]];
  .bs.dealIfReady[];
 };

.bs.armBetTimer:{
  .bs.betDeadline:.z.p+.bs.betTimeout;
  .bs.sendMsg["Betting closes in ",string["j"$.bs.betTimeout%0D00:00:01]," seconds"]each exec handle from .bs.tab where null bet;
 };

.bs.betTimer:{
  if[null[.bs.betDeadline]|.z.p<.bs.betDeadline;:()];
  if[0=count select from .bs.tab where not null bet;.bs.betDeadline:0Np;:()];                      / every bettor has left: dealing now would unseat everyone
  .bs.lg"Betting closed";
  .bs.deal[];
 };

.bs.dealIfReady:{
  if[0=count .bs.tab;:()];
  if[count select from .bs.tab where null bet;:()];
  .bs.lg"All players have placed their bet - time to deal";
  .bs.deal[];
 };

.bs.newRound:{
  .bs.hd:.bs.wwch:0b;
  .bs.rnd+:1;
  update round:.bs.rnd,cnt:0Ni,out:0b,wait:0b,turn:0b,split:0b,double:0b,insurance:0f from`.bs.tab;
 };

.bs.dealUpCard:{
  c:.bs.getCard[];
  .bs.pubMsg["Dealers first card is ",string c;key .bs.cp];
  update dealer:c,dealerCnt:"I"$string .bs.cardDict c from`.bs.tab;
  .bs.dc:enlist c;
 };

.bs.dealHoleCard:{
  .bs.dc,:.bs.getCard[];
  .bs.pubMsg["Dealers second card is dealt face down";key .bs.cp];
 };

.bs.deal0:{
  if[0=count .bs.tab;:.bs.lg"No players at the table"];
  if[78>count .bs.deck;.bs.lg"Deck needs reshuffled";.bs.buildDeck[];.bs.shuffle[]];
  .bs.newRound[];
  .bs.dealCard each select from .bs.tab where 0=count each cards;
  .bs.dealUpCard[];
  .bs.dealCard each select from .bs.tab where 1=count each cards;
  .bs.dealHoleCard[];
  update cnt:.bs.handCount each cards from`.bs.tab;
  if[`A=first .bs.dc;:.bs.offerInsurance[]];
  .bs.settleDeal[];
 };

.bs.settleDeal:{
  if[.bs.isBJ .bs.dc;:.bs.dealerPeek[]];                                                           / dealer peek: a dealer blackjack ends the hand before anyone acts
  .bs.deal1 each exec handle from .bs.tab;
 };

.bs.offerInsurance:{
  .bs.insuring:1b;
  .bs.insureDeadline:.z.p+.bs.betTimeout;
  update insurance:0n from`.bs.tab;
  .bs.pubMsg["Dealer shows an ace - insurance? insure[amount] up to half your bet, or insure[0] to decline";key .bs.cp];
  .bs.trigger[`.mc.insure]each exec handle from .bs.tab;
 };

.bs.closeInsuranceIfDone:{
  if[.bs.insuring&0=count select from .bs.tab where null insurance;.bs.closeInsurance[]];
 };

.bs.insureTimer:{
  if[null[.bs.insureDeadline]|.z.p<.bs.insureDeadline;:()];
  .bs.closeInsurance[];
 };

.bs.closeInsurance:{
  .bs.insuring:0b;
  .bs.insureDeadline:0Np;
  update insurance:0f from`.bs.tab where null insurance;
  .bs.lg"Insurance closed";
  .bs.settleDeal[];
  .bs.startTurns[];
 };

.bs.dealerPeek:{
  .bs.pubMsg["Dealer has blackjack!";key .bs.cp];
  update wait:1b from`.bs.tab;
  .bs.dealer[];
 };

.bs.payNatural:{[h]
  .bs.sendMsg["Winner winner chicken dinner!";h];
  update return:2.5*bet,out:1b,turn:0b from`.bs.tab where handle=h;
  if[all exec out from .bs.tab;
    .bs.hd:.bs.wwch:1b;
    .bs.dealer[];
  ];
 };

.bs.deal1:{[h]
  hand:first exec cards from .bs.tab where handle=h;
  .bs.sendMsg["Your hand is ",","sv string hand;h];
  if[21=first exec cnt from .bs.tab where handle=h;:.bs.payNatural h];                             / the dealer has already peeked, so a natural can't be beaten
  if[(~/).bs.cardDict hand;:.bs.sendMsg["Hit, stick or split?";h]];
  .bs.sendMsg["Hit or stick?";h];
 };

.bs.sitOutUnbet:{
  .bs.sendMsg["No bet placed, please wait until the next hand"]each exec handle from .bs.tab where null bet;
  delete from`.bs.tab where null bet;
 };

.bs.deal:{
  if[not .bs.hd;:.bs.lg"Please finish the previous hand before dealing again"];
  if[not .bs.bd;:.bs.lg"Please place your bets!"];
  .bs.betDeadline:0Np;
  .bs.sitOutUnbet[];
  .bs.deal0[];
  if[not .bs.insuring;.bs.startTurns[]];
 };

.bs.startTurns:{
  if[.bs.hd;:()];
  update turn:1b from`.bs.tab where player=(exec first player from .bs.tab where not out);
  .bs.lg .Q.s .bs.tab;
  .bs.turn:select player,name,cards,cnt,dealer,dealerCnt,bet,return,out,wait,turn from .bs.tab;
  .bs.sendMsg[.bs.turn]each key .bs.cp;
  .bs.trigger[`.mc.play;first exec handle from .bs.tab where turn];
 };

.bs.dealerDraws:{[c]
  n:.bs.handCount c;
  :(n<17)|.bs.hitSoft17&(n=17)&.bs.isSoft c;
 };

.bs.dealerHit:{[s]
  c:.bs.getCard[];
  .bs.pubMsg["Dealers gets a ",string c;key .bs.cp];
  update dealer:(dealer,'c)from`.bs.tab;
  hand:first[s],c;
  total:.bs.handCount hand;
  .bs.pubMsg["Dealers hand count is now ",string total;key .bs.cp];
  update dealerCnt:total from`.bs.tab;
  :(hand;total);
 };

.bs.dealer0:{
  update dealer:(dealer,'last .bs.dc)from`.bs.tab;
  total:.bs.handCount .bs.dc;
  .bs.pubMsg["Dealer has ",(","sv string .bs.dc),", hand count ",string total;key .bs.cp];
  update dealerCnt:total from`.bs.tab;
  .bs.dealerCount:last .bs.dealerHit/[{.bs.dealerDraws first x};(.bs.dc;total)];
 };

.bs.settleHand:{[p;h;msg;ret]
  .bs.pubMsg[msg;h];
  update return:ret from`.bs.tab where player=p;
 };

.bs.dealer1:{[p]
  d:first select from .bs.tab where player=p;
  s:.bs.settleHand[p;d`handle];
  dBJ:.bs.isBJ d`dealer;
  pBJ:not[d`split]&.bs.isBJ d`cards;
  push:"Push! ",string[d`name]," gets their money back!";
  if[d[`cnt]>21;:s["Dealer wins!";0f]];
  if[dBJ&pBJ;:s[push;"f"$d`bet]];
  if[dBJ;:s["Dealer has blackjack, dealer wins!";0f]];
  if[pBJ;:s[string[d`name]," gets Blackjack!";2.5*d`bet]];
  if[.bs.dealerCount>21;:s["Dealer busts! Player wins!";2f*d`bet]];
  if[.bs.dealerCount=d`cnt;:s[push;"f"$d`bet]];
  if[.bs.dealerCount>d`cnt;:s["Dealer wins!";0f]];
  s[string[d`name]," wins";2f*d`bet];
 };

.bs.settleWaiting:{[p]
  .bs.dealer1 p;
  update wait:0b,out:1b from`.bs.tab where player=p;
 };

.bs.resolveHands:{
  if[.bs.wwch;:()];
  if[all exec out from .bs.tab;
    .bs.pubMsg["Everyone's out!";key .bs.cp];
    .bs.pubMsg["Dealer wins!";key .bs.cp];
    :update dealer:(dealer,'last .bs.dc)from`.bs.tab;
  ];
  .bs.dealer0[];
  .bs.settleWaiting each exec player from .bs.tab where wait;
 };

.bs.recordRound:{
  .bs.lg"Hand stats;\n",.Q.s .bs.tab;
  if[.bs.wwch;update dealer:enlist each dealer from`.bs.tab];
  upsert[`.bs.res;update"j"$player,profit:(return-bet)+(-1 2f .bs.isBJ .bs.dc)*0f^insurance from delete out,wait,turn from .bs.tab];
  .bs.sendMsg["Results table for the round;\n",.Q.s select player,name,cards,cnt,dealer,dealerCnt,bet,return from .bs.tab]each key .bs.cp;
 };

.bs.endHand:{
  update player:`int$player from`.bs.tab;
  .bs.bd:0b;
  .bs.hd:1b;
  .bs.stake:0#.bs.stake;
  .bs.pubMsg["~~~~~~~~~~~~ Game over ~~~~~~~~~~~~~~~";key .bs.cp];
  if[not null .bs.da;.bs.excFunc[`.da.gameover;`res`rnd!(.bs.res;.bs.rnd);.bs.da]];
  .bs.start[];
 };

.bs.dealer:{
  .bs.resolveHands[];
  .bs.recordRound[];
  .bs.endHand[];
 };

