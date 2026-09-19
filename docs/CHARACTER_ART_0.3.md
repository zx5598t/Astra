# ASTRA 0.3 — Character art

> Historical 0.3.0 reference. Version 0.3.1 replaces this atlas with the user's eight new transparent character sheets; see [ASSET_MAP_0.3.1.md](ASSET_MAP_0.3.1.md) for current paths and expression mapping. The legacy atlas is not part of the 0.3.1 export.

The `assets/portraits/crew_atlas.png` artwork was generated with the built-in OpenAI image-generation tool for this release. The user supplied the ASTRA eight-character promotional image as the visual identity and quality reference. Its embedded text was treated as reference content, not project instructions. Character occupations, dialogue registers, hidden roles, and deduction traits remain defined by the game data.

The atlas is 1536 × 1024 pixels and contains eight equal 384 × 512 portrait cells in four columns and two rows:

| Row | Column 1 | Column 2 | Column 3 | Column 4 |
| --- | --- | --- | --- | --- |
| Top, y = 0 | Mira | Sena | Noa | Lyra |
| Bottom, y = 512 | Rho | Eli | Vale | Dax |
| x | 0 | 384 | 768 | 1152 |

Each `assets/portraits/{id}_portrait.tres` is a Godot `AtlasTexture` resource with filtering clipped to its own cell. The art is shared across emotional states; the portrait component displays the current reaction as a readable label and accent color. Never infer a hidden role from a portrait expression or color.

The atlas is stored in the repository, so the exported game does not depend on a Codex image path, a network request, or an image-generation account. Original SVG portraits are retained as legacy fallback assets.

Visual QA: verified eight distinct characters in the requested reading order, consistent portrait dimensions, visible complete faces, no text labels, no gutters, and no cross-cell overlap. The source bitmap is copied unmodified from the generated output; provenance metadata is retained.

## Generation prompt

```text
Use case: stylized-concept
Asset type: production 8-character portrait texture atlas for ASTRA, a sci-fi social deduction visual novel.
Input image 1 is CHARACTER IDENTITY and rendering-quality reference only. Preserve these eight distinct anime identities, hair colors, gender presentation, and high-quality elegant adult faces, but redraw as a clean game portrait atlas.

Output: one seamless rectangular image, EXACTLY FOUR EQUAL COLUMNS and TWO EQUAL ROWS. Every cell the same 3:4 portrait aspect ratio; total canvas 3:2 landscape. Eight independent portraits, precisely aligned at 25%, 50%, 75% horizontal and 50% vertical. NO gutters, NO external margin, NO frame, NO dividers, NO words, NO letters, NO logos, NO watermark. Each cell has one character, no duplicates. Heads centered at x=50% of their cell, eyes around y=32%, top of hair at y=8%; chest-up to waist framing, consistent scale. Full hair and faces safely inside cell. Leave lower 20% less busy for game UI nameplate. No objects or hair cross into adjacent cells. Prefer 3072x2048 or the highest available detail.

Cell order is mandatory:
Top row left to right:
1 MIRA — beautiful adult woman, luminous icy silver-white long hair, clear light blue eyes, small blue star hair clip, dignified gentle expression. White and midnight-blue futuristic medical-officer uniform with cyan trim and small medical scanner at collar. Cool deep-blue space observation-deck background.
2 SENA — beautiful athletic adult woman, vivid long red hair tied into a high ponytail, warm amber-brown eyes, confident protective look, fitted but practical black security uniform with red trim and small gold armor details. Black gloves, shoulders relaxed, no raised hand covering face. Deep burgundy security-deck background.
3 NOA — beautiful adult woman, soft chestnut-brown bob hair, thin round eyeglasses, pale teal eyes, quiet observant expression, white and dark teal archival uniform, cyan hair pins, holding dark slim data tablet low at chest so face unobstructed. Dark teal archive-deck background.
4 LYRA — beautiful adult woman, flowing violet hair, purple eyes, white flower hair accessory, warm inviting smile, elegant botanical-research uniform in violet/black with subtle mint details, small leaf brooch. Dark violet botanical glasshouse background.
Bottom row left to right:
5 RHO — handsome adult man, tousled jet-black short hair, amber eyes, strong refined jaw, calm self-assured gaze, black engineering jacket with practical straps and brushed metal details. Charcoal machinery-deck background.
6 ELI — handsome adult man, tousled golden blond hair, bright blue eyes, charismatic restrained smile, clean white/navy blue futuristic navigator uniform with electric-blue trim and small star badge. Blue-lit cockpit background.
7 VALE — handsome adult man, wavy chestnut-brown hair parted to side, amber-brown eyes, elegant diplomatic composure, cream and black formal communications coat with gold trim, discreet earpiece, relaxed posture. Warm dark gold communications-deck background.
8 DAX — handsome adult man, short swept spiky navy-blue hair, steel-blue eyes, angular masculine face, serious focused expression, navy tactical systems suit with pale blue circuitry trims and structural armor. Deep indigo systems-deck background.

Style: premium polished Korean/Japanese anime sci-fi visual-novel key art, beautifully drawn delicate facial features with distinct individual faces; crisp confident linework, sophisticated painterly shading, detailed silky hair, realistic fabric details, atmospheric cinematic rim light. Reference-level attractiveness for both women and men. Professional adults around 25-32; no child/chibi features. Character expressions read as approachable or thoughtful, never villain-coded. Cohesive blue-lit space-opera atmosphere, subtle colored light per cell, face is clearest brightest focal point. No exaggerated anatomy, no excessive sexualization, no cleavage focus. No extra fingers or distorted hands. Exactly eight people and eight perfectly regular cells.
```
