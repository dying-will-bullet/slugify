const std = @import("std");
const testing = std.testing;
const Allocator = std.mem.Allocator;
const unicode = @import("std").unicode;

const deuni = @import("deunicode");

// --------------------------------------------------------------------------------
//                                  Private API
// --------------------------------------------------------------------------------

fn pushChar(c: u8, out: anytype, prev_is_dash: *bool, sep: []const u8) !void {
    if ((c >= 'a' and c <= 'z') or (c >= '0' and c <= '9')) {
        prev_is_dash.* = false;
        _ = try out.writeByte(c);
    } else if (c >= 'A' and c <= 'Z') {
        prev_is_dash.* = false;
        _ = try out.writeByte(c - 'A' + 'a');
    } else {
        if (!prev_is_dash.*) {
            _ = try out.write(sep);
            prev_is_dash.* = true;
        }
    }
}

// --------------------------------------------------------------------------------
//                                  Public API
// --------------------------------------------------------------------------------

pub const Dict = std.AutoHashMap(u21, []const u8);

pub const Options = struct {
    sep: []const u8 = "-",
    dict: ?Dict = null,
};

pub fn sluifyAlloc(allocator: Allocator, s: []const u8, options: Options) ![]const u8 {
    var buf = try std.ArrayList(u8).initCapacity(allocator, s.len);
    defer buf.deinit();
    var out = buf.writer();

    var prev_is_dash = true;
    var iter = (try unicode.Utf8View.init(s)).iterator();

    while (iter.nextCodepoint()) |codepoint| {
        if (options.dict != null) {
            if (options.dict.?.get(codepoint)) |repl| {
                for (repl) |c| {
                    try pushChar(c, out, &prev_is_dash, options.sep);
                }
                continue;
            }
        }
        if (codepoint < 0x7F) {
            try pushChar(@truncate(u8, codepoint), out, &prev_is_dash, options.sep);
        } else {
            const res = deuni.getReplacement(codepoint) orelse options.sep;
            for (res) |c| {
                try pushChar(c, out, &prev_is_dash, options.sep);
            }
        }
    }

    if (std.mem.endsWith(u8, buf.items, options.sep)) {
        for (0..options.sep.len) |_| {
            _ = buf.pop();
        }
    }

    return buf.toOwnedSlice();
}

pub fn sluify(dest: []u8, s: []const u8, options: Options) ![]const u8 {
    var fbs = std.io.fixedBufferStream(dest);
    var out = fbs.writer();
    var prev_is_dash = true;
    var iter = (try unicode.Utf8View.init(s)).iterator();

    while (iter.nextCodepoint()) |codepoint| {
        if (codepoint < 0x7F) {
            try pushChar(@truncate(u8, codepoint), out, &prev_is_dash, options.sep);
        } else {
            const res = deuni.getReplacement(codepoint) orelse options.sep;
            for (res) |c| {
                try pushChar(c, out, &prev_is_dash, options.sep);
            }
        }
    }

    if (std.mem.endsWith(u8, dest[0..fbs.pos], options.sep)) {
        return dest[0 .. fbs.pos - options.sep.len];
    }

    return dest[0..fbs.pos];
}

// --------------------------------------------------------------------------------
//                                   Testing
// --------------------------------------------------------------------------------

fn testConversionAlloc(s: []const u8, expect: []const u8) !bool {
    const allocator = testing.allocator;
    const res = try sluifyAlloc(allocator, s, .{});
    defer allocator.free(res);

    return std.mem.eql(u8, res, expect);
}

fn testConversion(s: []const u8, expect: []const u8) !bool {
    var buf: [1024]u8 = undefined;
    const res = try sluify(&buf, s, .{});

    return std.mem.eql(u8, res, expect);
}

test "test conversion alloc" {
    try testing.expect(try testConversionAlloc("♥", "hearts"));
    try testing.expect(try testConversionAlloc("🦊", "fox-face"));
    try testing.expect(try testConversionAlloc("  Déjà Vu!  ", "deja-vu"));
    try testing.expect(try testConversionAlloc("tôi yêu những chú kỳ lân", "toi-yeu-nhung-chu-ky-lan"));
}

test "test conversion buffer" {
    try testing.expect(try testConversion("♥", "hearts"));
    try testing.expect(try testConversion("🦊", "fox-face"));
    try testing.expect(try testConversion("  Déjà Vu!  ", "deja-vu"));
    try testing.expect(try testConversion("tôi yêu những chú kỳ lân", "toi-yeu-nhung-chu-ky-lan"));
}

test "test custom sep" {
    const allocator = testing.allocator;

    const res = try sluifyAlloc(allocator, "  Déjà Vu!  ", .{ .sep = "__" });
    defer allocator.free(res);

    try testing.expectEqualStrings("deja__vu", res);
}

test "test dict" {
    const allocator = testing.allocator;

    var dict = Dict.init(allocator);
    defer dict.deinit();

    // é
    try dict.put(233, "ee");
    // à
    try dict.put(224, "aa");

    const res = try sluifyAlloc(allocator, "  Déjà Vu!  ", .{ .dict = dict });
    defer allocator.free(res);

    try testing.expectEqualStrings("deejaa-vu", res);
}
