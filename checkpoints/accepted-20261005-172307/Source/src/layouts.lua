-- Reference facts: Reticle Ammo HUD 1.1.0, Steam 25327279 and September 24 PE.
-- No layout is guessed on unknown builds. Offsets relative to game.dll.
return {
    stamps={[0x6AA96B14]=0x4770000,[0x6AB3B43F]=0x4744000},
    player=0x3326468,owner=0x346BF98,inventory=0x3326738,driver=0x3326660,
    selector=0x3326420,magazine=0x3326648,rounds=0x3326CF0,heat=0x3326D48,
    entity_map=0xF1AEB0,unit_map=0xF22EC8,records=0xF32F18,
    deposit={0x33265F0,0x33265E8},resource={0x3326AA0,0x3326AA8,0x3326A98,0x3326AB0},
    static={magazine={0xF124A0,540,160,0x60,0xa0},rounds={0xF12820,50,0x88},heat={0xF12CC8,58,0x250},weapon_data={0xF12BD8,730,0x4d0,0x70,0xb0}},
    signatures={
        {0x607200,'488b0561f2d10283b88400000000'},
        {0x6066ed,'8b9410a8030000'},
        {0xfd9c93,'4c8b15fe224902'},
        {0xfd9cc5,'498b9ac82ef200'},
        {0xfd9d83,'498b9ab0aef100'},
        {0x9a83e0,'4c8b1551e39702'},
        {0x745db6,'488b1da308be02'},
        {0x744dc2,'4c8b0d271fbe02'},
        {0x744d02,'488b2d3f19be02'},
        {0x764efa,'4c8b15471ebc02'},
        {0x764f79,'8bc8498b4258488d1449807c9008000f94c0'}
    }
}
