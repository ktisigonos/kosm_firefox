//! Every Firefox-based browser through kosm's own extension: pages darkened by Dark Reader's
//! engine in the kosmos' colors and font, with per-site colors and font toggles. The extension gets the
//! values from `kosm relay`, which the browser starts while it runs, so an apply reaches open
//! pages at once. Kosm Live, the same extension able to set prefs, is installed into `live`'s
//! profiles and sets the prefs other apps (`kosm_zen`) write for it in the running browser.

const App = @This();

const std = @import("std");
const kosm = @import("kosm");

/// Dark Reader's theme for pages. Null fields are not written, so Dark Reader's own apply.
theme: Theme = .{},
/// Corners forced on pages, over each page's own, even its `!important` ones, while
/// `enabled.corners` is on. null: each page's own corners.
border_radius: ?BorderRadius = null,
/// What every site is styled with unless the toolbar button's "All sites" row or the site's own
/// row says otherwise.
enabled: Enabled = .{},
/// The kosm the browser starts as the relay; `~` is expanded. Default: `~/.local/bin/kosm`.
kosm_binary: []const u8 = "~/.local/bin/kosm",
/// Where the values, the relay's launcher and Kosm Live are written.
/// Default: `~/.local/share/kosm/firefox`.
directory: []const u8 = "~/.local/share/kosm/firefox",
/// The folders the browsers read native messaging manifests from. Default: Firefox's and
/// Zen's, `~/.mozilla/native-messaging-hosts`; LibreWolf reads `~/.librewolf/native-messaging-hosts`.
native_hosts: []const []const u8 = &.{"~/.mozilla/native-messaging-hosts"},
/// The profiles Kosm Live is installed into, with the prefs that let it load. null: none, and
/// the signed Kosm is installed by hand. `from`: every Zen profile.
live: ?Live = null,
/// How values are spelled. Null fields take the JSON adapter's, then kosm's `#rrggbb`.
format: kosm.Format = .{},

/// Dark Reader's theme. Field names are Dark Reader's, in Zig casing; null ones are not written.
pub const Theme = struct {
    /// `mode`: dark pages, or light ones dimmed. null: dark. `from`: `.dimmed` for a light theme.
    mode: ?Mode = null,
    /// `brightness`: in percent. null: 100.
    brightness: ?u16 = null,
    /// `contrast`: in percent. null: 100.
    contrast: ?u16 = null,
    /// `grayscale`: in percent, 0..100. null: 0.
    grayscale: ?u8 = null,
    /// `sepia`: in percent, 0..100. null: 0.
    sepia: ?u8 = null,
    /// `textStroke`: makes text bolder, in pixels, 0..1. null: 0.
    text_stroke: ?f32 = null,
    /// `darkSchemeBackgroundColor`: page backgrounds in dark mode. null: `#181a1b`. `from`: black.
    dark_scheme_background_color: ?kosm.Color = null,
    /// `darkSchemeTextColor`: page text in dark mode. null: `#e8e6e3`. `from`: white.
    dark_scheme_text_color: ?kosm.Color = null,
    /// `lightSchemeBackgroundColor`: page backgrounds in dimmed mode. null: `#dcdad7`. `from`: white.
    light_scheme_background_color: ?kosm.Color = null,
    /// `lightSchemeTextColor`: page text in dimmed mode. null: `#181a1b`. `from`: black.
    light_scheme_text_color: ?kosm.Color = null,
    /// `scrollbarColor`: scrollbars. null: derived from the page. `from`: the theme's
    /// `lightness.bright` of the foreground.
    scrollbar_color: ?kosm.Color = null,
    /// `selectionColor`: the background of selected text. null: derived from the page.
    /// `from`: the theme's `state.selected` of the background.
    selection_color: ?kosm.Color = null,
    /// `styleSystemControls`: also restyle buttons, fields and other native controls. null:
    /// Dark Reader's choice for the browser.
    style_system_controls: ?bool = null,
    /// `fontFamily`: the families every page is shown in, in fallback order (code and icon
    /// fonts are kept). null: each page's own fonts.
    font_family: ?[]const []const u8 = null,
};

/// Corners forced on pages.
pub const BorderRadius = struct {
    /// The radius, in pixels.
    pixels: u32,
    /// The elements that get it, a CSS selector. Default: every element but the page itself.
    selector: []const u8 = "*:not(html, body)",
};

