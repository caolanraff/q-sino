# q-sino
A multiplayer blackjack game in kdb+/q. A server deals the game over IPC,
players connect to it and play by hand or with an automated strategy, and
an optional pitboss process watches the table for card counters.

## Layout
- `src/house/bin/blackjack.q` - the dealer and game engine. Listens on port `5555` by default; loads the rest of the game from `src/house/lib/`.
- `src/house/bin/pitboss.q` - card-counting detection. Connects to the server and listens on port `5556` by default.
- `src/players/bin/player.q` - the player client, for both manual and automated play.
- `src/players/lib/strategy.q` - shared basic-strategy charts, card counting and the auto-play logic used by every strategy.
- `src/players/lib/*.q` (the rest) - one file per strategy (see [Strategies](#strategies)).
- `src/common/` - code every process shares, loaded with `.utl.require"common"`: logging (`.log.info`/`.log.warn`/`.log.error`), card values and the card-counting systems, and console settings.
- `src/*/test/` - qspec specs; `test/run.q` runs them.

## Running
Run everything from the repo root. Start the server first:

```bash
q src/house/bin/blackjack.q                     # port 5555, random shuffle
q src/house/bin/blackjack.q -p 6000 --seed 42   # port 6000, repeatable shuffle
q src/house/bin/blackjack.q --pitboss 1         # the pitboss may eject suspected card counters
```

`-p` (q's own listening-port flag) defaults to `5555`.

Optionally start the pitboss once the server is up:

```bash
q src/house/bin/pitboss.q                                  # port 5556, server on localhost:5555
q src/house/bin/pitboss.q -p 6001 --server localhost:6000
```

Then connect one `player.q` per player, mixing manual and automated players
freely:

```bash
q src/players/bin/player.q                                  # manual - you play by hand
q src/players/bin/player.q --player basicCardCounter        # automated - plays 1000 hands, then leaves
q src/players/bin/player.q --player avgPlayer1 --hands 100  # automated - plays 100 hands, then leaves
q src/players/bin/player.q --server otherhost:6000          # a server on another machine or port
```

`--server` is the server's `host:port`, `localhost:5555` by default.

The server deals a new hand as soon as everyone at the table has bet, and
keeps going for as long as players with chips are at the table.

### Playing by hand
Without `--player`, the client prompts you when it's your turn and you answer
in its console:

| Command | |
|---|---|
| `stake[bet]` | Bet on the next hand: whole dollars, $10 to $500. |
| `hit[]` | Take another card. |
| `stick[]` | Stick with your hand. |
| `double[]` | Double your bet and take exactly one more card (first two cards only). |
| `split[]` | Split a pair into two hands. |
| `insure[amount]` | When the dealer shows an ace: insure for up to half your bet, or `insure[0]` to decline. |
| `buyin[amount]` | Buy chips (at least $100). Your first buy-in deals you in; top-ups are between hands. |
| `hist[]` | Results of every hand so far. |

You can also play from a plain `q` session, with
`` h:hopen`:localhost:5555 ``, then `h"buyin 1000"` to buy chips, then
`h"stake 10"`, `h"hit[]"` and so on.
You won't get the turn prompts, and the server's pushes print a harmless
error in that session.

These commands are all a player can run on the server: any other query or
code sent to it is refused and logged.

### Example game
Two players at one table: `alice` playing by hand, and `bob` counting cards
for 3 hands. You play under your login name unless `--server` ends with one:

```bash
q src/house/bin/blackjack.q --seed 42
q src/players/bin/player.q --server localhost:5555:alice
q src/players/bin/player.q --server localhost:5555:bob --player basicCardCounter --hands 3
```

Alice's console, with what she types after `q)`. Each seat is shown as
`<name>_<handle>`:

```
  You have $1000.00 in chips, please use buyin[amount] if you want more
Please place your bets via the stake[] function, $10 to $500; your chips: $1000.00
  Betting closes in 30 seconds
q)stake[20]
~~~~~~~~~~~~ Hand 1 ~~~~~~~~~~~~
  Your card is 2
  Dealer's first card is J
  Your card is 6
  Dealer's second card is dealt face down
  Your hand is 2,6 (8)
  It's alice_7's turn: 2,6 (8)
  You have 30 seconds per move
Hit or stick?
q)hit[]
  alice hits and gets a 4, count now 12
