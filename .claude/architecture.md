# Architecture

## Processes

```
blackjackServer.q  (port 5555, namespace .bs)
        ^  ^
        |  |  hopen 5555
        |  +----------------------------+
        |                               |
masterClient.q (namespace .mc)    detectionAlgo.q (port 5556, namespace .da)
   loads playerCore.q
   loads players/<strategy>.q
```

- **blackjackServer.q** owns all game state and is the source of truth. It
  tracks connections in `cp` (handle→user dict), keyed on `.z.w`/`.z.u` via
  `user:{`$string[.z.u],"_",string[.z.w]}`.
- One `masterClient.q` process per player. It `hopen`s the server, then reacts
  to messages the server pushes to it (see below) rather than polling.
- **detectionAlgo.q** is optional and registers itself specially: the server's
  `regConn` recognizes the process param `p:`detectionAlgo` (set at the top
  of detectionAlgo.q) and stores its handle in `DA` instead of `cp`, so it
  receives `gameover`/`shuffle` callbacks but is excluded from player-facing
  broadcasts (`pubMsg` targets `key cp`, not `DA`).

## IPC message protocol

The server drives clients by evaluating a function name on their handle
(`sendMsg`/`pubMsg`/`excFunc` in blackjackServer.q — e.g.
`neg[h](\`stake;bet)` or `neg[h](\`play;\`)`). A client process must therefore
define, at global scope, whatever function names the server invokes on it:

| Server → Client message | When | Client-side handler expected |
|---|---|---|
| `intro` | on connect (`.z.po`) | prints welcome text (defined in blackjackServer.q, sent by value) |
| a string | log/info messages (`lg`, `sendMsg` with a string) | just `show`n by the receiving process |
| `.bs.turn` (table) | whenever turn state changes | client updates its view of the table |
| `` `stake ``, `` `shuffle ``, `` `play ``, `` `gameover `` | `gp=`auto`\` gameplay, or detection callbacks | client must define a same-named function taking the args shown |

`masterClient.q` implements the auto-play side of this: its `play:{...}`
reads `.bs.tab` (via `getTab`), builds a hand summary, calls the loaded
strategy's `Help[]` to get a decision (`` `H`S`D`SP `` → hit/stick/double/split),
and evaluates that decision back on the server handle `h`.

**Adding a new server→client message**: add the call site in
blackjackServer.q (`sendMsg`/`pubMsg`/`neg[h](...)`) and a matching
global-scope function in masterClient.q (or the strategy file, if
player-specific).

## Server state (`.bs` namespace, blackjackServer.q)

- `.bs.tab` — one row per active player-hand this round: `round player name
  handle cards cnt dealer dealerCnt bet return profit split double` (+
  transient columns `out wait turn` added at deal time). A player who splits
  gets a second row via a fractional `player` id (e.g. `1.01`).
- `.bs.res` — completed-hand history for the *current shoe* (accumulated from
  `.bs.tab` at end of round); reset (moved into `.bs.hist`) on `shuffle[]`.
- `.bs.hist` — all `.bs.res` rows from previous shoes this run.
- `.bs.stake` — keyed table of pending bets (`name`,`handle`)→`bet`.
- `.bs.deck` — remaining cards as a symbol vector; rebuilt by `buildDeck[]`
  (`deckCnt`, default 6, decks) and shuffled by `shuffle[]`.
- `.bs.hd` / `.bs.bd` — "hand done" / "bets done" flags gating `stake`,
  `hit`, `stick`, `split`, `double`, `shuffle`.
- `cardDict` — face value lookup, shared verbatim across
  blackjackServer.q, playerCore.q and detectionAlgo.q (`A K Q J 10 9 8 7 6 5 4
  3 2` → `11 10 10 10 10 9 8 7 6 5 4 3 2`); keep these in sync if edited.

## Player-strategy contract (`src/client/players/*.q`)

Every file under `players/` is loaded after `playerCore.q` and must define:

- `Help:{[cards] ...}` — returns one of `` `H`S`D`SP `` (hit/stick/double/split)
  given the player's cards + dealer's up-card. `playerCore.q` supplies a
  full basic-strategy `Help` (hard/soft/pair tables) that counter scripts
  reuse as-is; the `avgPlayer*` scripts override it with a naive
  hit-below-17 rule.
- `getBet:{...}` — returns the stake for the next hand. Card-counting
  scripts key this off `theCount` (maintained by `playerCore.q`'s `Count[]`,
  called from `masterClient.q`'s `stake:{...}`); the `avgPlayer*` scripts key
  it off flat amounts, previous profit, or hand number instead.
- Optionally `setCountDict[`basic\`omega\`perfect]` (playerCore.q) to select
  which point-count system feeds `theCount` — see `omegaCardCounter.q` /
  `perfectCardCounter.q` for the pattern; default is `basic`.

`playerCore.q` globals a strategy file can rely on: `theCount` (running true
count), `bet`, `decks`/`startCards`, and the `hard`/`soft`/`pair`
basic-strategy keyed tables.

## Detection algo (`.da` namespace, detectionAlgo.q)

Consumes `.bs.res` rows pushed via the `gameover` callback and:

- `getBetTrend` — correlates each player's bet size against basic/omega/
  perfect running counts (flags likely card counters).
- `getPlayTrend` — flags suspicious plays: doubling on soft 18-20, splitting
  tens, standing on 15/16 (all textbook counter "tells").
- `chart` — pivots `.da.betTrend` into a per-day/per-player wide table for
  charting bet-vs-count covariance.

If you change `.bs.res`'s column set in blackjackServer.q, update
`getBetTrend`/`getPlayTrend` here to match — they assume its shape.
