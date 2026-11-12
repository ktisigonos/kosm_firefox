// Receives the values kosm wrote from the native host, keeps them in storage for every page to
// read, and answers which site a frame belongs to. Kosm Live also has Zen's prefs set live.
"use strict";

/// The native messaging host kosm_firefox writes the manifest of.
const host = "kosm_firefox";

function connect() {
  const port = browser.runtime.connectNative(host);
  port.onMessage.addListener((values) => browser.storage.local.set({ values }));
  port.onDisconnect.addListener((stopped) => {
    if (stopped.error) console.error(`kosm: the native host ${host} stopped: ${stopped.error.message}; pages keep the last values`);
  });
}

/// The site a toggle applies to: the host name of the tab's page, or "" for pages without one.
function siteOf(url) {
  try {
    return new URL(url).hostname;
  } catch {
    return "";
  }
}

browser.runtime.onMessage.addListener((message, sender) => {
  if (message.type === "site") return Promise.resolve(siteOf(sender.tab?.url));
  return undefined;
});

connect();
if (browser.kosmLive) browser.kosmLive.watchPrefs();
