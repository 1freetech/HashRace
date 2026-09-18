# Hash Race World Scale, Camera and Transition Architecture

Hash Race v0.088 formalizes the overworld around three rules: stable proportions, camera framing instead of sprite shrinking, and reusable transitions.

## Spatial contract

The existing world already uses a 48 px art/navigation cell, so v0.088 standardizes around that instead of forcing a disruptive 16/32 px rewrite. The detailed representative is roughly two world cells tall. HQ structures are now 304 x 216 world pixels, partner structures 248 x 176, and utility/service buildings 264 x 184. Door visuals target roughly 48 x 112 px. This gives buildings substantially more visual mass while retaining walkable streets and clear interaction aprons.

world_scale_rules.gd is the single source of truth for live building footprints, collision rectangles, front-door positions and painter depth. Navigation now blocks the same footprint that the renderer shows.

## Camera framing

camera_proportion_controller.gd provides four views:

- CITY - 0.75x
- STREET - 1.0x
- DETAIL - 1.5x
- CLOSE - 2.0x

The live world starts in CITY view so more of each district is visible without reducing the source art itself. Minus zooms out, equals zooms in, and zero resets. Ctrl plus mouse wheel also changes the camera preset. The underlying world renderer continues snapping transforms and character movement to pixel positions.

## Scene transitions

SceneManager is an autoload. It supports both ordinary scene replacement and preserved-scene transitions. Preserving the current scene is important for Hash Race because the overworld owns live mining, treasury and rival state. An interior can be pushed on top of the world, then return_to_previous restores the exact same world node instead of rebuilding the simulation from defaults.

Doorway.tscn is a reusable Area2D portal. Give it a target scene and destination Marker2D name. Node-based maps can use either the Player or player group.

## Roof visibility

roof_fade_area.gd supports node-based buildings. The live procedural city additionally fades a building when the representative is directly behind its footprint, using the same 30 percent visibility target. This preserves believable building scale without hiding the character.

## Entry cues

The live procedural facilities use larger dark door frames, visible handles, entrance mats and a proximity glow. A future interior map can place a Doorway.tscn over the same visual door and transition through SceneManager without changing the exterior art contract.
