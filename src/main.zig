const std = @import("std");
const json = @import("json_zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const input =
        \\{
        \\  "name": "Zig",
        \\  "version": 0.11,
        \\  "features": ["fast", "safe"]
        \\}
    ;

    // Parse the JSON string
    // Note: It uses the allocator for internal structures (arrays, hashmaps).
    const root = try json.parse(allocator, input);
    // You can call root.deinit(allocator) if not using an ArenaAllocator,
    // but Arena is recommended for easier cleanup.

    if (root == .Object) {
        const obj = root.Object;
        if (obj.get("name")) |name| {
            std.debug.print("Name: {s}\n", .{name.String});
        }
    }

    var list = try std.ArrayList(u8).initCapacity(allocator, 1024);
    defer list.deinit(allocator);

    const val = json.JsonValue{ .String = "Hello World" };
    std.debug.print("JSON: {f}\n", .{val});

    // Write to any std.io.Writer
    try json.stringify(val, list.writer(allocator));

    std.debug.print("JSON: {s}\n", .{list.items});
}
