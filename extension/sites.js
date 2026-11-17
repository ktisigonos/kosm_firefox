// The switches, shared by pages and the popup: colors, font and corners. Kosm's `enabled` sets
// each for all sites; storage key "global" overrides those, and key "sites" every site switched
// on its own, the most recent first, each as { site, colors?, font?, corners? }.
"use strict";

const kosmSites = {
  /// Every switch, each with what it is when kosm wrote no `enabled` for it.
  defaults: { colors: true, font: true, corners: false },

  /// The switches kosm wrote: `values.enabled` filled from the defaults.
  configuredOf(values) {
    return this.each((key) => values?.enabled?.[key] ?? this.defaults[key]);
  },

  /// The switches every site follows: `global`'s overrides over kosm's.
  globalOf(values, global) {
    const configured = this.configuredOf(values);
    return this.each((key) => global?.[key] ?? configured[key]);
  },

  /// What kosm styles on `site`: its own switches over `globalToggles`.
  togglesOf(sites, site, globalToggles) {
    const entry = sites.find((toggled) => toggled.site === site);
    // Entries stored before the separate switches hold a single `on` for colors and font.
    return this.each((key) => entry?.[key] ?? (key === "corners" ? undefined : entry?.on) ?? globalToggles[key]);
  },

  /// `sites` with `site`'s `key` set to `on` and the site moved to the front.
  toggled(sites, site, key, on) {
    const entry = sites.find((toggled) => toggled.site === site) ?? { site };
    return [{ ...entry, [key]: on }, ...sites.filter((toggled) => toggled.site !== site)];
  },

  /// `global` with `key` set to `on`; set back to what kosm wrote, it follows kosm again.
  globalToggled(global, values, key, on) {
    const { [key]: _, ...others } = global ?? {};
    return on === this.configuredOf(values)[key] ? others : { ...others, [key]: on };
  },

  /// { colors, font, corners }, each `valueOf` its name.
  each(valueOf) {
    return Object.fromEntries(Object.keys(this.defaults).map((key) => [key, valueOf(key)]));
  },
};
