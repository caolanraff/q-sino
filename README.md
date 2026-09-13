# q-sino
KDB+ blackjack game

## Scripts
- `src/server/blackjackServer.q` - the dealer/game engine. Listens on port `5555`.
- `src/server/detectionAlgo.q` - watches for card-counting behavior. Connects to the server; listens on port `5556`.
- `src/client/masterClient.q` - generic player client. Loads `playerCore.q` and one `players/*.q` strategy, then connects to the server.
- `src/client/playerCore.q` - shared basic-strategy tables and card-counting helpers used by the strategy scripts.
- `src/client/players/*.q` - pluggable per-player strategies (see below).

## Usage

Start the server first, from the repo root:

```bash
q src/server/blackjackServer.q -gameplay manual -hands 1000
```

- `-gameplay` - `manual` (players call `stake`/`hit`/`stick`/etc. themselves) or `auto` (the server drives bot clients automatically). Required.
- `-hands` - number of hands to play before stopping. Optional, default `1000`.
- `-seed` - RNG seed for the shuffle. Optional, default derived from the current time.

Optionally start the detection process (after the server is up):

```bash
q src/server/detectionAlgo.q
```

### Running a player

Each player connects with `masterClient.q`, from `src/client/` (it loads `playerCore.q` and the chosen strategy via a relative path):

```bash
cd src/client
q masterClient.q -player <name>
```

Run one `masterClient.q` per player you want at the table - `-player` selects which `players/*.q` strategy that client plays:

| `-player` value | Strategy |
|---|---|
| `avgPlayer1` | Basic hit-below-17 play; flat $20 bet every hand. |
| `avgPlayer2` | Basic hit-below-17 play; bets the previous hand's profit (falls back to $10). |
| `avgPlayer3` | Basic hit-below-17 play; bets $20 on every 5th hand, $10 otherwise. |
| `basicCardCounter` | Full basic-strategy play; sizes bets off the Hi-Lo ("basic") running count. |
| `smallSpreadBasicCardCounter` | Same as `basicCardCounter`, but with a smaller bet spread (less swingy bets). |
| `omegaCardCounter` | Full basic-strategy play; sizes bets off the Omega II running count. |
| `perfectCardCounter` | Full basic-strategy play; sizes bets off a "perfect" (level-9) running count. |

For example, a manual 2-player game:

```bash
q src/server/blackjackServer.q -gameplay manual -hands 100    # terminal 1
cd src/client && q masterClient.q -player basicCardCounter    # terminal 2
cd src/client && q masterClient.q -player avgPlayer1          # terminal 3
```

A human can also join directly with a plain `q` session connected to the server (`` h:hopen`:localhost:5555 ``), calling `stake[bet]`, `hit[]`, `stick[]`, `double[]`, `split[]`, `shuffle[]`, `buildDeck[]`, `hist` on the handle.

## Enhancements
- change globals to use namespace
- create generic functions for bust and 21, as used in deal and hit functions
- use qprof to check speed of functions
- supervised learning (using seed values)
- protected eval function
- detection algo to publish data to websockets
