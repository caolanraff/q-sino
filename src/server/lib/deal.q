.bjk.limits:{"$",string[.bjk.rules`minBet]," to $",string .bjk.rules`maxBet};                      / bet limits as text

stake:{[bet]                                                                                       / [bet] place a bet for the next hand
  if[not type[bet]in -5 -6 -7h;.bjk.sendMsg["Bets are whole dollars";.z.w];:()];                   / whole dollars only
  if[not bet within .bjk.rules`minBet`maxBet;.bjk.sendMsg["Bets are ",.bjk.limits[];.z.w];:()];    / within the table limits
  if[not .bjk.hd;.bjk.sendMsg["Please wait until the current hand is complete";.z.w];:()];         / not mid-hand
  .log.info string[.z.u]," bets $",string bet;
  upsert[`.bjk.stake;(.bjk.user[];.z.w;"j"$bet)];                                                  / record the bet
  .bjk.bd:1b;                                                                                      / a bet is in
  .bjk.tab:.bjk.tab lj .bjk.stake;                                                                 / attach bets to the table
  if[null .bjk.betDeadline;.bjk.armBetTimer[]];                                                    / first bet starts the betting clock
  .bjk.dealIfReady[];                                                                              / deal if everyone has bet
 };

.bjk.armBetTimer:{                                                                                 / start the betting clock
  .bjk.betDeadline:.z.p+.bjk.timeout;                                                              / betting closes after .bjk.timeout
  m:"Betting closes in ",string["j"$.bjk.timeout%0D00:00:01]," seconds";                           / the warning
  .bjk.sendMsg[m]each exec handle from .bjk.tab where null bet;                                    / warn anyone without a bet
 };

.bjk.betTimer:{                                                                                    / close betting once the clock runs out
  if[null[.bjk.betDeadline]|.z.p<.bjk.betDeadline;:()];                                            / clock not running or not up
  if[0=count select from .bjk.tab where not null bet;.bjk.betDeadline:0Np;:()];                    / every bettor has left: dealing now would unseat everyone
  .log.info"Betting closed";
  .bjk.deal[];                                                                                     / deal to those who bet
 };

.bjk.dealIfReady:{                                                                                 / deal once everyone seated has bet
  if[0=count .bjk.tab;:()];                                                                        / nobody seated
  if[count select from .bjk.tab where null bet;:()];                                               / someone still to bet
  .log.info"All players have placed their bet - time to deal";
  .bjk.deal[];                                                                                     / deal
 };

.bjk.newRound:{                                                                                    / start a new round
  .bjk.hd:.bjk.wwch:0b;                                                                            / hand in progress; dealer still to play
  .bjk.rnd+:1;                                                                                     / next round number
  update round:.bjk.rnd,cnt:0Ni,out:0b,wait:0b,turn:0b,split:0b,double:0b,insurance:0f             / reset every hand's state
    from`.bjk.tab;
 };

.bjk.dealUpCard:{                                                                                  / deal the dealer's up-card
  c:.bjk.getCard[];                                                                                / draw
  .bjk.pubMsg["Dealers first card is ",string c;key .bjk.cp];                                      / announce it
  update dealer:c,dealerCnt:"I"$string .crd.cardDict c from`.bjk.tab;                              / show it on every hand
  .bjk.dc:enlist c;                                                                                / start the dealer's hand
 };

.bjk.dealHoleCard:{                                                                                / deal the dealer's hole card
  .bjk.dc,:.bjk.getCard[];                                                                         / add it to the dealer's hand
  .bjk.pubMsg["Dealers second card is dealt face down";key .bjk.cp];                               / announce it, face down
 };

.bjk.deal0:{                                                                                       / deal the opening cards
  if[0=count .bjk.tab;:.log.info"No players at the table"];                                        / nobody to deal to
  if[78>count .bjk.deck;.log.info"Deck needs reshuffled";.bjk.buildDeck[];.bjk.shuffle[]];         / reshuffle when under 78 cards
  .bjk.newRound[];                                                                                 / new round
  .bjk.dealCard each select from .bjk.tab where 0=count each cards;                                / each player's first card
  .bjk.dealUpCard[];                                                                               / dealer's up-card
  .bjk.dealCard each select from .bjk.tab where 1=count each cards;                                / each player's second card
  .bjk.dealHoleCard[];                                                                             / dealer's hole card
  update cnt:.bjk.handCount each cards from`.bjk.tab;                                              / score every hand
  if[`A=first .bjk.dc;:.bjk.offerInsurance[]];                                                     / offer insurance against an ace
  .bjk.settleDeal[];                                                                               / peek, or show each hand
 };

.bjk.settleDeal:{                                                                                  / peek for a dealer blackjack, else show each hand
  if[.bjk.isBJ .bjk.dc;:.bjk.dealerPeek[]];                                                        / a dealer blackjack ends the hand before anyone acts
  .bjk.deal1 each exec handle from .bjk.tab;                                                       / show each player their hand
 };

.bjk.offerInsurance:{                                                                              / open the insurance window
  .bjk.insuring:1b;                                                                                / window open
  .bjk.insureDeadline:.z.p+.bjk.timeout;                                                           / insurance clock
  update insurance:0n from`.bjk.tab;                                                               / nobody has answered yet
  m:"Dealer shows an ace - insurance? insure[amount] up to half your bet, ";                       / the offer
  m,:"or insure[0] to decline";                                                                    / and how to decline
  .bjk.pubMsg[m;key .bjk.cp];                                                                      / ask everyone
  .bjk.trigger[`.plr.insure]each exec handle from .bjk.tab;                                        / prompt their insurance handlers
 };

.bjk.closeInsuranceIfDone:{                                                                        / close insurance once everyone has answered
  if[.bjk.insuring&0=count select from .bjk.tab where null insurance;.bjk.closeInsurance[]];       / open and nobody left to answer
 };

.bjk.insureTimer:{                                                                                 / close insurance once the clock runs out
  if[null[.bjk.insureDeadline]|.z.p<.bjk.insureDeadline;:()];                                      / clock not running or not up
  .bjk.closeInsurance[];                                                                           / close it
 };

.bjk.closeInsurance:{                                                                              / close the insurance window and carry on
  .bjk.insuring:0b;                                                                                / window closed
  .bjk.insureDeadline:0Np;                                                                         / stop the clock
  update insurance:0f from`.bjk.tab where null insurance;                                          / no answer is a decline
  .log.info"Insurance closed";
  .bjk.settleDeal[];                                                                               / peek, or show each hand
  .bjk.startTurns[];                                                                               / start play
 };

.bjk.dealerPeek:{                                                                                  / dealer blackjack: end the hand
  .bjk.pubMsg["Dealer has blackjack!";key .bjk.cp];                                                / announce it
  update wait:1b from`.bjk.tab;                                                                    / every hand waits to be settled
  .bjk.dealer[];                                                                                   / settle the hand
 };

.bjk.payNatural:{[h]                                                                               / [handle] pay a player's natural 3:2
  .bjk.sendMsg["Winner winner chicken dinner!";h];                                                 / tell them
  update return:2.5*bet,out:1b,turn:0b from`.bjk.tab where handle=h;                               / pay out and take the hand out of play
  if[all exec out from .bjk.tab;                                                                   / every hand was a natural
    .bjk.hd:.bjk.wwch:1b;                                                                          / hand over; the dealer doesn't play
    .bjk.dealer[];                                                                                 / settle the hand
  ];
 };

.bjk.deal1:{[h]                                                                                    / [handle] show a player their hand and options
  hand:first exec cards from .bjk.tab where handle=h;                                              / their cards
  .bjk.sendMsg["Your hand is ",","sv string hand;h];                                               / show them
  if[21=first exec cnt from .bjk.tab where handle=h;:.bjk.payNatural h];                           / the dealer has already peeked, so a natural can't be beaten
  if[(~/).crd.cardDict hand;:.bjk.sendMsg["Hit, stick or split?";h]];                              / a pair can split
  .bjk.sendMsg["Hit or stick?";h];                                                                 / otherwise hit or stick
 };

.bjk.sitOutUnbet:{                                                                                 / sit out anyone without a bet
  m:"No bet placed, please wait until the next hand";                                              / the notice
  .bjk.sendMsg[m]each exec handle from .bjk.tab where null bet;                                    / tell them
  delete from`.bjk.tab where null bet;                                                             / take them off the table
 };

.bjk.deal:{                                                                                        / deal a hand to everyone who bet
  if[not .bjk.hd;:.log.info"Please finish the previous hand before dealing again"];                / a hand is in progress
  if[not .bjk.bd;:.log.info"Please place your bets!"];                                             / nobody has bet
  .bjk.betDeadline:0Np;                                                                            / stop the betting clock
  .bjk.sitOutUnbet[];                                                                              / sit out the rest
  .bjk.deal0[];                                                                                    / deal the opening cards
  if[not .bjk.insuring;.bjk.startTurns[]];                                                         / start play unless insurance is open
 };

.bjk.startTurns:{                                                                                  / give the first player still in their turn
  if[.bjk.hd;:()];                                                                                 / hand already over
  update turn:1b from`.bjk.tab where player=(exec first player from .bjk.tab where not out);       / first player still in
  .log.info .bjk.tab;
  .bjk.turn:select player,name,cards,cnt,dealer,dealerCnt,bet,return,out,wait,turn from .bjk.tab;  / the table as players see it
  .bjk.sendMsg[.bjk.turn]each key .bjk.cp;                                                         / show everyone
  .bjk.giveTurn first exec handle from .bjk.tab where turn;                                        / start their turn
 };

.bjk.dealerDraws:{[c]                                                                              / [cards] does the dealer draw on this hand
  n:.bjk.handCount c;                                                                              / hand total
  :(n<17)|.bjk.hitSoft17&(n=17)&.bjk.isSoft c;                                                     / under 17, or soft 17 when hitting soft 17
 };

.bjk.dealerHit:{[s]                                                                                / [state] draw one dealer card; state is (cards;total)
  c:.bjk.getCard[];                                                                                / draw
  .bjk.pubMsg["Dealers gets a ",string c;key .bjk.cp];                                             / announce it
  update dealer:(dealer,'c)from`.bjk.tab;                                                          / add it to every row's dealer hand
  hand:first[s],c;                                                                                 / dealer's new hand
  total:.bjk.handCount hand;                                                                       / its total
  .bjk.pubMsg["Dealers hand count is now ",string total;key .bjk.cp];                              / announce it
  update dealerCnt:total from`.bjk.tab;                                                            / show it on every hand
  :(hand;total);                                                                                   / new state
 };

.bjk.dealer0:{                                                                                     / play the dealer's hand
  update dealer:(dealer,'last .bjk.dc)from`.bjk.tab;                                               / reveal the hole card on every hand
  total:.bjk.handCount .bjk.dc;                                                                    / dealer's total
  .bjk.pubMsg["Dealer has ",(","sv string .bjk.dc),", hand count ",string total;key .bjk.cp];      / announce the hand
  update dealerCnt:total from`.bjk.tab;                                                            / show it on every hand
  .bjk.dealerCount:last .bjk.dealerHit/[{.bjk.dealerDraws first x};(.bjk.dc;total)];               / draw until the dealer stands; keep the final total
 };

.bjk.settleHand:{[p;h;msg;ret]                                                                     / [player;handle;message;return] announce a hand's result and record its return
  .bjk.pubMsg[msg;h];                                                                              / announce it
  update return:ret from`.bjk.tab where player=p;                                                  / record the return
 };

.bjk.dealer1:{[p]                                                                                  / [player] settle a hand against the dealer
  d:first select from .bjk.tab where player=p;                                                     / the hand
  s:.bjk.settleHand[p;d`handle];                                                                   / settle it with a message and return
  dBJ:.bjk.isBJ d`dealer;                                                                          / dealer blackjack
  pBJ:not[d`split]&.bjk.isBJ d`cards;                                                              / player blackjack; not on a split hand
  push:"Push! ",string[d`name]," gets their money back!";                                          / push message
  if[d[`cnt]>21;:s["Dealer wins!";0f]];                                                            / player bust
  if[dBJ&pBJ;:s[push;"f"$d`bet]];                                                                  / both blackjack: push
  if[dBJ;:s["Dealer has blackjack, dealer wins!";0f]];                                             / dealer blackjack
  if[pBJ;:s[string[d`name]," gets Blackjack!";2.5*d`bet]];                                         / player blackjack pays 3:2
  if[.bjk.dealerCount>21;:s["Dealer busts! Player wins!";2f*d`bet]];                               / dealer bust
  if[.bjk.dealerCount=d`cnt;:s[push;"f"$d`bet]];                                                   / same total: push
  if[.bjk.dealerCount>d`cnt;:s["Dealer wins!";0f]];                                                / dealer higher
  s[string[d`name]," wins";2f*d`bet];                                                              / player higher
 };

.bjk.settleWaiting:{[p]                                                                            / [player] settle a waiting hand and take it out of play
  .bjk.dealer1 p;                                                                                  / settle it
  update wait:0b,out:1b from`.bjk.tab where player=p;                                              / out of play
 };

.bjk.resolveHands:{                                                                                / play the dealer and settle every waiting hand
  if[.bjk.wwch;:()];                                                                               / every hand was a natural, already paid
  if[all exec out from .bjk.tab;                                                                   / every hand is out of play: bust or already paid
    .bjk.pubMsg["Everyone's out!";key .bjk.cp];                                                    / announce it
    .bjk.pubMsg["Dealer wins!";key .bjk.cp];                                                       / dealer wins
    :update dealer:(dealer,'last .bjk.dc)from`.bjk.tab;                                            / reveal the hole card and stop
  ];
  .bjk.dealer0[];                                                                                  / play the dealer's hand
  .bjk.settleWaiting each exec player from .bjk.tab where wait;                                    / settle each waiting hand
 };

.bjk.recordRound:{                                                                                 / record the round's results
  .log.info"Hand stats;\n",.Q.s .bjk.tab;
  if[.bjk.wwch;update dealer:enlist each dealer from`.bjk.tab];                                    / dealer has only the up-card: make it a list
  r:delete out,wait,turn from .bjk.tab;                                                            / the round's hands, without the turn state
  r:update"j"$player,profit:(return-bet)+(-1 2f .bjk.isBJ .bjk.dc)*0f^insurance from r;            / profit; insurance pays 2:1 on a dealer blackjack, else is lost
  `.bjk.res upsert r;                                                                              / add to results
  t:select player,name,cards,cnt,dealer,dealerCnt,bet,return from .bjk.tab;                        / the results as players see them
  .bjk.sendMsg["Results table for the round;\n",.Q.s t]each key .bjk.cp;                           / show everyone the results
 };

.bjk.endHand:{                                                                                     / end the hand and start the next round
  update player:`int$player from`.bjk.tab;                                                         / player numbers back to ints
  .bjk.bd:0b;                                                                                      / no bets in
  .bjk.hd:1b;                                                                                      / no hand in progress
  .bjk.stake:0#.bjk.stake;                                                                         / clear bets
  .bjk.pubMsg["~~~~~~~~~~~~ Game over ~~~~~~~~~~~~~~~";key .bjk.cp];                               / announce it
  if[not null .bjk.pit;.bjk.excFunc[`.pit.gameover;`res`rnd!(.bjk.res;.bjk.rnd);.bjk.pit]];        / send the pitboss the results
  .bjk.start[];                                                                                    / next round
 };

.bjk.dealer:{                                                                                      / finish the hand: dealer plays, results recorded
  .bjk.turnDeadline:0Np;                                                                           / stop the turn clock
  .bjk.resolveHands[];                                                                             / play the dealer and settle hands
  .bjk.recordRound[];                                                                              / record results
  .bjk.endHand[];                                                                                  / end the hand
 };

