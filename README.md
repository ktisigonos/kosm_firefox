# kosm_firefox

Firefox-based browsers for kosm: every page darkened by Dark Reader's engine in the kosmos'
colors and font, through kosm's own extension, and changed at once by every apply.

- **Kosm** (`extension/`) styles pages: Dark Reader's engine in the values kosm wrote, optionally
  corners forced to one radius, and a toolbar button with a colors, a font and (while corners are
  forced) a corners switch for the current site and every site switched before. Corners are off
  on every site until switched on there.
  It can be signed for Mozilla's Firefox, but isn't yet.
- **Kosm Live** (`extension/live/`) is Kosm plus an experiment API: it also sets the prefs other
  apps write for it in the running browser, and calls the window methods they name to recompute
  what the browser derives from those prefs. `kosm_zen` writes its prefs for it, so Zen's own UI
  (the kosm mod's colors, the accent) changes at once too, just as after a restart. Experiment APIs need a browser
  that runs unsigned extensions using them, such as Zen; Mozilla's Firefox won't load it.

Nothing of kosm runs while the browser is closed: the browser starts `kosm relay` while it
runs, which sends the values file to the extension now and whenever an apply changes it.

## What it writes

- `~/.local/share/kosm/firefox/values.json`: Dark Reader's theme, and the forced border radius.
- `~/.local/share/kosm/firefox/relay`: the script the browser starts, running `kosm relay`.
- `~/.mozilla/native-messaging-hosts/kosm_firefox.json`: tells Firefox and Zen where the relay is.
- With `live`: Kosm Live in `~/.local/share/kosm/firefox/live/`, and in every live profile a file
  `extensions/kosm-live@ktisigonos` installing it plus a `// kosm:begin firefox` block in
  `user.js` with the prefs it needs: unsigned extensions allowed
  (`xpinstall.signatures.required`), experiment APIs on (`extensions.experiments.enabled`), and
  extensions in the profile's own folder loading without a prompt
  (`extensions.autoDisableScopes` = 14). Anything able to write into your profile could already
  change its `user.js`, so these open nothing new to it.

After the first apply, restart the browser once; Kosm Live shows up in its add-ons. If you used
Dark Reader or a Stylus font style, remove them.

## Fields

| Field | Default |
|---|---|
| `theme.mode` | null: dark; `.dimmed` dims light pages instead; `from`: `.dark`, or `.dimmed` for a light theme |
| `theme.brightness`, `theme.contrast` | null: 100 (percent) |
| `theme.grayscale`, `theme.sepia` | null: 0 (percent) |
| `theme.text_stroke` | null: 0 (pixels, 0..1) |
| `theme.dark_scheme_background_color` | null: Dark Reader's `#181a1b`; `from`: black |
| `theme.dark_scheme_text_color` | null: `#e8e6e3`; `from`: white |
| `theme.light_scheme_background_color` | null: `#dcdad7`; `from`: white |
| `theme.light_scheme_text_color` | null: `#181a1b`; `from`: black |
| `theme.scrollbar_color` | null: from the page; `from`: the theme's `lightness.bright` of the foreground |
| `theme.selection_color` | null: from the page; `from`: the theme's `state.selected` of the background |
| `theme.style_system_controls` | null: Dark Reader's choice |
| `theme.font_family` | null: each page's fonts; families in fallback order |
| `border_radius` | null: each page's own corners; `.{ .pixels = 8 }` forces 8px on the sites switched on in the toolbar button, over even their `!important` corners |
| `border_radius.selector` | `*:not(html, body)`: every element but the page itself; any CSS selector |
| `kosm_binary` | `~/.local/bin/kosm` |
| `directory` | `~/.local/share/kosm/firefox` |
| `native_hosts` | `~/.mozilla/native-messaging-hosts` (LibreWolf: add `~/.librewolf/native-messaging-hosts`) |
| `live` | null: no Kosm Live; `from`: `.{}` |
| `live.profiles` | `~/.zen/*` |
| `live.exclude` | none |
| `format` | `.{}`: the JSON adapter's, then `#rrggbb` |

An `App{}` writes nothing.

## Dark Reader

`extension/darkreader.js` is the npm package `darkreader` 4.9.135 (MIT, `extension/darkreader-LICENSE`),
unchanged. The engine has none of the Dark Reader extension's per-site fixes, so a few sites look
worse than with the extension; switch their colors off with the toolbar button.

## Corners

Corners are opt-in: a site keeps its own until you tick Corners for it in the toolbar button. The
border radius then goes into each of its frames as a user stylesheet, so it wins over every page's own
corners. It also rounds what a page keeps square or round on purpose (circular avatars become
rounded squares); narrow `selector`, or switch corners off for the site again.
Elements inside shadow roots keep their own corners.
