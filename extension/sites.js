// The per-site toggles, shared by pages and the popup. Storage key "sites" holds every site toggled,
// the most recent first, each as { site, colors, font, corners }; a site not in it has all on.
"use strict";

const kosmSites = {
  /// What kosm styles on `site`: { colors, font, corners }, each true unless toggled off.
  togglesOf(sites, site) {
    const entry = sites.find((toggled) => toggled.site === site);
    // Entries stored before the separate toggles hold a single `on` for all; those stored before
    // corners have none for them.
    return {
      colors: entry?.colors ?? entry?.on ?? true,
      font: entry?.font ?? entry?.on ?? true,
      corners: entry?.corners ?? entry?.on ?? true,
    };
  },

  /// `sites` with `site` set to `toggles` ({ colors, font, corners }) and moved to the front.
  toggled(sites, site, toggles) {
    const entry = { site, colors: toggles.colors, font: toggles.font, corners: toggles.corners };
    return [entry, ...sites.filter((toggled) => toggled.site !== site)];
  },
};
