// Receives the values kosm wrote from the native host, keeps them in storage for every page to
// read, answers which site a frame belongs to, and forces a frame's corners. Kosm Live also has Zen's prefs set live.
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

/// Swaps the corners CSS in the sender's frame: `remove` out, then `insert` in, either null. It
/// goes in as a user stylesheet, whose `!important` wins over every page's, which a page's own
/// <style> could not.
async function forceCorners(message, sender) {
  const target = { cssOrigin: "user", frameId: sender.frameId, matchAboutBlank: true };
  try {
    if (message.remove !== null) await browser.tabs.removeCSS(sender.tab.id, { ...target, code: message.remove });
    if (message.insert !== null) await browser.tabs.insertCSS(sender.tab.id, { ...target, code: message.insert, runAt: "document_start" });
  } catch (error) {
    console.error(`kosm: cannot set the corners on ${sender.url}: ${error.message}`);
  }
}

browser.runtime.onMessage.addListener((message, sender) => {
  if (message.type === "site") return Promise.resolve(siteOf(sender.tab?.url));
  if (message.type === "corners") return forceCorners(message, sender);
  return undefined;
});

connect();
if (browser.kosmLive) browser.kosmLive.watchPrefs();
