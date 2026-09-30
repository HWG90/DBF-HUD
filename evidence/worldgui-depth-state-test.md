# Isolated WorldGUI depth-state test, 2026-09-30

## Launch failure and rollback

The user reported a launch CTD after deployment. The previous HUD log ends with
normal cleanup and was not recreated by the failed launch; it does not identify
the native fault. The deployed patch_79 was identified by both unique resource
hashes and contained exactly this test's two resources. Its main, stream and GPU
files were moved intact to work/depth-state-launch-crash outside the game data
directory. Experimental material selection was removed from the installed Lua,
and all 46 offline contracts pass on the restored build. Disable the addon in
Arsenal before redeploying, which would otherwise restore the quarantined files.

This package is withdrawn and its builder entry point is disabled. The verified
depth-state finding remains useful, but cloning identifiers and constructing an
archive has not established native shader-library load safety. The next offline
investigation must verify that format and registration path before another test.

### Offline archive audit after rollback

The native ee6b1ba7e22d71ed archive's shader_library type declares main and GPU
alignment 0x100. Both the depth and plain library file rows also declare 0x100
for each alignment. The test declared 0x10 for the shader type and its main file
alignment. It also wrote ApproxGPUSize=0 while providing 14592 GPU bytes. These
are concrete packaging discrepancies, not proof of the exception location.

The draft builder now aligns shader main records and both type alignments to
256 bytes and declares its GPU storage. Its entry point remains disabled. This
has not established validity of runtime MainBufferOffset/GPUBufferOffset or
compiled-program registration for a renamed library. Those still require native
loader inspection before any replacement addon is released. Existing crash
attachments inspected are from earlier sessions, not this launch failure.

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