/// The global switches, each the default of the toolbar button's "All sites" row.
pub const Enabled = struct {
    /// Pages in `theme`'s colors. Default: on.
    colors: bool = true,
    /// Pages in `theme.font_family` and `theme.text_stroke`. Default: on.
    font: bool = true,
    /// Pages with `border_radius`'s corners. Default: off, as it rounds what pages keep square
    /// on purpose.
    corners: bool = false,
};

/// Dark Reader's `mode`.
pub const Mode = enum(u1) {
    /// Light pages dimmed.
    dimmed = 0,
    /// Pages turned dark.
    dark = 1,
};

/// Where Kosm Live goes. It needs a browser that runs unsigned extensions with experiment APIs:
/// Zen does, Mozilla's own Firefox doesn't.
pub const Live = struct {
    /// The profile directories to install it into, a glob. Only directories holding a
    /// `prefs.js` count. Default: every Zen profile, `~/.zen/*`.
    profiles: []const u8 = "~/.zen/*",
    /// Profile directories to leave out, globs written like `profiles`.
    exclude: []const []const u8 = &.{},
};

/// The native messaging host's name, which the extension connects to.
const host_name = "kosm_firefox";
/// The signed extension's id, and Kosm Live's.
const extension_id = "kosm@ktisigonos";
const live_extension_id = "kosm-live@ktisigonos";
/// The id of the block kosm owns in each live profile's `user.js`.
const block_id = "firefox";

/// Kosm Live's files: its manifest and experiment, then everything it shares with Kosm.
const live_files = [_]struct { name: []const u8, content: []const u8 }{
    .{ .name = "manifest.json", .content = @embedFile("extension/live/manifest.json") },
    .{ .name = "schema.json", .content = @embedFile("extension/live/schema.json") },
    .{ .name = "api.js", .content = @embedFile("extension/live/api.js") },
    .{ .name = "background.js", .content = @embedFile("extension/background.js") },
    .{ .name = "content.js", .content = @embedFile("extension/content.js") },
    .{ .name = "sites.js", .content = @embedFile("extension/sites.js") },
    .{ .name = "font.js", .content = @embedFile("extension/font.js") },
    .{ .name = "popup.html", .content = @embedFile("extension/popup.html") },
    .{ .name = "popup.js", .content = @embedFile("extension/popup.js") },
    .{ .name = "popup.css", .content = @embedFile("extension/popup.css") },
    .{ .name = "darkreader.js", .content = @embedFile("extension/darkreader.js") },
    .{ .name = "darkreader-LICENSE", .content = @embedFile("extension/darkreader-LICENSE") },
};

/// Colors from the theme: the mode from the theme's (dark pages, or light ones dimmed for a
/// light theme), each scheme's background and text from black and white, the scrollbar and
/// selection from the foreground and background roles, and Kosm Live in every Zen profile. The
/// font is left to the page.
pub fn from(theme: kosm.Theme) App {
    const palette = theme.palette;
    return .{
        .theme = .{
            .mode = switch (theme.mode) {
                .dark => .dark,
                .light => .dimmed,
            },
            .dark_scheme_background_color = palette.black,
            .dark_scheme_text_color = palette.white,
            .light_scheme_background_color = palette.white,
            .light_scheme_text_color = palette.black,
            .scrollbar_color = theme.variations.lightness.bright.apply(theme.roles.foreground),
            .selection_color = theme.variations.state.selected.apply(theme.roles.background),
        },
        .live = .{},
    };
}

/// Writes the values, the relay's launcher and its native messaging manifests, then Kosm Live
/// and its prefs into every live profile. An `App{}` writes nothing.
pub fn apply(self: App, output: *kosm.Output) !void {
    if (self.isEmpty()) return;
    const values = try std.mem.concat(output.allocator, u8, &.{ self.directory, "/values.json" });
    try output.generate(.{ .file = values, .lang = "json", .format = self.format }, try self.valuesTable(output.allocator));

    const launcher = try std.mem.concat(output.allocator, u8, &.{ self.directory, "/relay" });
    const launcher_content = try std.mem.concat(output.allocator, u8, &.{
        "#!/bin/sh\n# Started by the browser while it runs; written by kosm.\nexec ",
        try shellQuoted(output.allocator, try expandHome(output, self.kosm_binary)),
        " relay ",
        try shellQuoted(output.allocator, try expandHome(output, values)),
        "\n",
    });
    try output.verbatim(.{ .file = launcher, .content = launcher_content, .executable = true });

    const manifest: NativeManifest = .{ .path = try expandHome(output, launcher) };
    for (self.native_hosts) |folder| {
        const file = try std.mem.concat(output.allocator, u8, &.{ std.mem.trimEnd(u8, folder, "/"), "/", host_name, ".json" });
        try output.generate(.{ .file = file, .lang = "json" }, manifest);
    }

    if (self.live) |live| try self.writeLive(output, live);
}

