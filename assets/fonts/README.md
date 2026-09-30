# Prepared Nerd Fonts library

Source: Nerd Fonts v3.5.1, https://github.com/ryanoasis/nerd-fonts/releases/tag/v3.5.1

72 release families, 2,252 individual TTF/OTF faces. These are prepared assets for later integration, not new live font choices.

Each face has a lossless 48px grayscale PNG alpha mask, JSON glyph bounds/advance/cell coordinates and source checksum. Text faces cover printable ASCII (U+0020-U+007E); unsupported characters are marked explicitly and left blank. The two SymbolsOnly faces include all 10,624 source symbols each. Other Unicode and Nerd Font icons in text faces are not rasterized yet.

Keep neutral white RGB and use the mask as glyph alpha when implementing a renderer. Preserve metrics and bearings; do not force proportional fonts onto BigBlue's 8x12 pixel grid. Never load every face at startup: load only the selected face.

Original upstream README/license/copyright files accompany each family. Derived glyph atlases retain their respective upstream licensing requirements; this directory does not grant a new blanket license. IMPORT.json records source archive URLs and SHA256 checksums. The downloaded original archives are cached outside the repository for future conversion.

Regenerate with tools/import_nerd_fonts.py --cache <directory>. Requires Pillow and fontTools. The converter checks download digests where available, mask-cell bounds and missing-character coverage. BigBlue's existing native 8x12 rectangle renderer remains unchanged.
