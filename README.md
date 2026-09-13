# q-sino
KDB+ blackjack game

## Scripts
- `src/server/bin/blackjackServer.q` - the dealer/game engine. Listens on port `5555`. Loads shared code from `src/server/lib/`.
- `src/server/bin/detectionAlgo.q` - watches for card-counting behavior. Connects to the server; listens on port `5556`.
- `src/client/bin/masterClient.q` - generic player client. Loads `playerCore.q` and one strategy script from `src/client/lib/`, then connects to the server.
- `src/client/lib/playerCore.q` - shared basic-strategy tables and card-counting helpers used by the strategy scripts.
- `src/client/lib/*.q` (all except `playerCore.q`) - pluggable per-player strategies (see below).

## Usage

Start the server first, from the repo root:

```bash
q src/server/bin/blackjackServer.q -gameplay manual -hands 1000
```

- `-gameplay` - `manual` (players call `stake`/`hit`/`stick`/etc. themselves) or `auto` (the server drives bot clients automatically). Required.
- `-hands` - number of hands to play before stopping. Optional, default `1000`.
- `-seed` - RNG seed for the shuffle. Optional, default derived from the current time.
- `-port` - port to listen on. Optional, default `5555`.

Optionally start the detection process (after the server is up):

```bash
q src/server/bin/detectionAlgo.q
```

- `-port` - port to listen on. Optional, default `5556`.
- `-serverPort` - port of the blackjackServer.q instance to connect to. Optional, default `5555`.

### Running a player

Each player connects with `masterClient.q`, from the repo root (it resolves and loads `playerCore.q` and the chosen strategy from `src/client/lib/` regardless of the caller's working directory):

```bash
q src/client/bin/masterClient.q -player <name>
```

- `-player` - which strategy to play (see table below). Required.
- `-port` - port of the blackjackServer.q instance to connect to. Optional, default `5555`.

Run one `masterClient.q` per player you want at the table - `-player` selects which `src/client/lib/*.q` strategy that client plays:

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
q src/server/bin/blackjackServer.q -gameplay manual -hands 100    # terminal 1
q src/client/bin/masterClient.q -player basicCardCounter          # terminal 2
q src/client/bin/masterClient.q -player avgPlayer1                # terminal 3
```

A human can also join directly with a plain `q` session connected to the server (`` h:hopen`:localhost:5555 ``), calling `stake[bet]`, `hit[]`, `stick[]`, `double[]`, `split[]`, `shuffle[]`, `buildDeck[]`, `hist` on the handle.

## Enhancements
- change globals to use namespace
- create generic functions for bust and 21, as used in deal and hit functions
- use qprof to check speed of functions
- supervised learning (using seed values)
- protected eval function
- detection algo to publish data to websockets
