const std = @import("std");
const slugify = @import("slugify").slugify;
const slugifyAlloc = @import("slugify").slugifyAlloc;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const res = try slugifyAlloc(allocator, "  Déjà Vu!  ", .{});
    defer allocator.free(res);

    std.debug.print("{s}\n", .{res});

    // Or use a buffer
    var buf: [1024]u8 = undefined;
    const res2 = try slugify(&buf, "🌿🐌🌲", .{});
    std.debug.print("{s}\n", .{res2});
}