fn isEmpty(self: App) bool {
    if (self.live != null or self.border_radius != null) return false;
    if (!std.meta.eql(self.enabled, Enabled{})) return false;
    inline for (@typeInfo(Theme).@"struct".field_names) |name| {
        if (@field(self.theme, name) != null) return false;
    }
    return true;
}

/// What `values.json` holds: `{ "theme": ..., "enabled": ... }`, Dark Reader's theme with its own
/// names and the global switches, and with `border_radius` `"borderRadius": { "pixels": ...,
/// "selector": ... }`.
fn valuesTable(self: App, allocator: std.mem.Allocator) !kosm.Value {
    var entries: std.ArrayList(kosm.Value.Entry) = .empty;
    const fields = @typeInfo(Theme).@"struct";
    inline for (fields.field_names) |name| {
        if (@field(self.theme, name)) |value| {
            const key = comptime camelCase(name);
            if (comptime std.mem.eql(u8, name, "font_family")) {
                try entries.append(allocator, .{ .key = "useFont", .value = .{ .boolean = true } });
                try entries.append(allocator, .{ .key = key, .value = .{ .string = try cssFamilies(allocator, value) } });
            } else if (comptime std.mem.eql(u8, name, "mode")) {
                try entries.append(allocator, .{ .key = key, .value = .{ .integer = @backingInt(value) } });
            } else {
                try entries.append(allocator, .{ .key = key, .value = switch (@TypeOf(value)) {
                    kosm.Color => .{ .color = value },
                    bool => .{ .boolean = value },
                    f32 => .{ .float = value },
                    u8, u16 => .{ .integer = value },
                    else => comptime unreachable,
                } });
            }
        }
    }
    var root: std.ArrayList(kosm.Value.Entry) = .empty;
    try root.append(allocator, .{ .key = "theme", .value = .{ .table = entries.items } });
    var enabled: std.ArrayList(kosm.Value.Entry) = .empty;
    inline for (@typeInfo(Enabled).@"struct".field_names) |name| {
        try enabled.append(allocator, .{ .key = name, .value = .{ .boolean = @field(self.enabled, name) } });
    }
    try root.append(allocator, .{ .key = "enabled", .value = .{ .table = enabled.items } });
    if (self.border_radius) |border_radius| {
        const radius = try allocator.dupe(kosm.Value.Entry, &.{
            .{ .key = "pixels", .value = .{ .integer = border_radius.pixels } },
            .{ .key = "selector", .value = .{ .string = border_radius.selector } },
        });
        try root.append(allocator, .{ .key = "borderRadius", .value = .{ .table = radius } });
    }
    return .{ .table = root.items };
}

/// Writes Kosm Live's files, and into every live profile the file that installs it and the prefs
/// that let it load.
fn writeLive(self: App, output: *kosm.Output, live: Live) !void {
    const folder = try std.mem.concat(output.allocator, u8, &.{ self.directory, "/live" });
    for (live_files) |file| {
        try output.verbatim(.{ .file = try std.mem.concat(output.allocator, u8, &.{ folder, "/", file.name }), .content = file.content });
    }
    const proxy = try std.mem.concat(output.allocator, u8, &.{ try expandHome(output, folder), "\n" });
    const exclude = try output.allocator.alloc([]const u8, live.exclude.len);
    for (live.exclude, exclude) |directory, *file| file.* = try prefsFile(output.allocator, directory);
    const found = try output.find(.{ .files = try prefsFile(output.allocator, live.profiles), .exclude = exclude });
    for (found) |prefs_js| {
        const profile = std.Io.Dir.path.dirname(prefs_js).?;
        try output.verbatim(.{ .file = try std.mem.concat(output.allocator, u8, &.{ profile, "/extensions/", live_extension_id }), .content = proxy });
        const user_js = try std.mem.concat(output.allocator, u8, &.{ profile, "/user.js" });
        try output.block(.{ .file = user_js, .id = block_id, .lang = "userjs" }, live_prefs);
    }
}

