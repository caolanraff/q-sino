# q-sino
KDB+ blackjack game

## Scripts
- `src/server/bin/blackjackServer.q` - the dealer/game engine. Listens on port `5555`. Loads shared code from `src/server/lib/`.
- `src/server/bin/detectionAlgo.q` - watches for card-counting behavior. Connects to the server; listens on port `5556`.
- `src/client/bin/masterClient.q` - generic player client, one script for both modes. With `-player <name>` it loads `playerCore.q` and that strategy and plays automatically; without it, it connects with just its own log-only prompts and you play manually (see below).
- `src/client/lib/playerCore.q` - shared basic-strategy tables, card-counting helpers, and the real auto-play logic used by the strategy scripts; only loaded when `-player` is given.
- `src/client/lib/*.q` (all except `playerCore.q`) - pluggable per-player strategies (see below).

## Usage

Start the server first, from the repo root:

```bash
q src/server/bin/blackjackServer.q -hands 1000
```

The server has no notion of "gameplay mode" - it just deals the game and
exposes `stake`/`hit`/`stick`/`double`/`split`/`shuffle` to every connection
the same way. It also unconditionally pushes `.mc.stake`/`.mc.play`/
`.mc.shuffle` to every connected handle at the relevant point in play.
`masterClient.q` defines those three names itself, as simple log-only
prompts ("it's your turn - run ... when ready"); loading a strategy via
`-player <name>` pulls in `playerCore.q`, which redefines the same three
names with the real auto-play logic, so a bot reacts to the pushes
automatically instead.

- `-hands` - number of hands to play before stopping. Optional, default `1000`.
- `-seed` - RNG seed for the shuffle. Optional, default derived from the current time.

Optionally start the detection process (after the server is up):

```bash
q src/server/bin/detectionAlgo.q
```

### Running a player

Each player connects with `masterClient.q`, from the repo root:

```bash
q src/client/bin/masterClient.q               # manual - play by hand, prompted each turn
q src/client/bin/masterClient.q -player <name> # auto - <name> plays every hand for you
```

**Manual mode** (no `-player`): connects without touching `playerCore.q` or
any strategy file, so you get `masterClient.q`'s own log-only prompt each
time it's your turn (`It's your turn to stake - run stake[bet] when ready`,
etc.) instead of auto-playing. You then call `stake[bet]`, `hit[]`,
`stick[]`, `double[]`, `split[]`, `shuffle[]`, `buildDeck[]`, `hist[]` on
the handle yourself, whenever you're ready.

**Auto mode** (`-player <name>`): additionally loads that strategy from
`src/client/lib/` and plays every hand automatically:

| `-player` value | Strategy |
|---|---|
| `avgPlayer1` | Basic hit-below-17 play; flat $20 bet every hand. |
| `avgPlayer2` | Basic hit-below-17 play; bets the previous hand's profit (falls back to $10). |
| `avgPlayer3` | Basic hit-below-17 play; bets $20 on every 5th hand, $10 otherwise. |
| `basicCardCounter` | Full basic-strategy play; sizes bets off the Hi-Lo ("basic") running count. |
| `smallSpreadBasicCardCounter` | Same as `basicCardCounter`, but with a smaller bet spread (less swingy bets). |
| `omegaCardCounter` | Full basic-strategy play; sizes bets off the Omega II running count. |
| `perfectCardCounter` | Full basic-strategy play; sizes bets off a "perfect" (level-9) running count. |

Run one `masterClient.q` per player you want at the table, mixing manual and
auto freely - for example:

```bash
q src/server/bin/blackjackServer.q -hands 100                     # terminal 1
q src/client/bin/masterClient.q                                   # terminal 2 (manual)
q src/client/bin/masterClient.q -player avgPlayer1                # terminal 3 (auto)
```

A human can also join directly with a plain `q` session connected to the
server (`` h:hopen`:localhost:5555 ``) instead of running `masterClient.q` -
same manual commands, but without the friendly prompts (the server's
pushes just print a harmless error to the session's own console, since
`.mc.stake`/`.mc.play`/`.mc.shuffle` are undefined there).

## Enhancements
- change globals to use namespace
- create generic functions for bust and 21, as used in deal and hit functions
- use qprof to check speed of functions
- supervised learning (using seed values)
- protected eval function
- detection algo to publish data to websockets
