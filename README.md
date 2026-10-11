# Mother's Day Word Game

Digital version of the card game, made with **Godot 4.3** (GDScript). Targets PC, mobile and web.

## Run
Open the folder in Godot 4.3+ and press Play. Tap/click a top card (pool stack or backup pile) to
select it, then tap/click a word row to play it there.

## Rules as implemented
- 117-card deck (see `CARD_COUNTS` in `scripts/game_state.gd`). Choose 1-8 words.
- Setup: one scoring card per word, a 10-card pool stack per word (top card revealed), a 15-card backup pile.
- Playing a card appends it to a word. After **every** play the word is checked; if valid, you score
  the word's value: 1 per letter, but a 2-letter card is worth 3. (CAT +3, then S -> CATS +4.)
- Game ends when no cards are left, or when you press **End Game**.

Assumptions to confirm: cards can only be added to the *end* of a word; only the top card of the
backup pile is playable; words need 2+ letters.

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
