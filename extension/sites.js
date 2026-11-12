// The per-site toggle, shared by pages and the popup. Storage key "sites" holds every site toggled,
// the most recent first, each as { site, on }; a site not in it is on.
"use strict";

const kosmSites = {
  /// Whether kosm styles `site`.
  isOn(sites, site) {
    const entry = sites.find((toggled) => toggled.site === site);
    return entry === undefined || entry.on;
  },

  /// `sites` with `site` set to `on` and moved to the front.
  toggled(sites, site, on) {
    return [{ site, on }, ...sites.filter((toggled) => toggled.site !== site)];
  },
};
