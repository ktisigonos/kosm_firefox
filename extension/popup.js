// The toggle for the current tab's site, then every site toggled before, the most recent first.
"use strict";

const list = document.getElementById("sites");

function row(site, on, current) {
  const item = document.createElement("li");
  const label = document.createElement("label");
  const toggle = document.createElement("input");
  toggle.type = "checkbox";
  toggle.checked = on;
  toggle.addEventListener("change", () => toggleSite(site, toggle.checked));
  const name = document.createElement("span");
  name.textContent = site;
  if (current) item.className = "current";
  label.append(toggle, name);
  item.append(label);
  return item;
}

async function toggleSite(site, on) {
  const stored = await browser.storage.local.get("sites");
  await browser.storage.local.set({ sites: kosmSites.toggled(stored.sites ?? [], site, on) });
  await render();
}

async function render() {
  const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
  let current = "";
  try {
    current = new URL(tab.url).hostname;
  } catch {}
  const sites = (await browser.storage.local.get("sites")).sites ?? [];
  const rows = [];
  if (current !== "") rows.push(row(current, kosmSites.isOn(sites, current), true));
  for (const toggled of sites) {
    if (toggled.site !== current) rows.push(row(toggled.site, toggled.on, false));
  }
  list.replaceChildren(...rows);
}

render();
