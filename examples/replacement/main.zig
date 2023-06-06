const std = @import("std");
const slugifyAlloc = @import("slugify").slugifyAlloc;
const Dict = @import("slugify").Dict;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var dict = Dict.init(allocator);
    defer dict.deinit();

    // 128049 is the code point of 🐱
    try dict.put(128049, "neko");

    const res = try slugifyAlloc(allocator, "I love 🐱.", .{ .dict = dict });
    defer allocator.free(res);

    std.debug.print("{s}\n", .{res});
}
