// The switches for all sites, then the current tab's site, then every site switched before, the
// most recent first. Corners get a column only while kosm wrote a border radius.
"use strict";

const list = document.getElementById("sites");
const labels = { colors: "Colors", font: "Font", corners: "Corners" };

function checkbox(checked, title, onChange) {
  const toggle = document.createElement("input");
  toggle.type = "checkbox";
  toggle.checked = checked;
  toggle.title = title;
  toggle.addEventListener("change", () => onChange(toggle.checked));
  return toggle;
}

/// A row named `name`, a checkbox per shown switch, `onToggle(key, on)` called on each change.
function row(name, toggles, keys, className, onToggle) {
  const item = document.createElement("tr");
  item.className = className;
  const label = document.createElement("td");
  label.textContent = name;
  item.append(label);
  for (const key of keys) {
    const cell = document.createElement("td");
    cell.append(checkbox(toggles[key], `${labels[key]} on ${name}`, (on) => onToggle(key, on)));
    item.append(cell);
  }
  return item;
}

async function toggleGlobal(key, on) {
  const stored = await browser.storage.local.get(["global", "values"]);
  await browser.storage.local.set({ global: kosmSites.globalToggled(stored.global, stored.values, key, on) });
  await render();
}

async function toggleSite(site, key, on) {
  const stored = await browser.storage.local.get("sites");
  await browser.storage.local.set({ sites: kosmSites.toggled(stored.sites ?? [], site, key, on) });
  await render();
}

async function render() {
  const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
  let current = "";
  try {
    current = new URL(tab.url).hostname;
  } catch {}
  const stored = await browser.storage.local.get(["values", "global", "sites"]);
  const sites = stored.sites ?? [];
  const withCorners = (stored.values?.borderRadius ?? null) !== null;
  const keys = withCorners ? ["colors", "font", "corners"] : ["colors", "font"];
  document.getElementById("corners").hidden = !withCorners;
  const global = kosmSites.globalOf(stored.values, stored.global);
  const rows = [row("All sites", global, keys, "global", toggleGlobal)];
  const siteRow = (site, className) =>
    row(site, kosmSites.togglesOf(sites, site, global), keys, className, (key, on) => toggleSite(site, key, on));
  if (current !== "") rows.push(siteRow(current, "current"));
  for (const toggled of sites) {
    if (toggled.site !== current) rows.push(siteRow(toggled.site, ""));
  }
  list.replaceChildren(...rows);
}

render();
