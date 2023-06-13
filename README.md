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

## Installation

You can install it using a package manager or manually as shown below.

Add `slugify` as dependency in `build.zig.zon`:

```
.{
    .name = "my-project",
    .version = "0.1.0",
    .dependencies = .{
       .slugify = .{
           .url = "https://github.com/dying-will-bullet/slugify/archive/refs/tags/v0.1.0.tar.gz",
           .hash = "12208e86bbf6970f74f85859cc90a601d6cb381ef8637b0aa7901647750bafa6ac8c",
       },
    },
}
```

Add `slugify` as module in `build.zig`:

```diff
diff --git a/build.zig b/build.zig
index 60fb4c2..0255ef3 100644
--- a/build.zig
+++ b/build.zig
@@ -15,6 +15,9 @@ pub fn build(b: *std.Build) void {
     // set a preferred release mode, allowing the user to decide how to optimize.
     const optimize = b.standardOptimizeOption(.{});

+    const opts = .{ .target = target, .optimize = optimize };
+    const slugify_module = b.dependency("slugify", opts).module("slugify");
+
     const exe = b.addExecutable(.{
         .name = "m",
         // In this case the main source file is merely a path, however, in more
@@ -23,6 +26,7 @@ pub fn build(b: *std.Build) void {
         .target = target,
         .optimize = optimize,
     });
+    exe.addModule("slugify", slugify_module);

     // This declares intent for the executable to be installed into the
     // standard location when the user invokes the "install" step (the default
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

## slugify implementations in different languages

It is important to note that there is no universal standard for converting a Unicode character to an ASCII string.
The same Han character may have different transliterations in different languages.
For example, in Japanese, "世界" is transliterated as "sekai," while in Chinese, it is transliterated as "shijie".
This complexity also applies to emojis. For instance, the ♥ emoji can represent "love" or "heart" depending on the context.

Different implementations may use different mapping table, and I cannot guarantee that their results will be the same.
Here are slugify implementations in other languages:

- Java: [slugify/slugify](https://github.com/slugify/slugify)
- Rust: [Stebalien/slug-rs](https://github.com/Stebalien/slug-rs)
- Python: [un33k/python-slugify](https://github.com/un33k/python-slugify)
- JavaScript: [simov/slugify](https://github.com/simov/slugify)
- JavaScript: [sindresorhus/slugify](https://github.com/sindresorhus/slugify)

## LICENSE

MIT License Copyright (c) 2023, Hanaasagi
