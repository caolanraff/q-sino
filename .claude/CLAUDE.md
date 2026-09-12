# q-sino

A multiplayer blackjack game implemented in q/kdb+. A server process deals the
game over IPC; one or more client processes play hands using pluggable
strategies (basic average play or card-counting systems); an optional
detection process watches for card-counting behavior.

## Working with q code in this repo

Before writing, editing, or reviewing any `.q` file here, load these skills
(kdb+/q conventions, common pitfalls, Python→q translation, and a review
checklist):

- `/Users/caolanraff/Development/claude/skills/q/SKILL.md` (+ `reference.md`
  and `references/*.md`: `common-errors.md`, `python-q-mapping.md`,
  `review-checklist.md`, `shell-patterns.md`)
- `/Users/caolanraff/Development/claude/skills/qlint-snippet/SKILL.md` — use
  to lint a q snippet before presenting it, if `QLINT_DIR` is configured.

See [architecture.md](architecture.md) for the IPC message
protocol, table schemas, and player-strategy contract — read it before
changing `.bs`/`.mc`/`.da` state or adding a new player script.

## Layout

```
src/server/blackjackServer.q   the dealer/game engine (namespace .bs)
src/server/detectionAlgo.q     card-counting detection, connects to the server (namespace .da)
src/client/masterClient.q      generic player client, connects to the server (namespace .mc)
src/client/playerCore.q        shared basic-strategy tables + card-counting helpers
src/client/players/*.q         pluggable per-player strategy/betting scripts
```

There is no build step — everything runs directly under `q`.

## Running

Start the server first (defaults: `-gameplay manual`, `-hands 1000`, random seed):

```bash
q src/server/blackjackServer.q -gameplay auto -hands 100
```

Optionally start the detection process (must come up after the server, on port 5556):

```bash
q src/server/detectionAlgo.q
```

Connect one client per player, from `src/client/` (masterClient.q loads
`playerCore.q` and the chosen strategy file via relative path, so run it from
that directory or adjust accordingly):

```bash
cd src/client
q masterClient.q -player avgPlayer1
```

Valid `-player` values: `avgPlayer1`, `avgPlayer2`, `avgPlayer3`,
`basicCardCounter`, `smallSpreadBasicCardCounter`, `omegaCardCounter`,
`perfectCardCounter`.

The server listens on port `5555` (`\p 5555`); the detection process listens
on `5556` and dials into `5555` on startup.

In manual gameplay, connected clients (including a plain `q` process acting
as a human player) call server-exposed functions directly over the handle:
`stake[bet]`, `hit[]`, `stick[]`, `double[]`, `split[]`, `shuffle[]`,
`buildDeck[]`, `hist`.

## Git worktrees

This repo lives under `~/Documents`, which iCloud Drive syncs — including
`.git` internals — and that can cause severe git slowness once multiple
worktrees are in play. Do not create worktrees inside this repo's directory
tree (e.g. `.git/worktrees` defaults, or a sibling folder under
`~/Documents`). Instead, put them under:

```
~/git-worktrees/q-sino/<worktree-name>
```

e.g. `git worktree add ~/git-worktrees/q-sino/fix-shuffle-guard <branch>`.
Branch/HEAD state is unaffected — only the working-tree location changes. If
a worktree already exists somewhere under `~/Documents`, move it out with
`git worktree move <old-path> ~/git-worktrees/q-sino/<worktree-name>` (skip
any listed as `locked` in `git worktree list` — those are in active use).

## Known gaps / enhancements (from README)

- Remove the `while` loops in `.bs.deal0` (prefer vectorized iteration).
- Move globals into namespaces consistently (currently mixed root/`.bs`).
- Factor out duplicated bust/21 handling shared by `deal`/`hit`.
- Profile hot functions with qprof.
- Add supervised learning driven by fixed seed values.
- Wrap eval paths defensively (protected eval).
- Have the detection algo publish live findings over websockets.
