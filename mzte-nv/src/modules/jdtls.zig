//! Module for the JDTLS java language server, including utilities
//! for setting up nvim-jdtls
const std = @import("std");
const opts = @import("opts");

const ser = @import("../ser.zig");
const ffi = @import("../ffi.zig");
const c = ffi.c;

pub fn luaPush(l: *c.lua_State) void {
    ser.luaPushAny(l, .{
        .findRuntimes = ffi.luaFunc(lFindRuntimes),
        .getBundleInfo = ffi.luaFunc(lGetBundleInfo),
        .getDirs = ffi.luaFunc(lGetDirs),
    });
}

const Runtime = struct {
    version: [:0]const u8,
    name: [:0]const u8,
};

// Name is not arbitrary and must match `enum ExecutionEnvironment`.
// See: https://github.com/eclipse-jdtls/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
const runtime_map = [_]Runtime{
    .{ .version = "19", .name = "JavaSE-19" },
    .{ .version = "18", .name = "JavaSE-18" },
    .{ .version = "17", .name = "JavaSE-17" },
    .{ .version = "16", .name = "JavaSE-16" },
    .{ .version = "15", .name = "JavaSE-15" },
    .{ .version = "14", .name = "JavaSE-14" },
    .{ .version = "13", .name = "JavaSE-13" },
    .{ .version = "12", .name = "JavaSE-12" },
    .{ .version = "11", .name = "JavaSE-11" },
    .{ .version = "10", .name = "JavaSE-10" },
    .{ .version = "9", .name = "JavaSE-9" },
    .{ .version = "8", .name = "JavaSE-1.8" },
    .{ .version = "7", .name = "JavaSE-1.7" },
    .{ .version = "6", .name = "JavaSE-1.6" },
    .{ .version = "5", .name = "J2SE-1.5" }, // probably redundant, but JDTLS supports it
};

fn lFindRuntimes(l: *c.lua_State) !c_int {
    const jvmpath = opts.jvm orelse "/usr/lib/jvm";
    var jvmdir = std.fs.openDirAbsolute(jvmpath, .{ .iterate = true }) catch |e| switch (e) {
        error.FileNotFound => {
            std.log.warn("JVM Path @ '{s}' does not exist! Not registering any runtimes!", .{jvmpath});
            c.lua_newtable(l);
            return 1;
        },
        else => return e,
    };
    defer jvmdir.close();

    c.lua_newtable(l);

    var buf: [512]u8 = undefined;
    var idx: c_int = 1;
    var iter = jvmdir.iterate();
    while (try iter.next()) |jvm| {
        if ((jvm.kind != .directory and jvm.kind != .sym_link) or
            !std.mem.startsWith(u8, jvm.name, "java-"))
            continue;

        for (runtime_map) |rt| {
            if (!std.mem.containsAtLeast(u8, jvm.name, 1, rt.version))
                continue;

            // push a table with a name field (must be a name from runtime_map)
            // and a path field (path to the runtime's home)
            ser.luaPushAny(l, .{
                .name = rt.name,
                .path = try std.fmt.bufPrintZ(&buf, jvmpath ++ "/{s}/", .{jvm.name}),
            });

            // append table to list
            c.lua_rawseti(l, -2, idx);
            idx += 1;

            break;
        }
    }

    return 1;
}

/// Returns a list of JDTLS bundles (plugins basically) and the preferred content provider
///
/// https://github.com/dgileadi/vscode-java-decompiler/tree/master/server
// TODO: add command to download these maybe?
fn lGetBundleInfo(l: *c.lua_State) !c_int {
    const home = std.posix.getenv("HOME") orelse return error.HomeNotSet;

    const bundle_path = try std.fs.path.join(
        std.heap.c_allocator,
        // I kinda made this path up, but I think it makes sense.
        &.{ home, ".eclipse", "jdtls", "bundles" },
    );
    defer std.heap.c_allocator.free(bundle_path);

    var dir = std.fs.cwd().openDir(bundle_path, .{ .iterate = true }) catch |e| {
        if (e == error.FileNotFound) {
            // Just return an empty table if the bundles dir doesn't exist
            ser.luaPushAny(l, .{
                .content_provider = .{},
                .bundles = .{},
            });
            return 1;
        }

        return e;
    };
    defer dir.close();

    // return value
    c.lua_newtable(l);

    // bundles
    c.lua_newtable(l);

    var has_cfr = false;
    var iter = dir.iterate();
    var idx: c_int = 1;
    while (try iter.next()) |f| {
        if (f.kind != .file or !std.mem.endsWith(u8, f.name, ".jar"))
            continue;

        if (!has_cfr and std.mem.containsAtLeast(u8, f.name, 1, "cfr"))
            has_cfr = true;

        const path = try std.fs.path.joinZ(std.heap.c_allocator, &.{ bundle_path, f.name });
        defer std.heap.c_allocator.free(path);

        c.lua_pushstring(l, path.ptr);
        c.lua_rawseti(l, -2, idx);
        idx += 1;
    }

    c.lua_setfield(l, -2, "bundles");

    // content_provider
    c.lua_newtable(l);

    if (has_cfr) {
        c.lua_pushstring(l, "cfr");
        c.lua_setfield(l, -2, "preferred");
    }

    c.lua_setfield(l, -2, "content_provider");

    return 1;
}

fn lGetDirs(l: *c.lua_State) !c_int {
    const home = std.posix.getenv("HOME") orelse return error.HomeNotSet;

    var cwd_buf: [256]u8 = undefined;
    const cwd_basename = std.fs.path.basename(try std.posix.getcwd(&cwd_buf));

    const config_path = try std.fs.path.joinZ(
        std.heap.c_allocator,
        &.{ home, ".cache", "jdtls", "config" },
    );
    defer std.heap.c_allocator.free(config_path);

    const workspace_path = try std.fs.path.joinZ(
        std.heap.c_allocator,
        &.{ home, ".cache", "jdtls", "workspace", cwd_basename },
    );
    defer std.heap.c_allocator.free(workspace_path);

    ser.luaPushAny(l, .{
        .config = config_path,
        .workspace = workspace_path,
    });
    return 1;
}
