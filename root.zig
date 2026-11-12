//! Firefox-based browsers: pages in the kosmos' colors and font through kosm's own extension,
//! live on every apply, and Kosm Live setting other apps' prefs in a running browser.

const std = @import("std");

/// The extension's values, the relay and Kosm Live; build one with `from`.
pub const App = @import("App.zig");
/// Colors from the theme, and Kosm Live in every Zen profile.
pub const from = App.from;
/// The adapter the values and the native messaging manifest are written with, so a config
/// needs only this package for the extension.
pub const json_adapter = @import("kosm_json").adapter;
/// The adapter Kosm Live's prefs are written with.
pub const userjs_adapter = @import("kosm_userjs").adapter;

test {
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(App);
}
