const std = @import("std");
const json_zig = @import("json_zig");

const CryptoPrice = struct {
    symbol: []const u8,
    price: []const u8,
    timestamp: u64,

    pub fn format(
        self: @This(),
        writer: anytype,
    ) !void {
        //        _ = fmt;
        //_ = options;
        // 按 JSON 漂亮格式输出
        // json stringfty print
        std.debug.print("{}\n", .{json_zig.stringify(self, writer)});
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    var body_writer = std.io.Writer.Allocating.init(allocator);
    defer body_writer.deinit();

    const resp = try client.fetch(.{
        .location = .{ .url = "https://api.api-ninjas.com/v1/cryptoprice?symbol=BTCUSDT" },
        .extra_headers = &.{
            .{ .name = "X-Api-Key", .value = "eKvfgR/g3LnmNbhfe4pfiQ==BxWkl56ZIGWtIt5K" },
        },
        .response_writer = &body_writer.writer,
        .keep_alive = false,
    });
    if (resp.status != .ok) return error.UnexpectedStatus;

    var body = body_writer.toArrayList();
    defer body.deinit(allocator);

    // 解析为 CryptoPrice 结构体
    const parsed = try std.json.parseFromSlice(CryptoPrice, allocator, body.items, .{});
    defer parsed.deinit();
    const value: CryptoPrice = parsed.value;

    // 直接用自定义 format 漂亮打印
    std.debug.print("{f}\n", .{value});
}
