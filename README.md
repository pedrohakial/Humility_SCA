# Humility_SCA

A Godot prototype for a wooden shipyard + harbor economy game.

## Run the game

1. Open Godot and import `/Users/smmdopnp/dev/godot`.
2. Press `F5` (Run Project).
3. In the harbor scene:
   - Right arrow: advance construction stage
   - Left arrow: go back a stage

## Generate concept assets with OpenAI

The script below generates staged harbor images into `sprites/generated/`.

1. Install dependency:
   - `python3 -m pip install openai`
2. Set your API key:
   - `export OPENAI_API_KEY="your_key_here"`
3. Run generator:
   - `python3 tools/generate_harbor_assets.py`

Optional flags:
- `--model gpt-image-1.5`
- `--size 1536x1024`
- `--overwrite`

Output files include:
- `harbor_stage_0_messy.png`
- `harbor_stage_1_structural.png`
- `harbor_stage_2_market.png`
- `harbor_stage_3_prosperous.png`
- `shipyard_crane_sprite.png`
- `crate_stack_sprite.png`
