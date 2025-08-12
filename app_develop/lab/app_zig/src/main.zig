pub fn main() !void {
    std.debug.print("Hello, {s}!\n", .{"Zig"});
}

const std = @import("std");