/// The prefs Kosm Live needs: unsigned extensions, experiment APIs, and extensions in the
/// profile's folder loading without a prompt.
const live_prefs: kosm.Value = .{
    .table = &.{
        .{ .key = "xpinstall.signatures.required", .value = .{ .boolean = false } },
        .{ .key = "extensions.experiments.enabled", .value = .{ .boolean = true } },
        // Every install scope but the profile's own stays disabled until the user enables it.
        .{ .key = "extensions.autoDisableScopes", .value = .{ .integer = 14 } },
    },
};

/// The native messaging manifest pointing the browser at the relay's launcher.
const NativeManifest = struct {
    name: []const u8 = host_name,
    description: []const u8 = "kosm relay: the values kosm wrote, for kosm's browser extension",
    /// The launcher, absolute.
    path: []const u8,
    type: []const u8 = "stdio",
    allowed_extensions: []const []const u8 = &.{ extension_id, live_extension_id },
};

/// `path` with a leading `~` made the home directory, as the browser and the shell need it.
fn expandHome(output: *kosm.Output, path: []const u8) ![]const u8 {
    if (std.mem.eql(u8, path, "~")) return output.home;
    if (std.mem.startsWith(u8, path, "~/")) return std.mem.concat(output.allocator, u8, &.{ output.home, path[1..] });
    return path;
}

/// `text` in single quotes for `sh`, each `'` written as `'\''`.
fn shellQuoted(allocator: std.mem.Allocator, text: []const u8) ![]const u8 {
    var quoted: std.ArrayList(u8) = .empty;
    try quoted.append(allocator, '\'');
    for (text) |character| {
        if (character == '\'') try quoted.appendSlice(allocator, "'\\''") else try quoted.append(allocator, character);
    }
    try quoted.append(allocator, '\'');
    return quoted.items;
}

/// Families as a CSS `font-family` list: each quoted, `"` and `\` escaped, joined by `, `.
fn cssFamilies(allocator: std.mem.Allocator, families: []const []const u8) ![]const u8 {
    var list: std.ArrayList(u8) = .empty;
    for (families, 0..) |family, index| {
        if (index != 0) try list.appendSlice(allocator, ", ");
        try list.append(allocator, '"');
        for (family) |character| {
            if (character == '"' or character == '\\') try list.append(allocator, '\\');
            try list.append(allocator, character);
        }
        try list.append(allocator, '"');
    }
    return list.items;
}

/// The `prefs.js` Firefox keeps in every profile directory `directories` picks.
fn prefsFile(allocator: std.mem.Allocator, directories: []const u8) std.mem.Allocator.Error![]const u8 {
    return std.mem.concat(allocator, u8, &.{ std.mem.trimEnd(u8, directories, "/"), "/prefs.js" });
}

/// `dark_scheme_text_color` as Dark Reader spells it: `darkSchemeTextColor`.
fn camelCase(comptime snake: []const u8) []const u8 {
    comptime var camel: []const u8 = "";
    comptime var upper = false;
    inline for (snake) |character| {
        if (character == '_') {
            upper = true;
            continue;
        }
        camel = camel ++ &[_]u8{if (upper) std.ascii.toUpper(character) else character};
        upper = false;
    }
    return camel;
}

const testing = std.testing;
const json = @import("kosm_json");
const userjs = @import("kosm_userjs");

const Fixture = struct {
    tmp: testing.TmpDir,
    arena: std.heap.ArenaAllocator,
    plan: kosm.Plan,
    diagnostics: kosm.Diagnostics = .{},
    warnings: kosm.Warnings = undefined,
    home_buffer: [std.Io.Dir.max_path_bytes]u8 = undefined,
    output: kosm.Output = undefined,

    /// `profiles` are Zen profile folders made under `~/.zen`, each with a `prefs.js`.
    fn init(fixture: *Fixture, profiles: []const []const u8) !void {
        fixture.* = .{ .tmp = testing.tmpDir(.{}), .arena = .init(testing.allocator), .plan = .init(testing.allocator, testing.io) };
        for (profiles) |profile| {
            const prefs = try std.mem.concat(fixture.arena.allocator(), u8, &.{ ".zen/", profile, "/prefs.js" });
            try fixture.tmp.dir.createDirPath(testing.io, std.Io.Dir.path.dirname(prefs).?);
            try fixture.tmp.dir.writeFile(testing.io, .{ .sub_path = prefs, .data = "" });
        }
        fixture.warnings = .init(fixture.arena.allocator());
        const length = try fixture.tmp.dir.realPath(testing.io, &fixture.home_buffer);
        fixture.output = .{
            .allocator = fixture.arena.allocator(),
            .home = fixture.home_buffer[0..length],
            .adapters = &.{ json.adapter, userjs.adapter },
            .plan = &fixture.plan,
            .diagnostics = &fixture.diagnostics,
            .warnings = &fixture.warnings,
            .app = "browser.firefox",
        };
    }

    fn deinit(fixture: *Fixture) void {
        fixture.plan.deinit();
        fixture.arena.deinit();
        fixture.tmp.cleanup();
    }

    /// The planned file at `relative`, under the home directory.
    fn file(fixture: *Fixture, relative: []const u8) !*const kosm.Plan.File {
        const path = try std.Io.Dir.path.join(fixture.arena.allocator(), &.{ fixture.output.home, relative });
        return fixture.plan.find(path) orelse {
            std.debug.print("not planned: {s}\n", .{relative});
            return error.TestUnexpectedResult;
        };
    }
};

