const std = @import("std");

const CryptoPrice = struct {
    symbol: []const u8,
    price: f64,
    timestamp: u64,

    pub fn format(
        self: @This(),
        writer: anytype,
    ) !void {

        // 手动序列化为紧凑 JSON，避免适配旧 Writer 接口
        try writer.print(
            "{{\"symbol\":\"{s}\",\"price\":{d},\"timestamp\":{d}}}",
            .{ self.symbol, self.price, self.timestamp },
        );
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
