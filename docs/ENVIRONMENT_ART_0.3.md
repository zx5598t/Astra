> 역사적 기록: 0.3.0 아트 문서입니다. 현재 배치는 [ASSET_MAP_0.3.1.md](ASSET_MAP_0.3.1.md)를 참조하세요. 구형 에셋은 0.3.1에서 교체됐습니다.

# ASTRA 0.3 — Chapter environments

Generated once with the built-in OpenAI image-generation tool for ASTRA 0.3.0. These are original environment backgrounds; no reference image was supplied. The prompt is recorded below. The PNG was copied without image modification into the repository, retaining provenance metadata.

`assets/environments/chapter_atlas.png` is 2048 × 768 pixels. It contains three panoramic columns and two rows, with six distinct locations and no people or text labels. Its width is not divisible by three, so integer atlas widths differ by one pixel. Each `{case_id}_scene.tres` clips texture filtering at its region.

| Resource | Region (x, y, width, height) |
| --- | --- |
| dead_air_scene.tres | 0, 0, 683, 384 |
| glass_garden_scene.tres | 683, 0, 682, 384 |
| echo_ward_scene.tres | 1365, 0, 683, 384 |
| silent_orbit_scene.tres | 0, 384, 683, 384 |
| red_shift_scene.tres | 683, 384, 682, 384 |
| last_light_scene.tres | 1365, 384, 683, 384 |

Visual QA confirmed the prescribed reading order, six distinct palettes and room silhouettes, aligned boundaries, no characters, no text labels, and usable darker foregrounds for UI. The game loads local textures, without a network or image-generation dependency.

## Generation prompt

```text
Use case: stylized-concept
Asset type: six cinematic environment backgrounds for ASTRA, a premium anime sci-fi social-deduction visual novel.

Create ONE production environment atlas with EXACTLY THREE EQUAL COLUMNS and TWO EQUAL ROWS, total landscape aspect ratio 8:3. Target canvas 3072x1152 pixels; each cell is a 1024x576 panoramic 16:9 background. The six images meet precisely at x=33.333%, x=66.667%, and y=50%; no gutters, outer margin, frames, decorative dividers, text, labels, letters, watermarks or user-interface overlays. No people, silhouettes, corpses or human figures. One full separate room in every cell; no objects crossing between cells.

Shared art direction: the same elegant deep-space exploration ship in every image; sophisticated white alloy and graphite architecture, subtly weathered brushed metal, glass, realistic machinery, atmospheric premium anime environment key art with refined painterly rendering and believable perspective. Rich cinematic lighting, clear visual hierarchy, detailed scene silhouettes, deep spatial composition, polished console displays containing abstract luminous shapes only, never legible text. Mysteries told through locations and lighting. Keep foreground and lower quarter relatively dark/simple so the game can overlay controls. These are beautiful immersive locations, not tiny technical schematic panels.

Strict reading order:
TOP LEFT / DEAD AIR: command bridge after a selective power failure. Dark navy pilot consoles, two empty captain chairs, half-lit cyan control surfaces, a few small amber warning lamps, large reinforced forward windows overlooking a blue Earth-like planet. A damaged side panel gives subtle sparks and a thin wisp of vapor, not an explosion. Cold, lonely, investigative mood, low eye-level wide shot.
TOP MIDDLE / GLASS GARDEN: extraordinary orbital greenhouse in a curved glass dome. Dense emerald planting beds and slender mature trees, elegant hydroponic channels with flowing water, delicate white flowers, misty teal-green light, stars and a crescent planet visible above. A centered walkway leads into lush depth; one small amber quarantine light adds a hint of mystery. Quiet beautiful life against space.
TOP RIGHT / ECHO WARD: deserted futuristic medical and cryogenic ward. Frosted glass sleeping pods along both walls, one empty pod opened near center, white medical alloy, purple-blue running lights, delicate cold vapor over polished floor, dim violet diagnosis screens. Clean and melancholic, eerie absence, no gore, no body.
BOTTOM LEFT / SILENT ORBIT: grand navigation and observation chamber. Sweeping curved window spans the room, an immense blue-violet planet and rings outside, a central low circular holographic orbital chart in luminous cyan composed of concentric paths and points, surrounding dark navigator consoles, understated silver architectural ribs. Breathtaking cosmic scale, quiet blue light, thoughtful mystery.
BOTTOM MIDDLE / RED SHIFT: vast red-lit reactor and optical-control chamber. Central luminous crimson energy column within a massive concentric focusing-lens housing, suspended technical walkways, heavy shielding shutters and coolant conduits, a red star visible through a distant observation aperture. Black graphite and dark metal, sharp red-orange rim light, deep shadows, carefully controlled ominous power; no flames or catastrophic destruction.
BOTTOM RIGHT / LAST LIGHT: luminous escape docking bay at the edge of dawn. Sleek white rescue shuttle docked to the left, long clean floor lines leading toward an enormous open view of a golden planet sunrise, pale gold light filling silver-blue docking architecture, subtle cyan guidance strips, a calm feeling of earned hope. Only one small shuttle, no combat, no people.

Prioritize six genuinely different spatial designs and their signature palettes, identical illustration fidelity, correct rigid architecture, luminous depth, and frame boundaries exactly matching a regular 3x2 atlas. Do not make a poster or collage with irregular angled borders.
```
