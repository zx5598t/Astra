extends SceneTree

# Regenerates the crew portrait SVGs from the part definitions below.
#   godot --headless --path . --script res://tools/portraits/generate_portraits.gd
# Output: assets/portraits/<id>.svg (calm), <id>_warm.svg, <id>_tense.svg
# Edit the data here and re-run instead of hand-editing the SVG files.

const OUT_DIR := "res://assets/portraits"

const CREW := {
    "mira": {
        "bg": "#0e2a3a", "glow": "#63d7ff", "skin_top": "#f7ded0", "skin_bottom": "#eac3ae", "shade": "#e2b7a1",
        "iris": "#2f9fc4", "lash": "#1d2a33", "brow": "#2c4a66", "lip": "#b25c63", "nose": "#cf9a86",
        "back": "<path d=\"M150 250 C138 150 198 104 256 104 C314 104 374 150 362 250 C366 320 372 380 366 430 C340 446 306 440 292 414 L220 414 C206 440 172 446 146 430 C140 380 146 320 150 250 Z\" fill=\"#2c4a66\"/>",
        "body": "<path d=\"M60 640 C70 548 122 474 214 444 L256 486 L298 444 C390 474 442 548 452 640 Z\" fill=\"#dfeef3\"/><path d=\"M214 444 L240 540 L200 560 L150 470 Z\" fill=\"#c4dbe4\"/><path d=\"M298 444 L272 540 L312 560 L362 470 Z\" fill=\"#c4dbe4\"/><path d=\"M214 444 L256 486 L298 444 L286 436 L256 462 L226 436 Z\" fill=\"#1f5068\"/><path d=\"M228 474 C206 522 220 566 256 572\" stroke=\"#35607a\" stroke-width=\"5\" fill=\"none\" stroke-linecap=\"round\"/><rect x=\"330\" y=\"526\" width=\"58\" height=\"16\" rx=\"4\" fill=\"#63d7ff\"/><rect x=\"330\" y=\"548\" width=\"36\" height=\"8\" rx=\"3\" fill=\"#9fdcef\"/>",
        "front": "<path d=\"M166 246 C156 168 200 118 258 116 C318 116 362 164 350 250 C340 214 322 190 296 176 C292 196 280 210 262 216 C266 196 262 182 254 172 C232 196 204 214 172 224 Z\" fill=\"#35577a\"/><path d=\"M240 132 C262 126 290 132 308 146\" stroke=\"#4d7399\" stroke-width=\"5\" fill=\"none\" stroke-linecap=\"round\" opacity=\"0.7\"/>",
        "accessory": "<path d=\"M170 206 C220 184 292 184 342 206\" stroke=\"#63d7ff\" stroke-width=\"5\" fill=\"none\" opacity=\"0.9\"/><rect x=\"334\" y=\"246\" width=\"16\" height=\"38\" rx=\"6\" fill=\"#63d7ff\"/><circle cx=\"342\" cy=\"258\" r=\"3\" fill=\"#0e2a3a\"/>"
    },
    "rho": {
        "bg": "#3a1a12", "glow": "#ff755f", "skin_top": "#e2ab86", "skin_bottom": "#c98e6a", "shade": "#c08563",
        "iris": "#7a5536", "lash": "#2a1d18", "brow": "#2e211b", "lip": "#8f4b43", "nose": "#a86f52",
        "back": "<path d=\"M168 230 C160 160 204 126 256 126 C308 126 352 160 344 230 C340 214 330 200 318 192 L194 192 C182 200 172 214 168 230 Z\" fill=\"#3b2a24\"/>",
        "body": "<path d=\"M56 640 C64 540 118 470 212 442 L256 470 L300 442 C394 470 448 540 456 640 Z\" fill=\"#d9653d\"/><path d=\"M212 442 L256 470 L300 442 L292 430 L256 452 L220 430 Z\" fill=\"#8c3a22\"/><path d=\"M150 482 L196 640\" stroke=\"#2b2f36\" stroke-width=\"20\"/><path d=\"M362 482 L316 640\" stroke=\"#2b2f36\" stroke-width=\"20\"/><circle cx=\"398\" cy=\"560\" r=\"17\" fill=\"#ffb36b\"/><path d=\"M390 560 h16 M398 552 v16\" stroke=\"#8c3a22\" stroke-width=\"4\"/>",
        "front": "<path d=\"M170 214 C170 158 206 128 256 126 C306 128 344 158 342 214 L330 196 L318 210 L304 186 L288 206 L272 180 L256 204 L238 180 L222 206 L206 186 L194 210 L182 196 Z\" fill=\"#3b2a24\"/><path d=\"M206 330 C222 368 290 368 306 330 C296 354 216 354 206 330 Z\" fill=\"#6b4a3a\" opacity=\"0.35\"/><path d=\"M306 296 l15 -10\" stroke=\"#a5705a\" stroke-width=\"3\" stroke-linecap=\"round\"/>",
        "accessory": "<path d=\"M168 198 C220 178 292 178 344 198\" stroke=\"#2b2f36\" stroke-width=\"13\" fill=\"none\"/><circle cx=\"226\" cy=\"186\" r=\"21\" fill=\"#2b2f36\"/><circle cx=\"226\" cy=\"186\" r=\"13\" fill=\"#ffb36b\" opacity=\"0.9\"/><circle cx=\"220\" cy=\"180\" r=\"4\" fill=\"#fff4e0\" opacity=\"0.8\"/><circle cx=\"286\" cy=\"186\" r=\"21\" fill=\"#2b2f36\"/><circle cx=\"286\" cy=\"186\" r=\"13\" fill=\"#ffb36b\" opacity=\"0.9\"/><circle cx=\"280\" cy=\"180\" r=\"4\" fill=\"#fff4e0\" opacity=\"0.8\"/>"
    },
    "eli": {
        "bg": "#24163e", "glow": "#b88cff", "skin_top": "#f3d0b2", "skin_bottom": "#e0b393", "shade": "#d7a888",
        "iris": "#8f6bd6", "lash": "#241a33", "brow": "#2d2347", "lip": "#a35c66", "nose": "#c49178",
        "back": "<path d=\"M160 240 C150 160 204 118 262 118 C320 118 364 160 354 240 C352 226 344 212 334 204 L186 204 C176 214 164 226 160 240 Z\" fill=\"#3a2d5c\"/>",
        "body": "<path d=\"M56 640 C66 544 118 474 208 444 L256 482 L304 444 C394 474 446 544 456 640 Z\" fill=\"#4e3680\"/><path d=\"M226 470 L256 500 L286 470 L270 600 L242 600 Z\" fill=\"#1c1630\"/><path d=\"M190 438 C164 470 172 524 216 544 L256 490 L298 544 C340 524 348 470 322 438 L304 444 L256 482 L208 444 Z\" fill=\"#dcd0ee\"/><path d=\"M196 452 C184 478 192 508 214 524\" stroke=\"#b9a8d6\" stroke-width=\"4\" fill=\"none\"/><path d=\"M316 452 C328 478 320 508 298 524\" stroke=\"#b9a8d6\" stroke-width=\"4\" fill=\"none\"/><path d=\"M350 546 l26 -8 l-11 16 z\" fill=\"#ffd36a\"/>",
        "front": "<path d=\"M162 236 C148 158 204 112 264 112 C332 112 374 160 356 250 C346 224 330 206 312 196 C306 214 296 226 282 232 C276 212 262 198 242 190 C212 196 184 212 162 236 Z\" fill=\"#3a2d5c\"/><path d=\"M250 128 C286 122 324 136 344 166\" stroke=\"#5a4a8a\" stroke-width=\"5\" fill=\"none\" stroke-linecap=\"round\" opacity=\"0.8\"/>",
        "accessory": "<circle cx=\"178\" cy=\"290\" r=\"4.5\" fill=\"#b88cff\"/>"
    },
    "sena": {
        "bg": "#33280e", "glow": "#ffd15c", "skin_top": "#efc49f", "skin_bottom": "#d9a57f", "shade": "#cf9a75",
        "iris": "#b58a2a", "lash": "#2a1e16", "brow": "#3a281c", "lip": "#9a5248", "nose": "#b98567",
        "back": "<path d=\"M318 150 C382 150 408 212 396 292 C390 334 374 364 350 384 C366 332 366 272 340 222 Z\" fill=\"#4a3222\"/><path d=\"M168 236 C160 160 206 122 256 122 C306 122 352 160 344 236 C340 216 332 200 320 190 L192 190 C180 200 172 216 168 236 Z\" fill=\"#4a3222\"/>",
        "body": "<path d=\"M58 640 C66 546 120 474 212 446 L256 470 L300 446 C392 474 446 546 454 640 Z\" fill=\"#2a3348\"/><path d=\"M110 504 C130 472 170 458 208 454 L196 506 Z\" fill=\"#39445e\"/><path d=\"M402 504 C382 472 342 458 304 454 L316 506 Z\" fill=\"#39445e\"/><path d=\"M204 418 L308 418 L316 454 L256 480 L196 454 Z\" fill=\"#1d2436\" stroke=\"#ffd15c\" stroke-width=\"3\"/><path d=\"M150 546 l15 -11 l15 11 l-4 19 h-22 z\" fill=\"#ffd15c\"/><path d=\"M340 540 h60\" stroke=\"#ffd15c\" stroke-width=\"4\" opacity=\"0.7\"/>",
        "front": "<path d=\"M170 226 C166 160 206 124 256 122 C306 124 346 160 342 226 C326 190 296 170 256 168 C216 170 186 190 170 226 Z\" fill=\"#4a3222\"/><path d=\"M176 230 C168 262 170 302 182 328 C186 292 188 260 194 236 Z\" fill=\"#4a3222\"/><path d=\"M226 140 C250 132 280 134 300 144\" stroke=\"#6b4a33\" stroke-width=\"5\" fill=\"none\" stroke-linecap=\"round\" opacity=\"0.8\"/><path d=\"M322 164 C334 170 338 180 336 190\" stroke=\"#ffd15c\" stroke-width=\"6\" fill=\"none\" stroke-linecap=\"round\"/>",
        "accessory": "<path d=\"M172 256 C152 258 150 292 172 298\" stroke=\"#ffd15c\" stroke-width=\"5\" fill=\"none\"/><circle cx=\"170\" cy=\"278\" r=\"8\" fill=\"#1d2436\"/><path d=\"M166 298 C170 332 200 352 224 348\" stroke=\"#ffd15c\" stroke-width=\"3\" fill=\"none\"/>"
    },
    "vale": {
        "bg": "#0f2e27", "glow": "#57e5a5", "skin_top": "#f5d6c0", "skin_bottom": "#e5baa0", "shade": "#dcae94",
        "iris": "#3fbf87", "lash": "#16241f", "brow": "#1b3a34", "lip": "#a65b61", "nose": "#c79279",
        "back": "<path d=\"M156 250 C146 158 202 112 258 112 C316 112 368 158 358 250 C362 300 360 350 346 390 C330 370 324 340 326 300 L190 300 C192 340 186 370 170 390 C156 350 152 300 156 250 Z\" fill=\"#1f4d45\"/>",
        "body": "<path d=\"M60 640 C68 546 122 474 212 446 L256 478 L300 446 C390 474 444 546 452 640 Z\" fill=\"#253836\"/><path d=\"M212 446 L256 478 L300 446 L290 436 L256 458 L222 436 Z\" fill=\"#57e5a5\"/><path d=\"M212 446 L246 580\" stroke=\"#57e5a5\" stroke-width=\"3\" opacity=\"0.55\"/><path d=\"M300 446 L266 580\" stroke=\"#57e5a5\" stroke-width=\"3\" opacity=\"0.55\"/><path d=\"M256 478 l11 22 l-11 64 l-11 -64 z\" fill=\"#152321\"/>",
        "front": "<path d=\"M160 262 C146 170 200 114 262 112 C328 112 372 160 356 250 C340 204 304 178 262 176 C250 214 216 250 176 272 C184 250 184 236 180 222 C172 234 164 248 160 262 Z\" fill=\"#1f4d45\"/><path d=\"M270 126 C300 124 334 140 350 170\" stroke=\"#2f6b60\" stroke-width=\"5\" fill=\"none\" stroke-linecap=\"round\" opacity=\"0.8\"/>",
        "accessory": "<path d=\"M178 198 C210 150 302 150 334 198\" stroke=\"#152321\" stroke-width=\"8\" fill=\"none\"/><rect x=\"330\" y=\"244\" width=\"19\" height=\"42\" rx=\"8\" fill=\"#152321\"/><path d=\"M340 286 C340 320 316 338 286 340\" stroke=\"#57e5a5\" stroke-width=\"4\" fill=\"none\"/><circle cx=\"284\" cy=\"340\" r=\"6\" fill=\"#57e5a5\"/>"
    },
    "noa": {
        "bg": "#2c1426", "glow": "#ff9ed1", "skin_top": "#f8e0d2", "skin_bottom": "#ecc4b2", "shade": "#e3b8a6",
        "iris": "#b0607f", "lash": "#2c2230", "brow": "#4a2f40", "lip": "#b05a6e", "nose": "#d09a8a",
        "back": "<path d=\"M150 256 C140 160 198 116 256 116 C314 116 372 160 362 256 C364 300 360 336 352 356 C330 360 322 330 324 300 L188 300 C190 330 182 360 160 356 C152 336 148 300 150 256 Z\" fill=\"#5a3b4e\"/>",
        "body": "<path d=\"M64 640 C72 548 124 476 214 448 L256 474 L298 448 C388 476 440 548 448 640 Z\" fill=\"#3d3048\"/><path d=\"M214 448 L256 474 L298 448 L284 438 L256 456 L228 438 Z\" fill=\"#f1e6ef\"/><path d=\"M226 466 L256 486 L286 466 L276 640 L236 640 Z\" fill=\"#e9dbe6\"/><circle cx=\"256\" cy=\"530\" r=\"5\" fill=\"#ff9ed1\"/><circle cx=\"256\" cy=\"580\" r=\"5\" fill=\"#ff9ed1\"/><rect x=\"92\" y=\"556\" width=\"112\" height=\"84\" rx=\"9\" fill=\"#241c2b\" stroke=\"#ff9ed1\" stroke-width=\"3\"/><path d=\"M108 578 h72 M108 594 h54 M108 610 h64\" stroke=\"#ff9ed1\" stroke-width=\"3\" opacity=\"0.6\"/>",
        "front": "<path d=\"M160 240 C154 166 202 122 256 122 C310 122 358 166 352 240 C340 234 330 231 322 229 L190 229 C182 231 172 234 160 240 Z\" fill=\"#5a3b4e\"/><path d=\"M166 236 C158 292 168 332 186 350 C188 312 186 272 186 236 Z\" fill=\"#5a3b4e\"/><path d=\"M346 236 C354 292 344 332 326 350 C324 312 326 272 326 236 Z\" fill=\"#5a3b4e\"/><path d=\"M220 138 C248 130 282 132 304 142\" stroke=\"#7a5569\" stroke-width=\"5\" fill=\"none\" stroke-linecap=\"round\" opacity=\"0.8\"/><rect x=\"298\" y=\"200\" width=\"36\" height=\"9\" rx=\"4\" fill=\"#ff9ed1\" transform=\"rotate(-20 316 204)\"/>",
        "accessory": "<circle cx=\"218\" cy=\"266\" r=\"27\" fill=\"none\" stroke=\"#3a2f3a\" stroke-width=\"4\"/><circle cx=\"294\" cy=\"266\" r=\"27\" fill=\"none\" stroke=\"#3a2f3a\" stroke-width=\"4\"/><path d=\"M245 262 Q256 255 267 262\" stroke=\"#3a2f3a\" stroke-width=\"4\" fill=\"none\"/><path d=\"M200 252 l10 -6\" stroke=\"#ffffff\" stroke-width=\"3\" opacity=\"0.5\" stroke-linecap=\"round\"/>"
    },
    "lyra": {
        "bg": "#12301c", "glow": "#8df0a4", "skin_top": "#f0ccaf", "skin_bottom": "#dfae8d", "shade": "#d6a384",
        "iris": "#4f9e62", "lash": "#2e1c14", "brow": "#6e3a22", "lip": "#a5585a", "nose": "#c68d72",
        "back": "<path d=\"M146 250 C132 150 196 104 258 104 C322 104 384 150 368 250 C376 310 392 360 380 420 C372 460 344 470 330 450 C344 420 334 390 320 370 L196 370 C182 390 168 420 182 450 C168 470 140 460 132 420 C120 360 138 310 146 250 Z\" fill=\"#8a4b2e\"/>",
        "body": "<path d=\"M60 640 C68 546 120 476 210 448 L256 476 L302 448 C392 476 444 546 452 640 Z\" fill=\"#3d7550\"/><path d=\"M204 440 C220 472 292 472 308 440 C322 460 318 488 296 502 C276 488 236 488 216 502 C194 488 190 460 204 440 Z\" fill=\"#b8e6c2\"/><rect x=\"138\" y=\"544\" width=\"72\" height=\"42\" rx=\"6\" fill=\"#335f42\"/><path d=\"M370 548 C388 530 410 532 414 544 C400 558 384 562 370 548 Z\" fill=\"#8df0a4\"/>",
        "front": "<path d=\"M158 250 C146 164 200 112 260 112 C326 112 372 160 358 246 C350 214 332 190 306 178 C300 206 280 222 250 226 C262 208 262 192 252 180 C226 206 196 222 166 236 C164 240 160 246 158 250 Z\" fill=\"#9a5636\"/><path d=\"M150 300 C140 330 150 360 144 390\" stroke=\"#a8633f\" stroke-width=\"6\" fill=\"none\" stroke-linecap=\"round\" opacity=\"0.8\"/><path d=\"M364 300 C374 330 364 360 370 390\" stroke=\"#a8633f\" stroke-width=\"6\" fill=\"none\" stroke-linecap=\"round\" opacity=\"0.8\"/><path d=\"M236 128 C266 120 300 128 322 146\" stroke=\"#b56c47\" stroke-width=\"5\" fill=\"none\" stroke-linecap=\"round\" opacity=\"0.8\"/>",
        "accessory": "<path d=\"M178 198 C194 170 226 168 234 182 C222 198 198 206 178 198 Z\" fill=\"#8df0a4\"/><path d=\"M180 198 L232 182\" stroke=\"#3f7a52\" stroke-width=\"2.5\"/>"
    },
    "dax": {
        "bg": "#161e36", "glow": "#8fa8ff", "skin_top": "#e8c3a8", "skin_bottom": "#d2a78b", "shade": "#c99c80",
        "iris": "#6f86c9", "lash": "#1b2233", "brow": "#343c52", "lip": "#98585a", "nose": "#b98b72",
        "back": "<path d=\"M170 230 C164 162 206 128 256 128 C306 128 348 162 342 230 C336 214 328 202 318 196 L194 196 C184 202 176 214 170 230 Z\" fill=\"#4b5670\"/>",
        "body": "<path d=\"M58 640 C66 548 118 476 208 448 L256 472 L304 448 C394 476 446 548 454 640 Z\" fill=\"#37435e\"/><path d=\"M196 426 L316 426 L326 470 L256 502 L186 470 Z\" fill=\"#2a3350\"/><path d=\"M186 470 L256 502 L326 470\" stroke=\"#8fa8ff\" stroke-width=\"3\" fill=\"none\"/><path d=\"M130 546 h80 M130 562 h56\" stroke=\"#8fa8ff\" stroke-width=\"3\" opacity=\"0.7\"/><rect x=\"340\" y=\"536\" width=\"44\" height=\"44\" rx=\"6\" fill=\"none\" stroke=\"#8fa8ff\" stroke-width=\"3\" opacity=\"0.7\"/><path d=\"M350 558 h24 M362 546 v24\" stroke=\"#8fa8ff\" stroke-width=\"3\" opacity=\"0.7\"/>",
        "front": "<path d=\"M170 222 C168 160 208 128 256 126 C306 126 346 160 342 222 C330 192 306 178 274 176 L262 196 L250 176 C222 178 190 194 170 222 Z\" fill=\"#4b5670\"/><path d=\"M270 136 C298 138 324 152 336 176\" stroke=\"#66728e\" stroke-width=\"5\" fill=\"none\" stroke-linecap=\"round\" opacity=\"0.8\"/>",
        "accessory": "<rect x=\"268\" y=\"244\" width=\"54\" height=\"42\" rx=\"8\" fill=\"#8fa8ff\" opacity=\"0.26\" stroke=\"#8fa8ff\" stroke-width=\"3\"/><path d=\"M322 256 L348 244\" stroke=\"#8fa8ff\" stroke-width=\"3\"/><path d=\"M276 252 h22\" stroke=\"#dfe6ff\" stroke-width=\"2\" opacity=\"0.7\"/>"
    }
}

