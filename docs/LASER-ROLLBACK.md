# Earlier laser layouts and artwork-bay rollback

The later `catalog_housing` artwork bay is retired (`enabled=false`; eligibility false). Its upper framed artwork is no longer drawn on unprotected catalog variants. Earlier main count/gauge, ammunition icons, reserves and selected decorations remain. Accepted custom Double Freedom, Autocannon, Recoilless, fuel/gas and Senator displays retain their own paths. The rejected 79-weapon proposal remains disabled and absent from standard bundles.

All native heat gauges bypass later catalog theming. The identified laser resources also bypass it in heat, count and infinite-energy modes, sharing the preceding layout while preserving their actual telemetry and warning behavior. This also covers heat weapons whose readable catalog identity is not yet mapped.

| Resource | Repository identity |
| --- | --- |
| 416d053372c4e433 | LAS-58 Talon |
| 27ee1ed8f6fb6356 | LAS-5 Scythe |
| 295beb26dc4f8ff1 | LAS-17 Double-Edge Sickle |
| 35a61296619cc47e | LAS-99 Quasar Cannon |
| 3c86e871923f3970 | LAS-13 Trident |
| 7e3145a5baa4b948 | laser_rifle_charge (legacy resource alias; readable model unverified) |
| 8645f167b3c813a2 | LAS-16 Sickle |
| c85f576d5e086147 | LAS-12 Sai |
| d54b9505c0f72873 | LAS-98 Laser Cannon |

The earlier behavior is recovered by bypassing the additive presentation layer, rather than replacing the reader or gauge implementation. The preceding gauge path is present in commit 41654c1 and the preserved pre-catalog source; current font measurement, leading-zero treatment and user-selected decorations remain. Offline contracts compare all nine IDs against the presentation-bypassed baseline at three scales and in heat/count/infinite modes.

166 contracts passed. Native appearance and all laser variants still require user assessment; no universal live acceptance claim. Local logs, installed settings and the private alternate Senator are not published.