const test_theme = kosm.Theme.from(.{ .palette = .{ .black = kosm.hex("041c26"), .white = kosm.hex("a3c5cc") }, .mode = .dark });

test "App{} writes nothing" {
    var fixture: Fixture = undefined;
    try fixture.init(&.{});
    defer fixture.deinit();
    const empty: App = .{};
    try empty.apply(&fixture.output);
    try testing.expectEqual(0, fixture.plan.files.items.len);
}

test "the values are Dark Reader's theme by its own names, the font a quoted CSS list" {
    var fixture: Fixture = undefined;
    try fixture.init(&.{});
    defer fixture.deinit();
    var app = from(test_theme);
    app.live = null;
    app.theme.scrollbar_color = kosm.hex("b7dce5");
    app.theme.selection_color = null;
    app.theme.mode = .dimmed;
    app.theme.brightness = 110;
    app.theme.text_stroke = 0.5;
    app.theme.font_family = &.{ "Maple \"Mono\"", "sans-serif" };
    try app.apply(&fixture.output);
    try testing.expectEqualStrings(
        \\{
        \\  "theme": {
        \\    "mode": 0,
        \\    "brightness": 110,
        \\    "textStroke": 0.5,
        \\    "darkSchemeBackgroundColor": "#041c26",
        \\    "darkSchemeTextColor": "#a3c5cc",
        \\    "lightSchemeBackgroundColor": "#a3c5cc",
        \\    "lightSchemeTextColor": "#041c26",
        \\    "scrollbarColor": "#b7dce5",
        \\    "useFont": true,
        \\    "fontFamily": "\"Maple \\\"Mono\\\"\", \"sans-serif\""
        \\  },
        \\  "enabled": {
        \\    "colors": true,
        \\    "font": true,
        \\    "corners": false
        \\  }
        \\}
        \\
    , (try fixture.file(".local/share/kosm/firefox/values.json")).new);
}

test "a border radius and the switches are written beside the theme, and alone are enough to write the values" {
    var fixture: Fixture = undefined;
    try fixture.init(&.{});
    defer fixture.deinit();
    const app: App = .{ .border_radius = .{ .pixels = 8 }, .enabled = .{ .font = false, .corners = true } };
    try app.apply(&fixture.output);
    try testing.expectEqualStrings(
        \\{
        \\  "theme": {},
        \\  "enabled": {
        \\    "colors": true,
        \\    "font": false,
        \\    "corners": true
        \\  },
        \\  "borderRadius": {
        \\    "pixels": 8,
        \\    "selector": "*:not(html, body)"
        \\  }
        \\}
        \\
    , (try fixture.file(".local/share/kosm/firefox/values.json")).new);
}

test "a light theme dims light pages, a dark one turns them dark" {
    try testing.expectEqual(.dark, from(test_theme).theme.mode);
    var light = test_theme;
    light.mode = .light;
    try testing.expectEqual(.dimmed, from(light).theme.mode);
}

