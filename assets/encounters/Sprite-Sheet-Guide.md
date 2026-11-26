# Suvarna encounter sprite sheets

The archive contains individual transparent PNGs for the introductory guardian, the four ordinary enemy roles in each realm, ten minibosses, ten realm bosses, and two separately animatable foreground weak points.

Each regular PNG uses eight columns. Read left to right. Read the rows from top to bottom in this order.

1. Idle and breathing
2. Movement
3. Waking
4. Windup
5. Slash, sweep, and slam
6. Thrust and charge
7. Casting and projectile release
8. Guard
9. Recovery
10. Hit reaction
11. Death
12. Exposure and vulnerability

Characters face left in the sheet. Godot mirrors them and plays the pixel frames with nearest filtering. The JSON manifest lists the cell dimensions, anchors, names and playback rate for each clip. The two core sheets have one eight-frame exposure row.

The sheets combine existing Suvarna concept art with new ImageGen miniboss bases. The movement rows use authored timing tracks, localized 2D pixel deformation, layered weapons, shields, particles and impact effects baked into discrete raster frames.

The ImageGen prompts described a six-cell transparent atlas with an ancient lotus-visor introductory guardian, ash-chain warrior, lotus-armoured officer, copper forge champion, banyan guardian and funerary sergeant. A second transparent sheet depicted a mirror guardian, coil warrior, ash bell-mender, gate official, shrine sentinel and hammered copper shield figure. Both requested original left-facing ancient Indian dark-fantasy sprites, separated on true alpha, with hard square pixels and restricted shade clusters.


## Regional ordinary mobs

Every realm has four individually designed ordinary mob silhouettes with separate equipment and clothing. The 40 base figures were created with built-in ImageGen using the supplied aged-metal and fabric artwork as a style reference, rendered to native game resolution, and animated with authored 2D pixel motion and effect tracks. The boss and miniboss sheets retain their existing designs. The rightmost end frames of attack and recovery rows hold their pose when played non-looping.

## Death and reflection

The death row includes the full recoil, loss of support, impact and settled pose for each combatant. Flyers also fall to the floor in Godot. The last two cells hold the settled body, which remains on the ground briefly before fading in-game.

Vajrakala's forms reuse the Shunyaraja, Brhatkala, Mrinala and Suvarnabimba sheets. The final mirror form uses the existing prince artwork. The supplementary Vajrakala-Reflection sheet shows the exact source frames used for its idle, run, slash, thrust, hurt and death poses. Blank cells on that supplementary sheet are padding. The manifest lists the occupied cells and original frame rectangles.

## Combat poses and effects

The new strips cover blade, lunge, casting and impact anticipation, plus smash, dive and shield bash. Six follow-through strips start from the exact final cel of the matching attack, then release the weight back to idle. Each strip has eight cels. The combat strips use separately articulated arm or equipment poses, contact frames and planted recovery. The JSON manifest records the hand or weapon pivot for each frame. The separate attack-effects sheet uses 64 × 48 cels and includes ground impacts, chain hardware, spells and weapon trails.