const FACES := {
    "calm": """<path d="M196 238 Q217 226 240 236" stroke="{brow}" stroke-width="6" fill="none" stroke-linecap="round"/>
<path d="M272 236 Q295 226 316 238" stroke="{brow}" stroke-width="6" fill="none" stroke-linecap="round"/>
<ellipse cx="218" cy="266" rx="18" ry="12" fill="#fbfdff"/><circle cx="219" cy="267" r="10" fill="{iris}"/><circle cx="219" cy="267" r="5" fill="#101820"/><circle cx="223" cy="262" r="3" fill="#ffffff"/>
<ellipse cx="294" cy="266" rx="18" ry="12" fill="#fbfdff"/><circle cx="293" cy="267" r="10" fill="{iris}"/><circle cx="293" cy="267" r="5" fill="#101820"/><circle cx="297" cy="262" r="3" fill="#ffffff"/>
<path d="M199 262 Q218 248 238 261" stroke="{lash}" stroke-width="4" fill="none" stroke-linecap="round"/>
<path d="M274 261 Q294 248 313 262" stroke="{lash}" stroke-width="4" fill="none" stroke-linecap="round"/>
<path d="M257 288 Q251 304 259 308" stroke="{nose}" stroke-width="3" fill="none" stroke-linecap="round"/>
<path d="M239 332 Q256 339 273 332" stroke="{lip}" stroke-width="4.5" fill="none" stroke-linecap="round"/>""",
    "warm": """<path d="M196 232 Q217 218 240 230" stroke="{brow}" stroke-width="6" fill="none" stroke-linecap="round"/>
<path d="M272 230 Q295 218 316 232" stroke="{brow}" stroke-width="6" fill="none" stroke-linecap="round"/>
<ellipse cx="218" cy="268" rx="18" ry="10" fill="#fbfdff"/><circle cx="219" cy="270" r="9" fill="{iris}"/><circle cx="219" cy="270" r="4.5" fill="#101820"/><circle cx="222" cy="266" r="3" fill="#ffffff"/>
<ellipse cx="294" cy="268" rx="18" ry="10" fill="#fbfdff"/><circle cx="293" cy="270" r="9" fill="{iris}"/><circle cx="293" cy="270" r="4.5" fill="#101820"/><circle cx="296" cy="266" r="3" fill="#ffffff"/>
<path d="M199 266 Q218 250 238 265" stroke="{lash}" stroke-width="4" fill="none" stroke-linecap="round"/>
<path d="M274 265 Q294 250 313 266" stroke="{lash}" stroke-width="4" fill="none" stroke-linecap="round"/>
<path d="M204 278 Q218 284 232 278" stroke="{lash}" stroke-width="2.5" fill="none" stroke-linecap="round" opacity="0.55"/>
<path d="M280 278 Q294 284 308 278" stroke="{lash}" stroke-width="2.5" fill="none" stroke-linecap="round" opacity="0.55"/>
<ellipse cx="198" cy="302" rx="17" ry="8" fill="#ff8f9a" opacity="0.28"/><ellipse cx="314" cy="302" rx="17" ry="8" fill="#ff8f9a" opacity="0.28"/>
<path d="M257 288 Q251 304 259 308" stroke="{nose}" stroke-width="3" fill="none" stroke-linecap="round"/>
<path d="M236 326 Q256 346 276 326 Q256 334 236 326 Z" fill="{lip}"/>
<path d="M242 329 Q256 338 270 329 Q256 332 242 329 Z" fill="#ffffff" opacity="0.85"/>""",
    "tense": """<path d="M196 230 Q220 232 242 244" stroke="{brow}" stroke-width="6.5" fill="none" stroke-linecap="round"/>
<path d="M270 244 Q292 232 316 230" stroke="{brow}" stroke-width="6.5" fill="none" stroke-linecap="round"/>
<ellipse cx="218" cy="268" rx="18" ry="9" fill="#fbfdff"/><circle cx="219" cy="268" r="8.5" fill="{iris}"/><circle cx="219" cy="268" r="4" fill="#101820"/><circle cx="222" cy="265" r="2" fill="#ffffff"/>
<ellipse cx="294" cy="268" rx="18" ry="9" fill="#fbfdff"/><circle cx="293" cy="268" r="8.5" fill="{iris}"/><circle cx="293" cy="268" r="4" fill="#101820"/><circle cx="296" cy="265" r="2" fill="#ffffff"/>
<path d="M199 263 Q218 255 238 264" stroke="{lash}" stroke-width="4.5" fill="none" stroke-linecap="round"/>
<path d="M274 264 Q294 255 313 263" stroke="{lash}" stroke-width="4.5" fill="none" stroke-linecap="round"/>
<path d="M257 288 Q251 304 259 308" stroke="{nose}" stroke-width="3" fill="none" stroke-linecap="round"/>
<path d="M240 337 Q256 330 272 337" stroke="{lip}" stroke-width="4.5" fill="none" stroke-linecap="round"/>
<path d="M336 212 C345 227 347 236 338 243 C329 236 329 226 336 212 Z" fill="#bfe8ff" opacity="0.85"/>"""
}

