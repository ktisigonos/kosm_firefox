// The per-site toggles, shared by pages and the popup. Storage key "sites" holds every site toggled,
// the most recent first, each as { site, colors, font }; a site not in it has both on.
"use strict";

const kosmSites = {
  /// What kosm styles on `site`: { colors, font }, each true unless toggled off.
  togglesOf(sites, site) {
    const entry = sites.find((toggled) => toggled.site === site);
    // Entries stored before the two toggles hold a single `on` for both.
    return { colors: entry?.colors ?? entry?.on ?? true, font: entry?.font ?? entry?.on ?? true };
  },

  /// `sites` with `site` set to `toggles` ({ colors, font }) and moved to the front.
  toggled(sites, site, toggles) {
    return [{ site, colors: toggles.colors, font: toggles.font }, ...sites.filter((toggled) => toggled.site !== site)];
  },
};
