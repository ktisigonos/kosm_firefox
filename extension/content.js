// Styles every page in the kosmos' colors through Dark Reader's engine and in its font, each
// unless the page's site has it toggled off. Follows every change to the values or toggles at once.
"use strict";

/// What storage holds: `values` as kosm wrote them ({ theme }), `sites` as kosmSites keeps them.
const state = { values: null, sites: [], site: null };
/// The colors and font the page shows, as JSON, or null for either while it is off.
const shown = { colors: null, font: null };

function update() {
  if (state.values === null || state.site === null) return;
  const theme = state.values.theme ?? null;
  const toggles = kosmSites.togglesOf(state.sites, state.site);
  // The font is kosmFont's alone, so Dark Reader gets the colors without it.
  const colors = theme !== null && toggles.colors ? JSON.stringify({ ...theme, useFont: false, textStroke: 0 }) : null;
  const font = theme !== null && toggles.font ? JSON.stringify(theme) : null;
  if (colors !== shown.colors) {
    // Enabling an enabled Dark Reader keeps its old colors, so it is turned off first; both happen
    // before the page paints again, so nothing flashes.
    DarkReader.disable();
    if (colors !== null) DarkReader.enable(JSON.parse(colors));
    shown.colors = colors;
  }
  if (font !== shown.font) {
    kosmFont.show(font === null ? null : theme);
    shown.font = font;
  }
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
