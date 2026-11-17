// The per-site toggles, shared by pages and the popup. Storage key "sites" holds every site toggled,
// the most recent first, each as { site, colors, font, corners }; a site not in it has colors and
// font on and corners off, since forced corners are opted into per site.
"use strict";

const kosmSites = {
  /// What kosm styles on `site`: { colors, font, corners }; colors and font true unless toggled
  /// off, corners false unless toggled on.
  togglesOf(sites, site) {
    const entry = sites.find((toggled) => toggled.site === site);
    // Entries stored before the separate toggles hold a single `on` for colors and font.
    return {
      colors: entry?.colors ?? entry?.on ?? true,
      font: entry?.font ?? entry?.on ?? true,
      corners: entry?.corners ?? false,
    };
  },

  /// `sites` with `site` set to `toggles` ({ colors, font, corners }) and moved to the front.
  toggled(sites, site, toggles) {
    const entry = { site, colors: toggles.colors, font: toggles.font, corners: toggles.corners };
    return [entry, ...sites.filter((toggled) => toggled.site !== site)];
  },
};
