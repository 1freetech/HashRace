# Default player: 32-pose approved character

The user-approved September 21, 2026 character reference is the source for this integration. The original uploaded PNG is valid: 1536×1024 RGBA, 2,522,109 bytes, SHA-256 `39e4a44304249eaebeb1917e3cfd36953e19b60d7ffd9a2c7804293ed54df2cd`. Its labels, grid and gray background make it unsuitable as a direct runtime sheet.

The cleaned transparent derivative was made with the built-in image tool, preserving the spiky black hair, brown skin, green eyepiece, silver headphones, white/gray armor, black gloves and orange shoulders/boots. Its complete PNG binary lives at `Godot/art/characters/default_player_sheet.png` (1536×1024 RGBA, 2,095,896 bytes), SHA-256 `2a05fdf8fac364b48ae4c0ca5a0a5573a0439a42c7d2c01e372986f5cfdcd211`.

| Source row | Direction | Idle | Walking |
| --- | --- | --- | --- |
| 1 | Down | Column 1 | Columns 2–8 |
| 2 | Left | Column 1 | Columns 2–8 |
| 3 | Right | Column 1 | Columns 2–8 |
| 4 | Up | Column 1 | Columns 2–8 |

The source has small spacing differences. `default_player_sprite_sheet.gd` maps all 32 exact rectangles into a common 160×240 logical frame with the feet anchored at (80,232). It never assumes that a generated sheet has an exact uniform pixel grid. `AtlasTexture.margin` gives reusable SpriteFrames the same alignment as the live world renderer. Idle holds the last direction; movement visits only the seven walking poses. Nearest sampling and a uniform 0.5 world scale preserve aspect ratio. The old runtime green recoloring is removed.

## Required verification

`validate_player_sprite.gd` checks all source PNG/JPG/WebP files with Godot's actual image decoders, checks the embedded energy WebP, verifies the exact player SHA-256, and checks transparency, 32 distinct nonoverlapping regions, animation transitions, and consistent foot anchors.

`capture_player_sprite.gd` instantiates the actual `world.tscn`, drives the live player through all 32 poses, rejects identical rendered player crops, and saves full gameplay screenshots for idle and walking in each direction. `capture_screenshot.gd` also requires the real player, terrain, container and supporting textures and a nonblank gameplay frame. These checks run from clean GitHub Actions checkouts before merge/release validation.

Two corrupt terrain PNGs and the damaged embedded energy atlas were replaced with previously prepared healthy copies of the same artwork. Terrain regions now scale correctly to the recovered 512×512 sheets. The unused corrupt v0.130 overview JPEG was removed; the live C-01 Command Center loader is preserved. Historical source contracts now follow the real world inheritance chain instead of requiring an old scene target or a comment listing old files.

The character change continues the consolidated `world_v138.gd` recovery architecture; it does not add another version-specific world script.

## Image edit prompt

Use case: background-extraction. Asset type: actual transparent PNG sprite atlas for the Hash Race Godot game. Edit the supplied character sprite chart into a production sprite sheet. Preserve this exact recognizable character: dark brown skin, black spiky hair, white and gray suit with orange shoulders and boots, black gloves, silver headphones, green eyepiece. Preserve the 32 supplied poses, with four rows in order down/south, left/west, right/east, up/north; each row has eight columns: one standing/idle pose then seven walking phases. Remove ALL chart headings, letters, row labels, column numbers, grid lines, margins, and gray background. Result must have real alpha transparency, no painted checkerboard, no gray or white backdrop. Exact uniform invisible 8-column by 4-row atlas on a 1536 by 1024 pixel canvas: 192 by 256 pixels per cell, columns equally spaced, rows equally spaced, each figure centered horizontally with feet at cell y=244; consistent character scale; each full figure fits inside its cell with clear transparent padding. Crisp pixel art, no soft shadows. Do not add more characters, rows, text, labels, lines, symbols outside the existing suit, extra props or a scene. This is an edit of the attached sheet for gameplay, preserve the design and direction order.
