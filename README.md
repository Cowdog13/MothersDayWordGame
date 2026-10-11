# Mother's Day Word Game

Digital version of the card game, made with **Godot 4.3** (GDScript). Targets PC, mobile and web.

## Run
Open the folder in Godot 4.3+ and press Play. Tap/click a top card (pool stack or backup pile) to
select it, then tap/click a word row to play it there.

## Rules as implemented
- 117-card deck (see `CARD_COUNTS` in `scripts/game_state.gd`), shuffled.
- Setup: 3 starting cards (the words in play), a 10-card pool stack for each (top card revealed),
  and 15 backup cards, all face up. The rest of the deck is unused.
- Select a card (a pool's revealed card, or any backup card, at any time), then tap a **+** at the
  **front or end** of a word to play it there. Playing a pool card reveals the next card in that pool.
- After **every** play the whole word is checked (2+ letters required). If valid you score the word's
  value: 1 per letter, but a 2-letter card is worth 3. (CAT +3, then S -> CATS +4.)
- The game only ends when you press **Give Up**.
- Each finished game is saved to the leaderboard (player name, score, longest word, date), with a
  line chart of your scores over time. Saved in `user://leaderboard.json` (works on desktop, mobile
  and in the browser, per device/browser).

## Word list
`data/words.txt` is the public-domain ENABLE list (~173k words). Swap the file to change what counts as a word.

## Card images
Drop PNGs named after the card into `assets/cards/` (e.g. `A.png`, `TH.png`) and they are used
automatically instead of the placeholder boxes.

## Web export
`export_presets.cfg` has a Web preset (single-threaded, includes `data/*`). Install export templates
in Godot, then Project > Export > Web. Serve `build/web/` over HTTP.

## Tests
```
godot --headless --path . --import
godot --headless --path . --script tests/test_logic.gd
godot --headless --path . --script tests/smoke.gd
```
