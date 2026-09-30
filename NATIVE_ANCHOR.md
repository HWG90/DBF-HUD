# Native crosshair adapter — 0.2

This adapter was independently traced from a locally captured original game.dll image. No HD2UI implementation was read or used. Reticle Ammo HUD supplied the ammo layout reference; the crosshair adapter is separate.

The hud_crosshair setting leads to native update RVA 0x17B6560. Its caller at 0x12EBDF4 passes HUD + 0x19AAF8. The HUD is manager + 0x24E340; manager is the pointer at game.dll + 0x346D538. The update stores projected screen coordinates at controller + 0x2088/0x208C, and UI-local displacement at +0x2090/0x2094. State is +0x2080. HUD activity is checked at +0x58 and +0x21F5B0.

The root widget is found through parent +0xF0, bounded to 32 hops with cycle rejection. Root width/height are +0xC/+0x10. The native projection subtracts half the viewport with camera offset and scales into this root. Camera is the pointer at game.dll +0x346D560, with normalized offsets +0xDC/+0xE0. The adapter inverts this transform and converts to normalized top-left coordinates for the motion API.

Seven short code signatures are checked in addition to the PE build gate. All seven matched the local captured image. Reads are bounded and read-only. The adapter never calls native game functions. An inactive or unreadable native reticle expires to center without fading the ammo panel. External providers still take priority.

Offline tests cover displacement, parent and camera transforms, signature rejection, hidden state, parent cycles, and runtime movement without opacity loss. They establish implementation behavior, not live coordinate correctness. The new mapping, y direction, and supported-build coverage need in-game confirmation. No game binary is included.

For a live check, deploy 0.2, restart, and aim while turning and moving. The counter should remain visible and follow the moving reticle with reduced travel and damping. Check DBF-HUD.log in the game installation root: native crosshair means acquisition succeeded; center fallback includes its failure reason. Motion samples should change while the reticle moves. The log is recreated each session and capped at approximately 512 KB.
