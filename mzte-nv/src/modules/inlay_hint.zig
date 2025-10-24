//! Module for inlay-hint.nvim with custom display callback.

const std = @import("std");
const opts = @import("opts");

const ser = @import("../ser.zig");
const ffi = @import("../ffi.zig");
const c = ffi.c;

pub fn luaPush(l: *c.lua_State) void {
    ser.luaPushAny(l, .{
        .min_avail_space = 12,
        .formatHints = ffi.luaFunc(lFormatHints),
    });
}

const input_arrow = "󱞦";
const output_arrow = "󱞢";
const sep = "";

fn lFormatHints(l: *c.lua_State) !c_int {
    c.luaL_checkany(l, 1); // hints
    const avail_space = c.luaL_checkinteger(l, 2);

    var arena: std.heap.ArenaAllocator = .init(std.heap.c_allocator);
    defer arena.deinit();

    const alloc = arena.allocator();

    var input_hints: std.ArrayList([]const u8) = .empty;
    var output_hints: std.ArrayList([]const u8) = .empty;

    c.lua_pushnil(l);
    while (c.lua_next(l, 1) != 0) {
        c.lua_getfield(l, -1, "label");
        if (c.lua_isstring(l, -1) == 0) {
            // TODO: support label parts:
            // https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#inlayHintLabelPart
            continue;
        }
        const label = ffi.luaToString(l, -1);
        c.lua_getfield(l, -2, "kind");
        const kind = c.lua_tointeger(l, -1);
        const label_dupe = try alloc.dupe(u8, trimHint(label));
        c.lua_pop(l, 3);

        if (kind == 1) { // 1 signifies this inlay hint is for an output parameter
            try output_hints.append(alloc, label_dupe);
        } else {
            try input_hints.append(alloc, label_dupe);
        }
    }

    var text: std.Io.Writer.Allocating = .init(alloc);

    const mode: enum { both, outputs_only, nums } = mode: {
        const inputs_len = printLengthOfHints(input_hints.items);
        const outputs_len = printLengthOfHints(output_hints.items);

        // Do we have space for everything?
        if (inputs_len + outputs_len <= avail_space) break :mode .both;

        // No space for full display, can we fit outputs?
        if (outputs_len <= avail_space) break :mode .outputs_only;

        // We can fit nums because we're always over min_avail_space
        // Formatted like: < (I) > (O)
        break :mode .nums;
    };

    switch (mode) {
        .both => {
            try writeHints(&text.writer, input_arrow, input_hints.items);
            if (output_hints.items.len > 0) {
                try text.writer.writeByte(' ');
                try writeHints(&text.writer, output_arrow, output_hints.items);
            }
        },
        .outputs_only => {
            try writeHints(&text.writer, output_arrow, output_hints.items);
        },
        .nums => {
            try text.writer.print(input_arrow ++ " ({}) " ++ output_arrow ++ " ({})", .{
                input_hints.items.len,
                output_hints.items.len,
            });
        },
    }

    if (text.written().len == 0)
        c.lua_pushnil(l)
    else
        ffi.luaPushString(l, text.written());

    return 1;
}

fn trimHint(hint: []const u8) []const u8 {
    return std.mem.trim(u8, hint, &(std.ascii.whitespace ++ .{':'}));
}

fn printLengthOfHints(hints: []const []const u8) usize {
    if (hints.len == 0) return 0;
    var len: usize = 2; // arrow and space at start
    for (hints) |h| len += h.len;
    len += hints.len; // separators and trailing space

    return len;
}

fn writeHints(writer: *std.Io.Writer, initial_sym: []const u8, hints: []const []const u8) !void {
    if (hints.len == 0) return;

    try writer.writeAll(initial_sym);
    try writer.writeByte(' ');

    for (hints, 0..) |hint, i| {
        if (i != 0) try writer.writeAll(sep);
        try writer.writeAll(hint);
    }
}