Hit or stick?
q)stick[]
  alice has decided to stick
  It's bob_8's turn: 6,4 (10)
  bob hits and gets an A, count now 21
  bob is on 21
  bob has decided to stick
  Everyone has played their hand, now it's the dealer's turn
  Dealer has J,Q, hand count 20
  alice_7 loses $20.00 (12 against the dealer's 20)
  bob_8 wins $10.00 (21 against the dealer's 20)
~~~~~~~~~~~~ Game over ~~~~~~~~~~~~
```

Bob's client plays its hands itself, doubling on soft 18 against a 5 and on
11 against a 10, then leaves:

```
~~~~~~~~~~~~ Hand 3 ~~~~~~~~~~~~
  Your card is 9
  Dealer's first card is 10
  Your card is 2
  Dealer's second card is dealt face down
  Your hand is 9,2 (11)
  It's bob_8's turn: 9,2 (11)
  You have 30 seconds per move
Hit or stick?
  Bet doubled by bob
  bob hits and gets a 9, count now 20
  bob has decided to stick
  Everyone has played their hand, now it's the dealer's turn
  Dealer has 10,3, hand count 13
  Dealer gets an A
  Dealer's hand count is now 14
  Dealer gets a 9
  Dealer's hand count is now 23
  bob_8 wins $20.00 (the dealer busts with 23)
~~~~~~~~~~~~ Game over ~~~~~~~~~~~~

Please place your bets via the stake[] function, $10 to $500; your chips: $1050.00
Played 3 hands
Thanks for playing q-sino blackjack! You leave with $1050.00 in chips, up $50.00
```

The server logs every bet, card and result, with the table after each hand:

```
2026.10.03 03:09:12.336635000 INFO alice joins the table with $1000 in chips
2026.10.03 03:09:13.385114000 INFO bob joins the table with $1000 in chips
2026.10.03 03:09:13.385732000 INFO bob bets $10
2026.10.03 03:09:15.190146000 INFO alice bets $20
2026.10.03 03:09:15.190403000 INFO All players have placed their bet - time to deal
...
2026.10.03 03:09:19.217234000 INFO Hand stats:
round player name    handle uid                                  cards cnt dealer dealerCnt bet return profit split double insurance forced out wait turn
---------------------------------------------------------------------------------------------------------------------------------------------------------
1     1      alice_7 7      3f9c2a1e-8b7d-4c6a-9e2f-1a2b3c4d5e6f 2 6 4 12  J Q    20        20  0             0     0      0         0      1   0    0
1     2      bob_8   8      a4d1e7b2-5c3f-4e8a-b6d9-0f1e2d3c4b5a 6 4 A 21  J Q    20        10  20            0     0      0         0      1   0    0
...
2026.10.03 03:09:22.225730000 INFO alice_7 has left the table, net winnings this session -$20.00, leaving with $980.00 in chips
```

## Table rules
Standard Las Vegas Strip rules:
- Bets are $10 to $500, in whole dollars. Doubling and splitting can take a hand past $500.
- You play with chips, bought in at the table: `player.q` buys $1,000 when it joins (`--buyin` to choose, minimum $100). From a plain `q` session, call `buyin[amount]` to be dealt in: you're only seated, and asked to bet, once you've bought chips. You can't bet, double, split or insure for more than your chips, and can top up with `buyin[amount]` between hands. Each bets prompt shows your chips. A player with no chips, or too few to bet, gets 30 seconds to buy some, then is asked to leave the table.
- 6-deck shoe, reshuffled automatically once fewer than 78 cards remain.
- Blackjack pays 3:2; other wins pay 1:1.
- The dealer hits soft 17 and peeks for blackjack. A dealer blackjack ends the hand at once, and beats everything except a player blackjack, which pushes.
- Double on any first two cards, including after a split.
- Split any two cards of equal value (so K,Q splits), up to 4 hands. Split aces get one card each, and a two-card 21 after a split isn't a blackjack.
- Insurance (even money on a blackjack) is offered whenever the dealer shows an ace. Playing your hand without answering declines it.
- No surrender.
- Betting closes 30 seconds after the first bet of a round; anyone who hasn't bet sits that hand out.
- You have 30 seconds per move on your turn; a hand that isn't played in time sticks.

## Strategies
Pass one of these to `--player`:

| Strategy | Play | Betting |
|---|---|---|
| `avgPlayer1` | Hits below 17 | Flat $20. |
| `avgPlayer2` | Hits below 17 | Bets the previous hand's profit, or $10 if it didn't win. |
| `avgPlayer3` | Hits below 17 | $20 after every 5th round, $10 otherwise. |
| `basicCardCounter` | Basic strategy | $10-$80 on the Hi-Lo true count; insures at a true count of 3+. |
| `smallSpreadBasicCardCounter` | Basic strategy | Like `basicCardCounter`, but $10-$30. |
| `omegaCardCounter` | Basic strategy | $10-$80 on the Omega II true count. |
| `perfectCardCounter` | Basic strategy | $10-$80 on a level-9 "perfect" count. |

`--hands` (default `1000`) sets how many hands the client plays before it
disconnects, and `--buyin` (default `1000`) how many dollars of chips it buys
when it joins. A strategy leaves the table once it's out of chips. However a player
leaves, the client says what they leave with and their return, e.g. "Thanks
for playing q-sino blackjack! You leave with $990.00 in chips, down $10.00".

## Pitboss
The pitboss records every hand and looks for two signs of counting:
- **Bets that follow the count** - per player and round, the correlation and
  covariance of their bets against the Hi-Lo, Omega II and perfect counts,
  in `.pit.betTrend`.
- **Plays basic strategy wouldn't make** - doubling 18-20, splitting tens,
  sticking on 15/16 against a strong dealer card, and taking insurance, each
  with the count it was made at, in `.pit.double`, `.pit.split`,
  `.pit.stick` and `.pit.insure`.

Query them on its port from another `q` session:

```q
h:hopen 5556
h".pit.betTrend"
h".pit.chart[]"     / suspicion scores over time, ready to chart
```

`.pit.chart[]` gives one row per round, keyed by the `time` it was played, with
a column per player and count (e.g. `alice_8_perfect`) holding that player's
score: how closely their last 100 bets followed that count, from -1 to 1. An
`alert` column holds the suspicion threshold (0.5) to draw as a line.

A player becomes a **suspected card counter** once any of these signs has
held for 5 rounds in a row (one round over the line can be chance):
- **Bets follow the count** - over their last 100 hands (at least 20), their
  bets correlate with one of the three counts at 0.5 or more.
- **Bets jump when the count is good** - their average bet at a Hi-Lo true
  count of +2 or more is at least 1.5 times their average at 0 or below, with
  at least 5 hands at each. This still sees a counter who jumps their bet in
  steps or adds random bets as cover, which weakens the correlation.
- **Insurance only at a high count** - they've insured at least twice, only
  ever at a Hi-Lo true count of +3 or more. Basic strategy never insures, so
  this catches a counter who flat-bets.

The pitboss then logs a warning and asks the server to eject them.
It tracks each connection by an id the server gives it, not by name or
handle, so a player who leaves and a newcomer the server gives the same handle
(and so the same name) are never confused. It can start at any point in a
shoe: the first results it receives cover the shoe so far, and it scores
every round in them.
The server only does so when it was started with `--pitboss 1`:
the player is told "The pitboss has asked you to leave the table", their hand
is forfeited if one is in play, and they're disconnected. Their username is
then banned for the rest of the server's session: any later connection from
it is told "You've been asked to leave this table" and closed. Without the
flag the server just logs the suspicion. In testing, the four counting strategies
were all flagged within 50 rounds, and the other three never were.

## Tests
```bash
q test/run.q src/common/test src/house/test src/players/test -q
```

No test starts a real server or client: each entry script only opens ports
and connections when it's run directly, so the specs load the files and call
their functions.

## License

[MIT](LICENSE). The vendored code under `vendor/` keeps its own licenses.
