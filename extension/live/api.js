// Kosm Live's privileged part: sets the prefs kosm wrote to the profile's kosm-live.json in the
// running browser, flips the prefs that tell the browser to re-read them (Zen rebuilds its mods),
// then calls the window methods that recompute what the browser derives from them at startup.
// Only browsers that let unsigned extensions use experiment APIs run it.
"use strict";

const { setInterval, clearInterval, setTimeout } = ChromeUtils.importESModule("resource://gre/modules/Timer.sys.mjs");

/// How often the file is checked for a change, in milliseconds.
const checkIntervalMilliseconds = 500;

/// How long after a change the windows are repainted, in milliseconds: long enough for pages to
/// have taken their new colors, which reach them through the other half of the extension.
const repaintDelayMilliseconds = 1000;

/// Sets `value` as pref `name` unless it already holds it. True when it changed.
function setPref(name, value) {
  const prefs = Services.prefs;
  switch (typeof value) {
    case "boolean":
      if (prefs.getPrefType(name) === prefs.PREF_BOOL && prefs.getBoolPref(name) === value) return false;
      prefs.setBoolPref(name, value);
      return true;
    case "number":
      if (!Number.isInteger(value)) throw new Error(`kosm-live.json: ${name}: ${value} is not an integer`);
      if (prefs.getPrefType(name) === prefs.PREF_INT && prefs.getIntPref(name) === value) return false;
      prefs.setIntPref(name, value);
      return true;
    case "string":
      if (prefs.getPrefType(name) === prefs.PREF_STRING && prefs.getStringPref(name) === value) return false;
      prefs.setStringPref(name, value);
      return true;
    default:
      throw new Error(`kosm-live.json: ${name}: a pref is a boolean, an integer or a string`);
  }
}

/// A window method named as `object.method`, such as `gZenThemePicker.handleDarkModeChange`.
const windowMethodPattern = /^([A-Za-z_$][\w$]*)\.([A-Za-z_$][\w$]*)$/;

/// Calls the method named `name` (`object.method`) on every browser window that has it.
function callInWindows(name) {
  const match = windowMethodPattern.exec(name);
  if (!match) throw new Error(`${name} is not a window method named as object.method`);
  const [, object, method] = match;
  for (const window of Services.wm.getEnumerator("navigator:browser")) {
    const target = window[object];
    if (typeof target?.[method] === "function") target[method]();
  }
}

/// Repaints every browser window as a whole once. A page turning translucent can otherwise stay
/// drawn opaque until the window is refocused, as the browser keeps the window's opaque area: a
/// near-1 opacity on the window's root for two frames makes it recompute that area.
function repaintWindows() {
  for (const window of Services.wm.getEnumerator("navigator:browser")) {
    const style = window.document.documentElement.style;
    if (style.getPropertyValue("opacity") !== "") continue;
    style.setProperty("opacity", "0.999");
    window.requestAnimationFrame(() => window.requestAnimationFrame(() => style.removeProperty("opacity")));
  }
}

/// Sets every pref of `live` ({ prefs, flip, call }), then flips `flip` and calls `call` once
/// something changed or on the first read, so the browser picks up files kosm wrote while it was
/// closed too.
function apply(live, first) {
  let changed = false;
  for (const [name, value] of Object.entries(live.prefs ?? {})) {
    try {
      if (setPref(name, value)) changed = true;
    } catch (error) {
      console.error(`kosm: cannot set pref ${name}: ${error.message}`);
    }
  }
  if (!changed && !first) return;
  for (const name of live.flip ?? []) Services.prefs.setBoolPref(name, !Services.prefs.getBoolPref(name, false));
  for (const name of live.call ?? []) {
    try {
      callInWindows(name);
    } catch (error) {
      console.error(`kosm: cannot call ${name}: ${error.message}`);
    }
  }
  setTimeout(repaintWindows, repaintDelayMilliseconds);
}

this.kosmLive = class extends ExtensionAPI {
  onShutdown() {
    if (this.timer !== undefined) clearInterval(this.timer);
  }

  getAPI() {
    const api = this;
    return {
      kosmLive: {
        watchPrefs() {
          if (api.timer !== undefined) return;
          const file = PathUtils.join(PathUtils.profileDir, "kosm-live.json");
          let seen = null;
          let checking = false;
          const check = async () => {
            if (checking) return;
            checking = true;
            try {
              const stat = await IOUtils.stat(file);
              const stamp = `${stat.lastModified} ${stat.size}`;
              if (stamp === seen) return;
              const first = seen === null;
              seen = stamp;
              apply(await IOUtils.readJSON(file), first);
            } catch (error) {
              if (error.name !== "NotFoundError") console.error(`kosm: cannot read ${file}: ${error.message}`);
            } finally {
              checking = false;
            }
          };
          check();
          api.timer = setInterval(check, checkIntervalMilliseconds);
        },
      },
    };
  }
};
