<h1 align="center"> slugify 🐌 </h1>

[![CI](https://github.com/dying-will-bullet/slugify/actions/workflows/ci.yaml/badge.svg)](https://github.com/dying-will-bullet/slugify/actions/workflows/ci.yaml)
![](https://img.shields.io/badge/language-zig-%23ec915c)

Small utility library for generating ASCII string from a Unicode string. It could handle most major languages and emojis.

## Examples

```zig
const std = @import("std");
const slugify = @import("slugify").slugify;
const slugifyAlloc = @import("slugify").slugifyAlloc;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const res = try slugifyAlloc(allocator, "  Déjà Vu!  ", .{});
    defer allocator.free(res);
    std.debug.print("{s}\n", .{res});  // deja-vu

    // Or use a buffer
    var buf: [1024]u8 = undefined;
    const res2 = try slugify(&buf, "𝒔𝒍𝒖𝒈𝒊𝒇𝒚 𝒂 𝒔𝒕𝒓𝒊𝒏𝒈", .{});
    std.debug.print("{s}\n", .{res2});  // slugify-a-string
}
```

## API

### `Options`

Used to control the conversion behavior, with the following default values.

```zig
const Dict = std.AutoHashMap(u21, []const u8);

const Options = struct {
    sep: []const u8 = "-",
    dict: ?Dict = null,
};
```

`dict`: Add your own custom replacements. The replacements are run on the original string **before** any other transformations.

```zig
var dict = Dict.init(allocator);
defer dict.deinit();

// 128049 is the code point of 🐱
try dict.put(128049, "neko");

const res = try slugifyAlloc(allocator, "I love 🐱.", .{ .dict = dict });  // i-love-neko
defer allocator.free(res);
```

### `slugifyAlloc(allocator: Allocator, s: []const u8, options: Options) ![]const u8`

Return the converted string. The caller is should free the memory.

### `slugify(dest: []u8, s: []const u8, options: Options) ![]const u8`

Use buffer instead of allocator. Return a slice of the buffer.

## LICENSE

MIT License Copyright (c) 2023, Hanaasagi
