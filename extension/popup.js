// The toggles for the current tab's site, then every site toggled before, the most recent first.
"use strict";

const list = document.getElementById("sites");

function checkbox(checked, title, onChange) {
  const toggle = document.createElement("input");
  toggle.type = "checkbox";
  toggle.checked = checked;
  toggle.title = title;
  toggle.addEventListener("change", () => onChange(toggle.checked));
  return toggle;
}

function row(site, toggles, current) {
  const item = document.createElement("tr");
  if (current) item.className = "current";
  const name = document.createElement("td");
  name.textContent = site;
  const colors = document.createElement("td");
  colors.append(checkbox(toggles.colors, `Colors on ${site}`, (on) => toggleSite(site, { ...toggles, colors: on })));
  const font = document.createElement("td");
  font.append(checkbox(toggles.font, `Font on ${site}`, (on) => toggleSite(site, { ...toggles, font: on })));
  item.append(name, colors, font);
  return item;
}

async function toggleSite(site, toggles) {
  const stored = await browser.storage.local.get("sites");
  await browser.storage.local.set({ sites: kosmSites.toggled(stored.sites ?? [], site, toggles) });
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
  if (current !== "") rows.push(row(current, kosmSites.togglesOf(sites, current), true));
  for (const toggled of sites) {
    if (toggled.site !== current) rows.push(row(toggled.site, kosmSites.togglesOf(sites, toggled.site), false));
  }
  list.replaceChildren(...rows);
}

render();
