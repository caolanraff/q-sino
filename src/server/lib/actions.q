.bjk.playOnInsurance:{                                                                             / a player plays while insurance is offered: decline it for them; can they act
  if[.z.w in exec handle from .bjk.tab where null insurance;insure 0];                             / playing on declines insurance
  if[.bjk.hd;:0b];                                                                                 / the dealer's blackjack has ended the hand
  if[.bjk.insuring;                                                                                / others still to answer insurance
    .bjk.sendMsg["Waiting for the other players to answer insurance";.z.w];                        / tell them
    :0b;                                                                                           / refuse
  ];
  :1b;                                                                                             / insurance closed: carry on
 };

.bjk.checks:{                                                                                      / can the caller act now
  if[$[.bjk.insuring;not .bjk.playOnInsurance[];0b];:0b];                                          / insurance is still on offer
  if[.z.w<>first exec handle from .bjk.tab where turn,not out;                                     / not their turn
    .bjk.pubMsg[string[.z.u]," is trying to play ahead of their turn";.z.w];                       / tell them
    :0b;                                                                                           / refuse
  ];
  if[21<first exec cnt from .bjk.tab where turn;                                                   / hand already bust
    m:"Too late, the game's already over. Please wait until next hand ",string .z.u;               / the notice
    .bjk.pubMsg[m;.z.w];                                                                           / tell them
    :0b;                                                                                           / refuse
  ];
  :1b;                                                                                             / they can act
 };

.bjk.promptPlay:{[h]                                                                               / [handle] start the turn clock and prompt the player
  .bjk.turnDeadline:.z.p+.bjk.timeout;                                                             / turn clock
  .bjk.trigger[`.plr.play;h];                                                                      / prompt their play handler
 };

.bjk.giveTurn:{[h]                                                                                 / [handle] give a player the turn
  d:first select name,cards from .bjk.tab where turn;                                              / the hand on turn
  hand:d`cards;                                                                                    / its cards
  .bjk.pubMsg["It's ",string[d`name],"'s turn: ",.bjk.showHand hand;key .bjk.cp];                  / tell the table whose turn, with their hand
  .bjk.sendMsg["You have ",string["j"$.bjk.timeout%0D00:00:01]," seconds per move";h];             / tell them the time per move
  pair:(2=count hand)&1=count distinct .crd.cardDict hand;                                         / two cards of the same value can split
  .bjk.prompt[$[pair;"Hit, stick or split?";"Hit or stick?"];h];                                   / what they can do
  .bjk.promptPlay h;                                                                               / prompt them
 };

.bjk.nextTurn:{                                                                                    / move to the next hand still to play
  p:exec first player from .bjk.tab where not out,not wait;                                        / first hand neither out nor waiting
  update turn:1b from`.bjk.tab where player=p;                                                     / give it the turn
  if[not any exec turn from .bjk.tab;                                                              / nobody left to play
    .bjk.pubMsg["Everyone has played their hand, now it's the dealers turn";key .bjk.cp];          / announce it
    :.bjk.dealer[];                                                                                / dealer's turn
  ];
  h:first exec handle from .bjk.tab where turn;                                                    / handle on turn
  .bjk.giveTurn h;                                                                                 / give them the turn
 };

.bjk.stickHand:{                                                                                   / stick the hand on turn
  update wait:1b,turn:0b from`.bjk.tab where turn;                                                 / wait for the dealer
  .bjk.nextTurn[];                                                                                 / next hand
 };

stick:{                                                                                            / stick on the current hand
  if[not .bjk.checks[];:()];                                                                       / caller can't act
  .bjk.pubMsg[string[.z.u]," has decided to stick";key .bjk.cp];                                   / announce it
  .bjk.stickHand[];                                                                                / stick
 };

.bjk.turnTimer:{                                                                                   / stick a hand once the turn clock runs out
  if[null[.bjk.turnDeadline]|.z.p<.bjk.turnDeadline;:()];                                          / clock not running or not up
  .bjk.turnDeadline:0Np;                                                                           / stop the clock
  if[not any exec turn from .bjk.tab;:()];                                                         / nobody on turn
  n:first exec name from .bjk.tab where turn;                                                      / who's on turn
  .bjk.pubMsg[string[n]," took too long - sticking";key .bjk.cp];                                  / announce it
  .bjk.stickHand[];                                                                                / stick
 };

.bjk.dealTo:{[p]                                                                                   / [player] deal a card to a hand
  c:.bjk.getCard[];                                                                                / draw
  update cards:(cards,'c)from`.bjk.tab where player=p;                                             / add it to the hand
  total:.bjk.handCount first exec cards from .bjk.tab where player=p;                              / new total
  .bjk.pubMsg[string[.z.u]," hits and gets a ",string[c],", count now ",string total;key .bjk.cp]; / announce it
  update cnt:total from`.bjk.tab where player=p;                                                   / record the total
 };

.bjk.hit1:{                                                                                        / carry on after a card: stick on 21, out on bust, else prompt
  d:first select handle,name,cnt,bet from .bjk.tab where turn;                                     / hand on turn
  if[21=d`cnt;                                                                                     / on 21
    .bjk.pubMsg[string[.z.u]," is on 21";key .bjk.cp];                                             / announce it
    :stick[];                                                                                      / stick
  ];
  if[21<d`cnt;                                                                                     / bust
    .bjk.pubMsg[.bjk.result[d`name;d`bet;0f;"bust with ",string d`cnt];key .bjk.cp];               / announce it
    update return:0f,out:1b,turn:0b from`.bjk.tab where turn;                                      / lose the bet, out of play
    :.bjk.nextTurn[];                                                                              / next hand
  ];
  if[.bjk.double;:stick[]];                                                                        / a doubled hand gets one card
  .bjk.prompt["Hit or stick?";d`handle];                                                           / ask for the next play
  .bjk.promptPlay d`handle;                                                                        / prompt them
 };

hit:{                                                                                              / take a card
  if[.bjk.checks[];                                                                                / caller can act
    .bjk.dealTo first exec player from .bjk.tab where turn;                                        / deal to the hand on turn
    .bjk.hit1[];                                                                                   / carry on
  ];
 };

double:{                                                                                           / double the bet and take one card
  if[not .bjk.checks[];:()];                                                                       / caller can't act
  if[2<>first exec count each cards from .bjk.tab where turn;                                      / two cards only
    .bjk.pubMsg["You can't double after getting a third card ",string .z.u;.z.w];                  / tell them
    :();                                                                                           / refuse
  ];
  if[.bjk.available[.z.w]<first exec bet from .bjk.tab where turn;                                 / the double needs as much again
    .bjk.pubMsg["You can't afford to double ",string .z.u;.z.w];                                   / tell them
    :();                                                                                           / refuse
  ];
  .bjk.pubMsg["Bet doubled by ",string .z.u;key .bjk.cp];                                          / announce it
  update bet:bet*2,double:1b from`.bjk.tab where turn;                                             / double the bet
  .bjk.double:1b;                                                                                  / mid-double
  hit[];                                                                                           / one card
  .bjk.double:0b;                                                                                  / double done
 };

