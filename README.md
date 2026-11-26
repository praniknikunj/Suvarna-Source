# Suvarna - The Last Vow

Suvarna is a side-scrolling pixel-art dungeon crawler for Godot 4. The title offers Pilgrimage, a seeded run with standalone story chapters inside an endless cycle, and Dungeon Survey, the optional top-down assessment mode.

## Start a run

Open the project in Godot and press **F5**. Choose **Pilgrimage** for a fresh seed, or enter a seed and choose **Begin with this seed**. Copy or view the current seed in the gallery chart. The same seed and game version recreate the realm layouts.

## Pilgrimage controls

| Key | Action |
| --- | --- |
| Left / Right | Move and face the direction of travel |
| Up | Jump. Hold for a higher jump |
| Down | Drop through a ledge beneath your feet |
| X | Sword slash |
| V | Thrust farther forward with a longer recovery |
| E | Enter, interact, collect, or select |
| P | Pause. Use Up and Down to navigate and E to select |
| Shift | Dodge |
| Q | Use the Prayer Wheel at a cracked wall |
| Tab / B / I | Gallery chart / relics / journal |
| C | Copy the current dungeon seed |

## Progression

The opening cloister teaches movement and combat controls. The next chamber has a shrine that restores half of maximum vitality, up to full, when activated. Pretaghanta bars the First Gate. Defeat him and enter the gate to start the first realm.

A realm has ten dungeons. Regular dungeons are generated from the run seed. Dungeons one through five feature ground and flying foes. The sixth introduces the 5-HP shield bearer. The ninth returns to ground and flying foes, then leads into a clear approach about seven seconds long at a normal run and a miniboss encounter. The tenth contains the realm boss. Boss victories unlock the next realm through a narrated transition. The story reaches Vajrakala at dungeon 100, and the cycle can continue into dungeon 101.

## Combat

Suvarna starts with 100 maximum vitality and a continuous health bar. Ashes collected in Pilgrimage can permanently raise maximum vitality by ten. Enemies have their own health and damage. The basic ground foe has 3 HP, and the shield bearer has 5 HP. Both sword attacks deal one point to common enemies. Against a guardian, a successful hit is scaled to 1-5 percent of its maximum health. A thrust has more reach and a longer recovery. Jump over the shield bearer to strike its back. It keeps facing the previous direction for two seconds while guarding.

The common enemies change with each realm. Citadel guards close distance with a thrust, catacomb guards use broader sweeps, and mirror guards lunge faster. Flyers change their height and dive trajectory. Casters use realm-specific projectile patterns and retreat distances.

Guardians wind up, commit to a strike, and become vulnerable during recovery. Watch the weapon for a sweep or charge, move clear of Pretaghanta’s marked bell drop, jump a low shockwave, and move off the floor markers before the chains or pillars hit. Shift dodges after your sword recovery. Light projectiles can be cut, while chains, shockwaves and pillars must be avoided. Guardian patterns, timing and health vary by encounter. A guardian hit costs one third of the player's maximum vitality, rounded up. Padmavati and Shunyaraja expose their lotus and crown during recovery.

## Sprites and controller

Animated transparent sheets live in `assets/encounters`. Each sheet contains frame strips for idle, movement, waking, windup, slash, thrust, cast, guard, recovery, hit, death, and exposure. See the sheet manifest for exact pivots and timings.

See ASSESSMENT.md for Survey and ESP32 controller setup.

## Pixel-art opening

The title and opening use three original cinematic plates generated with built-in ImageGen, reduced to indexed color and rendered with nearest sampling. The walk cycle, weather, mist, lamp embers, blade reflection, bitmap lettering and scene timing are composited in Godot. The score is an original synthesized ambience track.

Image prompts used for the plates:
- **Black Ghats.** Widescreen 2D clustered pixel art on a 480 × 270 grid. A vast rock-cut hill monastery, Dravidian-style entrance tower, rain, indigo cloud, small saffron lamps and a warm break in the storm. No characters, text or UI.
- **Processional.** Side-on black-basalt cloister with carved lotus friezes, hanging bronze lamps, vermilion cloth, cool light shafts and a continuous walkable stone plane. Leave the path empty for the animated prince.
- **Sword vow.** Close-up of a weary Indian prince in dark quilted clothing and a maroon sash setting his sword on a carved altar. A clay oil lamp lights his hand, the sword and the stone. Crisp square pixels, restrained mineral colors, no rings or interface.
