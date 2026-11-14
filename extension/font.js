// The kosmos' font and text stroke on a page, apart from Dark Reader so either can be off alone.
"use strict";

const kosmFont = {
  /// Elements keeping their own font: Dark Reader's list, so a page looks the same as with it.
  excluded: [
    "pre",
    "pre *",
    "code",
    '[aria-hidden="true"]',
    '[class*="fa-"]',
    ".fa",
    ".fab",
    ".fad",
    ".fal",
    ".far",
    ".fas",
    ".fass",
    ".fasr",
    ".fat",
    ".icofont",
    '[style*="font-"]',
    '[class*="icon"]',
    '[class*="Icon"]',
    '[class*="symbol"]',
    '[class*="Symbol"]',
    ".glyphicon",
    '[class*="material-symbol"]',
    '[class*="material-icon"]',
    "mu",
    '[class*="mu-"]',
    ".typcn",
    '[class*="vjs-"]',
  ],

  /// The style element this page shows, or null while none is shown.
  style: null,

  /// Shows `theme`'s `fontFamily` (when `useFont`) and `textStroke`; null or neither removes them.
  show(theme) {
    const css = theme === null ? "" : this.css(theme);
    if (css === "") {
      this.style?.remove();
      this.style = null;
      return;
    }
    if (this.style === null) {
      this.style = document.createElement("style");
      this.style.className = "kosm-font";
    }
    this.style.textContent = css;
    if (!this.style.isConnected) (document.head ?? document.documentElement).append(this.style);
  },

  /// The CSS for `theme`'s font and text stroke, or "" for neither.
  css(theme) {
    const lines = [];
    if (theme.useFont && theme.fontFamily) lines.push(`  font-family: ${theme.fontFamily} !important;`);
    if (theme.textStroke > 0) {
      lines.push(`  -webkit-text-stroke: ${theme.textStroke}px !important;`);
      lines.push(`  text-stroke: ${theme.textStroke}px !important;`);
    }
    if (lines.length === 0) return "";
    return [`*:not(${this.excluded.join(", ")}) {`, ...lines, "}"].join("\n");
  },
};
