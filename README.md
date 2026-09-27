# q-sino
KDB+ blackjack game

## Scripts
- `src/server/bin/blackjack.q` - the dealer/game engine. Listens on port `5555`. Loads shared code from `src/server/lib/`.
- `src/server/bin/pitboss.q` - watches for card-counting behavior. Connects to the server; listens on port `5556`.
- `src/client/bin/player.q` - generic player client, one script for both modes. With `-player <name>` it loads that strategy and plays automatically; without it, it connects with just its own log-only prompts and you play manually (see below).
- `src/client/lib/strategy.q` - shared basic-strategy tables, card-counting helpers, and the real auto-play logic; each strategy script loads this itself, so it's never loaded for manual play.
- `src/client/lib/*.q` (all except `strategy.q`) - pluggable per-player strategies, each self-contained (loads `strategy.q` itself) - see below.

## Usage

Start the server first, from the repo root:

```bash
q src/server/bin/blackjack.q
```

The server has no notion of "gameplay mode" - it just deals the game and
exposes `stake`/`hit`/`stick`/`double`/`split`/`hist` to every connection the
same way (`shuffle`/`buildDeck` are server-internal only - reshuffling happens
automatically once the deck runs low, not on player request). It also
unconditionally pushes `.plr.stake`/`.plr.play`/
`.plr.shuffle` to every connected handle at the relevant point in play.
`player.q` defines those three names itself, as simple log-only
prompts ("it's your turn - run ... when ready"); loading a strategy via
`-player <name>` also pulls in `strategy.q` (each `src/client/lib/*.q`
strategy file loads it itself, at its own top), which redefines the same
three names with the real auto-play logic, so a bot reacts to the pushes
automatically instead. The server itself has no notion of "how many hands"
either - it always deals the next hand once everyone's bet; each
`player.q` decides for itself, via its own `-hands`, how many it
plays before disconnecting (see below).

- `-seed` - RNG seed for the shuffle. Optional, default derived from the current time.

Optionally start the detection process (after the server is up):

```bash
q src/server/bin/pitboss.q
```

### Running a player

Each player connects with `player.q`, from the repo root:

```bash
q src/client/bin/player.q                          # manual - play by hand, prompted each turn
q src/client/bin/player.q -player <name> -hands 100 # auto - <name> plays 100 hands, then disconnects
```

**Manual mode** (no `-player`): connects without touching `strategy.q` or
any strategy file, so you get `player.q`'s own log-only prompt each
time it's your turn (`It's your turn to stake - run stake[bet] when ready`,
etc.) instead of auto-playing. You then call `stake[bet]`, `hit[]`,
`stick[]`, `double[]`, `split[]`, `hist[]` directly in your console,
whenever you're ready, for as long as you want -
`player.q` defines each of these itself, forwarding it to the server
over the connection it opened, so you never have to touch the handle
yourself. `-hands` only applies to auto mode.

**Auto mode** (`-player <name>`): loads that strategy from `src/client/lib/`
(which pulls in `strategy.q` itself) and plays every hand automatically.
`-hands` (optional, default `1000`) caps how many hands *this client*
plays before it disconnects on its own - other players at the table, auto
or manual, aren't affected and the server keeps dealing regardless:

| `-player` value | Strategy |
|---|---|
| `avgPlayer1` | Basic hit-below-17 play; flat $20 bet every hand. |
| `avgPlayer2` | Basic hit-below-17 play; bets the previous hand's profit (falls back to $10). |
| `avgPlayer3` | Basic hit-below-17 play; bets $20 on every 5th hand, $10 otherwise. |
| `basicCardCounter` | Full basic-strategy play; sizes bets off the Hi-Lo ("basic") running count. |
| `smallSpreadBasicCardCounter` | Same as `basicCardCounter`, but with a smaller bet spread (less swingy bets). |
| `omegaCardCounter` | Full basic-strategy play; sizes bets off the Omega II running count. |
| `perfectCardCounter` | Full basic-strategy play; sizes bets off a "perfect" (level-9) running count. |

Run one `player.q` per player you want at the table, mixing manual and
auto freely - for example:

```bash
q src/server/bin/blackjack.q                                 # terminal 1
q src/client/bin/player.q                                    # terminal 2 (manual)
q src/client/bin/player.q -player avgPlayer1 -hands 100      # terminal 3 (auto, 100 hands)
```

A human can also join directly with a plain `q` session connected to the
server (`` h:hopen`:localhost:5555 ``) instead of running `player.q` -
same manual commands, but without the friendly prompts (the server's
pushes just print a harmless error to the session's own console, since
`.plr.stake`/`.plr.play`/`.plr.shuffle` are undefined there).

## Enhancements
- use qprof to check speed of functions
- protected eval function
