// Kosm Live's privileged part: sets the prefs kosm wrote to the profile's kosm-live.json in the
// running browser, then flips the prefs that tell the browser to re-read them (Zen rebuilds its
// mods). Only browsers that let unsigned extensions use experiment APIs run it.
"use strict";

const { setInterval, clearInterval } = ChromeUtils.importESModule("resource://gre/modules/Timer.sys.mjs");

/// How often the file is checked for a change, in milliseconds.
const checkIntervalMilliseconds = 500;

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

/// Sets every pref of `live` ({ prefs, flip }), then flips `flip` once something changed or on the
/// first read, so the browser picks up files kosm wrote while it was closed too.
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
