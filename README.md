# q-sino
A multiplayer blackjack game in kdb+/q. A server deals the game over IPC,
players connect to it and play by hand or with an automated strategy, and
an optional pitboss process watches the table for card counters.

## Layout
- `src/server/bin/blackjack.q` - the dealer and game engine. Listens on port `5555` by default; loads the rest of the game from `src/server/lib/`.
- `src/server/bin/pitboss.q` - card-counting detection. Connects to the server and listens on port `5556` by default.
- `src/client/bin/player.q` - the player client, for both manual and automated play.
- `src/client/lib/strategy.q` - shared basic-strategy charts, card counting and the auto-play logic used by every strategy.
- `src/client/lib/*.q` (the rest) - one file per strategy (see [Strategies](#strategies)).
- `src/common/` - code every process shares, loaded with `.utl.require"common"`: logging (`.log.info`/`.log.warn`/`.log.error`), card values and the card-counting systems, and console settings.
- `src/*/test/` - qspec specs; `test/run.q` runs them.

## Running
Run everything from the repo root. Start the server first:

```bash
q src/server/bin/blackjack.q                     # port 5555, random shuffle
q src/server/bin/blackjack.q -p 6000 --seed 42   # port 6000, repeatable shuffle
q src/server/bin/blackjack.q --pitboss 1         # the pitboss may eject suspected card counters
```

`-p` (q's own listening-port flag) defaults to `5555`.

Optionally start the pitboss once the server is up:

```bash
q src/server/bin/pitboss.q                                  # port 5556, server on localhost:5555
q src/server/bin/pitboss.q -p 6001 --server localhost:6000
```

Then connect one `player.q` per player, mixing manual and automated players
freely:

```bash
q src/client/bin/player.q                                # manual - you play by hand
q src/client/bin/player.q --player basicCardCounter       # automated - plays 1000 hands, then leaves
q src/client/bin/player.q --player avgPlayer1 --hands 100  # automated - plays 100 hands, then leaves
q src/client/bin/player.q --server otherhost:6000          # a server on another machine or port
```

`--server` is the server's `host:port`, `localhost:5555` by default.

The server deals a new hand as soon as everyone at the table has bet, and
keeps going for as long as players are connected.

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
| `buyin[amount]` | Buy chips (at least $100), between hands. |
| `hist[]` | Results of every hand so far. |

You can also play from a plain `q` session, with
`` h:hopen`:localhost:5555 `` and then `h"stake 10"`, `h"hit[]"` and so on.
You won't get the turn prompts, and the server's pushes print a harmless
error in that session.

These commands are all a player can run on the server: any other query or
code sent to it is refused and logged.

## Table rules
Standard Las Vegas Strip rules:
- Bets are $10 to $500, in whole dollars. Doubling and splitting can take a hand past $500.
- You play with chips, bought in at the table: `player.q` buys $1,000 when it joins (`--buyin` to choose, minimum $100). From a plain `q` session, call `buyin[amount]` before your first bet. You can't bet, double, split or insure for more than your chips, and can top up with `buyin[amount]` between hands. Each bets prompt shows your chips. A player with no chips, or too few to bet, gets 15 seconds to buy some, then is asked to leave the table.
- 6-deck shoe, reshuffled automatically once fewer than 78 cards remain.
- Blackjack pays 3:2; other wins pay 1:1.
- The dealer hits soft 17 and peeks for blackjack. A dealer blackjack ends the hand at once, and beats everything except a player blackjack, which pushes.
- Double on any first two cards, including after a split.
- Split any two cards of equal value (so K,Q splits), up to 4 hands. Split aces get one card each, and a two-card 21 after a split isn't a blackjack.
- Insurance (even money on a blackjack) is offered whenever the dealer shows an ace.
- No surrender.
- Betting closes 15 seconds after the first bet of a round; anyone who hasn't bet sits that hand out.
- You have 15 seconds per move on your turn; a hand that isn't played in time sticks.

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
when it joins. A strategy leaves the table once it's out of chips.

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
The server only does so when it was started with `--pitboss 1`:
the player is told "The pitboss has asked you to leave the table", their hand
is forfeited if one is in play, and they're disconnected. Their username is
then banned for the rest of the server's session: any later connection from
it is told "You've been asked to leave this table" and closed. Without the
flag the server just logs the suspicion. In testing, the four counting strategies
were all flagged within 50 rounds, and the other three never were.

## Tests
```bash
q test/run.q src/common/test src/server/test src/client/test -q
```

No test starts a real server or client: each entry script only opens ports
and connections when it's run directly, so the specs load the files and call
their functions.
