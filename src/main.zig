const std = @import("std");

const CryptoPrice = struct {
    symbol: []const u8,
    price: f64,
    timestamp: u64,

    pub fn format(
        self: @This(),
        writer: anytype,
    ) !void {
        // 手动序列化为紧凑 JSON，附带人类可读时间
        try writer.print(
            "Symbol: {s}, Price: {d}, Timestamp: ",
            .{ self.symbol, self.price },
        );
        try formatIsoUtc(self.timestamp, writer);
    }

    /// 使用 std.time 将秒级时间戳格式化为 YYYY-MM-DDTHH:MM:SSZ（UTC）
    fn formatIsoUtc(ts: u64, writer: anytype) !void {
        const epoch_seconds = std.time.epoch.EpochSeconds{ .secs = ts };
        const epoch_day = epoch_seconds.getEpochDay();
        const day_seconds = epoch_seconds.getDaySeconds();

        const yd = epoch_day.calculateYearDay();
        const md = yd.calculateMonthDay();
        const day_in_month: u8 = @intCast(md.day_index + 1); // day_index 从 0 开始

        const hour = day_seconds.getHoursIntoDay();
        const minute = day_seconds.getMinutesIntoHour();
        const second = day_seconds.getSecondsIntoMinute();

        try writer.print(
            "{d:0>4}-{d:0>2}-{d:0>2}T{d:0>2}:{d:0>2}:{d:0>2}Z",
            .{
                yd.year,
                md.month.numeric(),
                day_in_month,
                hour,
                minute,
                second,
            },
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

    // 先解析为动态 Value，再提取字段并转换 price / timestamp
    const parsed = try std.json.parseFromSlice(CryptoPrice, allocator, body.items, .{});
    defer parsed.deinit();

    // 直接用自定义 format 漂亮打印
    std.debug.print("{f}\n", .{parsed.value});
}
