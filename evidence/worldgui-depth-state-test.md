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

### Loader-control milestone

The complete native ee6b1ba7e22d71ed archive has 953 records. An independent
calculation of separate CPU/GPU buffer offsets, padding each present payload to
256 bytes in file-index order, matched every record with zero discrepancies.
The resulting totals exactly matched its declared header buffer sizes. The
withdrawn test incorrectly assigned both CPU payloads buffer offset zero. This
is another concrete archive defect; a matching fault address is unavailable.

The native default shader-library group resolves to
core/stingray_renderer/shader_libraries/default_shaders. Its version is 142,
count is 77, and its payload contains both plain and depth GUI library hashes.
The live program manager's variant map resolves D78AB313 to the native depth
variant, and its program map resolves 63AE484F to the graphics program. This
establishes the native entries and their loaded layouts, not custom-load safety.

The new Shader Loader Control addon preserves all 77 native group references
and appends one uniquely named control library. No installed patch already
overrides this group. The control retains DepthEnable=0, so it separates native
loading/registration from the depth-enable experiment. Its material is not
selected by the working Lua renderer. The builder validates distinct buffer
ranges, declared buffer extents, payload alignment and exact changes to shader
identifiers. The depth-enabled builder remains blocked.

This is an experimental native asset load test. Launch and custom variant/program
registration still require verification. No visible HUD change is expected.
Keep the withdrawn Depth State Test disabled. Import the Shader Loader Control
in Arsenal, deploy and restart; then inspect its new variant and program entries.

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

### Live loader control and archive-target isolation

Control 0.1 was deployed and the game reached HUD initialization and the mission. Application.can_get returned true for the control shader, its material, and default_shaders. Fresh native manager lookups still found only the native GUI entries; control variant 75C7DC83 and program 1F57CB83 were absent. Resource discovery therefore does not establish program registration.

The control placed its default-group override under archive 9ba626afa44a3aa3, while the verified native group belongs to ee6b1ba7e22d71ed. Control 0.2 targets that native archive. All three archive payloads are byte-identical to 0.1; only archive targeting and addon metadata change. This is a loading hypothesis, not a proven cause. DepthEnable stays zero. The revised control needs deployment/restart before registration can be verified.


Mission timing correction: the user clarified that the earlier registration check was before entering a mission. After explicit in-mission confirmation, a fresh read still resolved native D78AB313/9FCFE126/63AE484F and did not find control 75C7DC83/1F57CB83. The HUD log simultaneously showed active weapon 745, tracked pose and camera samples. The absence now has a verified mission checkpoint; the earlier mission claim was premature.


### Revised control registration confirmed

After deployment of control 0.2, the game reached HUD initialization. The installed unique resource was found only in ee6b1ba7e22d71ed.patch_0. Fresh native manager lookup resolved control variant 75C7DC83 and program 1F57CB83, alongside the existing GUI entries. The registered program pointed to the relocated control GPU payload; a bounded read of its state record confirmed enum 10 still has value zero. The archive-target-only revision therefore established custom program registration in this session; it does not establish depth-tested rendering.

Experimental gui_depth now availability-selects the registered loader-control material for a depth-disabled baseline draw. Direct gui and mesh modes are unchanged; all 47 contracts pass. A live panel draw still requires an equipped weapon and visual confirmation before creating a depth-enabled revision.


### Depth-enable-only probe

The user visually confirmed normal drawing with the registered loader-control material selected in experimental WorldGUI, then authorized enabling depth testing. Probe 0.3 uses the same addon identity, native archive target, resource names, identifiers and buffers as control 0.2. Exact zip comparison establishes identical main and stream payloads, and exactly one differing GPU byte: offset DA0 changes 0 to 1. Depth writes remain zero and comparison remains GREATER_EQUAL. The original launch-crashing test remains withdrawn; this is a revision of the verified control. Native launch, actual device depth-state construction and scenery occlusion remain unverified until deployment and visual test.


### WorldGUI occlusion visually confirmed

After deploying probe 0.3 and restarting, fresh manager lookup resolved the custom variant and graphics program. The program's relocated serialized state record was enum 10, value 1. The live HUD log resolved the control material instance and submitted WorldGUI through the explicit-material bitmap path. The user then entered a mission, checked occlusion, and reported that it was working and felt superior to the mesh. This establishes a visually confirmed depth-tested direct WorldGUI checkpoint for this session. Broader weapon, camera-mode, transparency and lifecycle coverage remain to be checked. The mesh remains available as fallback.

