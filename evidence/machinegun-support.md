# Regular machine-gun support, September 30

The absent HUD was caused by the inherited reader exclusion for resource
11c27d3babb38956. The local resource-name catalog resolves it to
content/fac_helldivers/equipment/support_weapons/machinegun/machinegun.
The Reticle Ammo HUD reference labels it crash-prone but supplies no specific
failure mechanism in that guard.

Before removal, identity-only logging identified the equipped entity. Separate
bounded Derive reads verified its record, generation candidate, driver component
registry identity and driver flags 0x20C1. The magazine map and registry resolved
the same record. Live static calibration gave capacity 175 and chamber flag 1;
the sampled state gave 160 rounds and reserve 3. The entity record was rechecked
after the reads. No native getters, process writes or renderer changes were used.

The exclusion is removed in favor of the existing identity-checked, bounded
magazine reader. A regression contract uses the actual machine-gun resource hash
and flags and checks both ammo normalization and rejection of a stale magazine
registry identity. These checks do not prove the absence of every possible
native fault. The HUD's visual appearance and fire/reload updates need confirmation.