test "the browser starts the relay through an executable launcher its native manifest names" {
    var fixture: Fixture = undefined;
    try fixture.init(&.{});
    defer fixture.deinit();
    var app = from(test_theme);
    app.live = null;
    app.kosm_binary = "/opt/it's/kosm";
    app.native_hosts = &.{ "~/.mozilla/native-messaging-hosts", "~/.librewolf/native-messaging-hosts/" };
    try app.apply(&fixture.output);
    const home = fixture.output.home;
    const launcher = try fixture.file(".local/share/kosm/firefox/relay");
    try testing.expect(launcher.executable);
    const expected_launcher = try std.mem.concat(fixture.arena.allocator(), u8, &.{
        "#!/bin/sh\n# Started by the browser while it runs; written by kosm.\nexec '/opt/it'\\''s/kosm' relay '",
        home,
        "/.local/share/kosm/firefox/values.json'\n",
    });
    try testing.expectEqualStrings(expected_launcher, launcher.new);
    for ([_][]const u8{ ".mozilla/native-messaging-hosts/kosm_firefox.json", ".librewolf/native-messaging-hosts/kosm_firefox.json" }) |relative| {
        const manifest = try std.json.parseFromSlice(struct { name: []const u8, path: []const u8, type: []const u8, allowed_extensions: []const []const u8 }, fixture.arena.allocator(), (try fixture.file(relative)).new, .{ .ignore_unknown_fields = true });
        try testing.expectEqualStrings("kosm_firefox", manifest.value.name);
        try testing.expectEqualStrings(try std.mem.concat(fixture.arena.allocator(), u8, &.{ home, "/.local/share/kosm/firefox/relay" }), manifest.value.path);
        try testing.expectEqualStrings("stdio", manifest.value.type);
        try testing.expectEqual(2, manifest.value.allowed_extensions.len);
    }
}

test "Kosm Live and the prefs it needs go into every live profile but the excluded" {
    var fixture: Fixture = undefined;
    try fixture.init(&.{ "a.default", "b.work" });
    try fixture.tmp.dir.createDirPath(testing.io, ".zen/Crash Reports");
    defer fixture.deinit();
    var app = from(test_theme);
    app.live.?.exclude = &.{"~/.zen/*.work"};
    try app.apply(&fixture.output);
    const folder = try std.mem.concat(fixture.arena.allocator(), u8, &.{ fixture.output.home, "/.local/share/kosm/firefox/live\n" });
    try testing.expectEqualStrings(folder, (try fixture.file(".zen/a.default/extensions/kosm-live@ktisigonos")).new);
    try testing.expectEqualStrings(@embedFile("extension/live/api.js"), (try fixture.file(".local/share/kosm/firefox/live/api.js")).new);
    try testing.expectEqualStrings(@embedFile("extension/live/manifest.json"), (try fixture.file(".local/share/kosm/firefox/live/manifest.json")).new);
    const user_js = (try fixture.file(".zen/a.default/user.js")).new;
    for ([_][]const u8{
        "user_pref(\"xpinstall.signatures.required\", false);",
        "user_pref(\"extensions.experiments.enabled\", true);",
        "user_pref(\"extensions.autoDisableScopes\", 14);",
    }) |line| try testing.expect(std.mem.find(u8, user_js, line) != null);
    const work = try std.Io.Dir.path.join(fixture.arena.allocator(), &.{ fixture.output.home, ".zen/b.work/user.js" });
    try testing.expectEqual(null, fixture.plan.find(work));
}

test "Kosm Live's manifest is Kosm's but for its name, id, description and experiment" {
    const allocator = testing.allocator;
    const kosm_manifest = try std.json.parseFromSlice(std.json.Value, allocator, @embedFile("extension/manifest.json"), .{});
    defer kosm_manifest.deinit();
    const live_manifest = try std.json.parseFromSlice(std.json.Value, allocator, @embedFile("extension/live/manifest.json"), .{});
    defer live_manifest.deinit();
    var live = try live_manifest.value.object.clone(allocator);
    defer live.deinit(allocator);
    const own = kosm_manifest.value.object;
    try testing.expect(live.orderedRemove("experiment_apis"));
    for ([_][]const u8{ "name", "description" }) |key| try live.put(allocator, key, own.get(key).?);
    const live_id = live.get("browser_specific_settings").?.object.get("gecko").?.object.get("id").?.string;
    try testing.expectEqualStrings(live_extension_id, live_id);
    const own_id = own.get("browser_specific_settings").?.object.get("gecko").?.object.get("id").?.string;
    try testing.expectEqualStrings(extension_id, own_id);

    var live_text: std.Io.Writer.Allocating = .init(allocator);
    defer live_text.deinit();
    try std.json.Stringify.value(std.json.Value{ .object = live }, .{}, &live_text.writer);
    const with_own_id = try std.mem.replaceOwned(u8, allocator, live_text.written(), live_extension_id, extension_id);
    defer allocator.free(with_own_id);
    var own_text: std.Io.Writer.Allocating = .init(allocator);
    defer own_text.deinit();
    try std.json.Stringify.value(kosm_manifest.value, .{}, &own_text.writer);
    try testing.expectEqualStrings(own_text.written(), with_own_id);
}
