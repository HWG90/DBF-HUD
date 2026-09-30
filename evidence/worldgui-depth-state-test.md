# Isolated WorldGUI depth-state test, 2026-09-30

Read-only native inspection connected the selected GUI libraries to their device
graphics descriptors. Both the plain and named depth variants have DepthEnable=0,
DepthWriteMask=0, DepthFunc=7. The selected depth program's VS and PS pointers
resolve into the expected library, so this is actual descriptor evidence rather
than an inference from the resource name.

The native program constructor at 0x7FF692C25650 decodes serialized state enum 10
as depth enable, enum 11 as depth write, and enum 12 as depth comparison. The
depth descriptor is written to native pass +0x2D8. In this session the depth pass
is 0x20C44F02490 and the plain pass is 0x20C44EE90C0; these addresses are temporary.

The disk payload has an 0x88-byte prefix absent from the relocated library base.
Its 39 serialized state records start at disk offset 0xC88. Enum 10 occurs at
0xD98, and its value at 0xDA0 is zero. This corrects the initially suspected
disk offset 0xD18, which applies to the relocated base instead.

The new addon clones that library and the native solid GUI material using unique
DBF-HUD resource names. It changes only depth enable to 1 and the three compiled
identifiers needed to distinguish the clone. Shader bytecode, context, layer,
comparison mode 7 (GREATER_EQUAL), depth writes (off), and remaining state stay
unchanged. No shared native GUI resource is overridden. No process memory writes
or new native function calls are used.

The experimental WorldGUI renderer prefers the new material when available.
Ordinary direct WorldGUI and scene mesh modes retain their existing behavior.
The creation-time material list remains removed. Existing materials remain the
fallback if the addon is absent.

Build with `python tools/build_depth_state_test.py`. Import the generated
DBF-HUD-WorldGUI-Depth-State-Test-0.1.zip in Arsenal, enable and deploy, then
restart the game. Select On (World GUI - experimental). Check the background,
digits and bar behind the character and solid scenery.

Offline checks validate the archive payloads, exact state modification and
renderer selection. Native resource loading and scene-depth attachment are still
unverified. Enabling hardware depth does not itself prove the pass receives a
compatible scene depth buffer. If loading fails or rendering regresses, disable
this isolated addon and use the mesh fallback.
