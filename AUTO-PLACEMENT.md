# Experimental root placement checkpoint

Manual remains default and retains saved offsets. Auto caches a weapon-local mount per equipped entity/candidate/avatar and view, after a 0.4 second settling interval. It retains weapon direction; left shoulder and first person remove roll. Model clearance and general backpack detection are not implemented.

Current fallback (metres relative to weapon root):
- Right shoulder: lateral +0.13 to +0.18; forward -0.05 to +0.10; up +0.03 to +0.10.
- Left shoulder: lateral -0.53 to -0.58; forward -0.20 to -0.05; up +0.11 to +0.18.
- First person: lateral -0.12; forward +0.35; up +0.22; panel size multiplier 0.5.

The first two ranges come from the projected seed with bounded clearance. First person currently overrides the seed with shared rifle-tuned constants, which float too high on handguns. User visually confirmed right and left positions and upright left rotation; rifle first-person position improved and was confirmed readable. Keep these as a fallback while researching optic/sight scene nodes. No optic or barrel node has been identified yet.
