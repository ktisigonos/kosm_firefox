// Styles every page with Dark Reader's engine in the kosmos' colors and font, unless its site is
// toggled off. Follows every change to the values or the toggles at once.
"use strict";

/// What storage holds: `values` as kosm wrote them ({ theme }), `sites` as kosmSites keeps them.
const state = { values: null, sites: [], site: null };

function update() {
  if (state.values === null || state.site === null) return;
  if (state.values.theme && kosmSites.isOn(state.sites, state.site)) DarkReader.enable(state.values.theme);
  else DarkReader.disable();
}

/// The top frame knows its site; a frame inside it asks for its tab's, which it can't read.
async function findSite() {
  if (window === window.top) return location.hostname;
  return browser.runtime.sendMessage({ type: "site" });
}

// Content scripts may fetch across origins, which Dark Reader needs for other sites' stylesheets.
DarkReader.setFetchMethod((url) => fetch(url));

browser.storage.onChanged.addListener((changes, area) => {
  if (area !== "local") return;
  if (changes.values) state.values = changes.values.newValue ?? null;
  if (changes.sites) state.sites = changes.sites.newValue ?? [];
  update();
});

Promise.all([browser.storage.local.get(["values", "sites"]), findSite()]).then(([stored, site]) => {
  state.values = stored.values ?? null;
  state.sites = stored.sites ?? [];
  state.site = site;
  update();
});