const FRAME := """<svg xmlns="http://www.w3.org/2000/svg" width="512" height="640" viewBox="0 0 512 640">
<defs>
<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{bg}"/><stop offset="1" stop-color="#050a14"/></linearGradient>
<radialGradient id="glow" cx="0.5" cy="0.4" r="0.5"><stop offset="0" stop-color="{glow}" stop-opacity="0.38"/><stop offset="1" stop-color="{glow}" stop-opacity="0"/></radialGradient>
<linearGradient id="skin" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{skin_top}"/><stop offset="1" stop-color="{skin_bottom}"/></linearGradient>
</defs>
<rect width="512" height="640" fill="url(#bg)"/>
<circle cx="256" cy="262" r="236" fill="url(#glow)"/>
<g stroke="{glow}" stroke-opacity="0.16" stroke-width="2" fill="none"><path d="M36 84h120M356 84h120M36 104h56M420 104h56M36 588h60M416 588h60"/><circle cx="256" cy="262" r="214"/></g>
{back}
{body}
<path d="M228 330 L228 440 C240 456 272 456 284 440 L284 330 Z" fill="{shade}"/>
<ellipse cx="176" cy="272" rx="13" ry="22" fill="{shade}"/><ellipse cx="336" cy="272" rx="13" ry="22" fill="{shade}"/>
<path d="M176 240 C176 172 212 142 256 142 C300 142 336 172 336 240 C336 302 316 350 256 378 C196 350 176 302 176 240 Z" fill="url(#skin)"/>
{face}
{front}
{accessory}
</svg>
"""

func _initialize() -> void:
    var written := 0
    for npc_id in CREW.keys():
        var parts: Dictionary = CREW[npc_id]
        for expression in ["calm", "warm", "tense"]:
            var face: String = str(FACES[expression]).format(parts)
            var values := parts.duplicate()
            values["face"] = face
            var svg: String = FRAME.format(values)
            var suffix: String = "" if str(expression) == "calm" else "_" + str(expression)
            var path := "%s/%s%s.svg" % [OUT_DIR, npc_id, suffix]
            var file := FileAccess.open(path, FileAccess.WRITE)
            if file == null:
                printerr("cannot write ", path)
                quit(1)
                return
            file.store_string(svg)
            file.close()
            written += 1
    print("PORTRAITS WRITTEN · %d" % written)
    quit(0)