insure:{[amt]                                                                                      / [amount] take insurance, 0 to decline
  if[not .bjk.insuring;.bjk.sendMsg["Insurance isn't on offer right now";.z.w];:()];               / insurance not on offer
  if[not .z.w in exec handle from .bjk.tab where null insurance;                                   / no hand waiting on insurance
    .bjk.sendMsg["You've no hand waiting on insurance";.z.w];                                      / tell them
    :();                                                                                           / refuse
  ];
  if[any(null amt;amt<0;amt>0.5*first exec bet from .bjk.tab where handle=.z.w);                   / 0 to half the bet
    .bjk.sendMsg["Insurance is between 0 and half your bet";.z.w];                                 / tell them
    :();                                                                                           / refuse
  ];
  if[amt>.bjk.available .z.w;.bjk.sendMsg["You can't afford that much insurance";.z.w];:()];       / no more than they have left
  m:$[amt=0;" declines insurance";" insures for $",string amt];                                    / their answer
  .bjk.pubMsg[string[.z.u],m;key .bjk.cp];                                                         / announce it
  update insurance:`float$amt from`.bjk.tab where handle=.z.w;                                     / record it
  .bjk.closeInsuranceIfDone[];                                                                     / close insurance if everyone has answered
 };

.bjk.split0:{[p]                                                                                   / [player] split a hand into two rows; returns the new row's player number
  update player:`float$player from`.bjk.tab;                                                       / player numbers to floats, to fit split hands between them
  q:.01+exec max player from .bjk.tab where handle=.z.w;                                           / new hand's number, just after the caller's last
  `.bjk.tab upsert update player:q,turn:0b from select from .bjk.tab where player=p;               / copy the hand
  update cards:1#'cards from`.bjk.tab where player in(p;q);                                        / one card each
  `player xasc`.bjk.tab;                                                                           / keep hands in play order
  :q;                                                                                              / new hand's number
 };

.bjk.stickSplitAces:{[p;q]                                                                         / [player;player] stick both split aces
  .bjk.pubMsg["Split aces get one card each - both hands stick";key .bjk.cp];                      / announce it
  update wait:1b,turn:0b from`.bjk.tab where player in(p;q);                                       / both wait for the dealer
  .bjk.nextTurn[];                                                                                 / next hand
 };

.bjk.refuseSplit:{.bjk.sendMsg[x," ",string .z.u;.z.w];0b};                                        / tell the caller why they can't split, and refuse

.bjk.canSplit:{                                                                                    / can the hand on turn split
  c:first exec cards from .bjk.tab where turn;                                                     / its cards
  if[2<>count c;:.bjk.refuseSplit"You can only split your first two cards"];                       / two cards only
  if[1<count distinct .crd.cardDict c;:.bjk.refuseSplit"You can't split this hand"];               / same value only
  if[.bjk.available[.z.w]<first exec bet from .bjk.tab where turn;                                 / the new hand needs as much again
    :.bjk.refuseSplit"You can't afford to split";                                                  / refuse
  ];
  if[.bjk.rules[`maxSplitHands]<=count select from .bjk.tab where handle=.z.w;                     / already at maxSplitHands hands
    :.bjk.refuseSplit"You can't split more than ",string[.bjk.rules[`maxSplitHands]-1]," times";   / refuse
  ];
  :1b;                                                                                             / they can split
 };

split:{                                                                                            / split the hand on turn
  if[not$[.bjk.checks[];.bjk.canSplit[];0b];:()];                                                  / caller can't act or split
  .bjk.pubMsg[string[.z.u]," is splitting";key .bjk.cp];                                           / announce it
  p:"f"$first exec player from .bjk.tab where turn;                                                / hand on turn
  aces:`A`A~first exec cards from .bjk.tab where player=p;                                         / splitting aces
  update split:1b from`.bjk.tab where player=p;                                                    / mark it split
  q:.bjk.split0 p;                                                                                 / split it
  .bjk.dealTo each p,q;                                                                            / a second card to each
  $[aces;.bjk.stickSplitAces[p;q];.bjk.hit1[]];                                                    / aces stick; otherwise carry on
 };
