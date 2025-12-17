const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // HTTP 客户端
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    // 把响应写入可增长缓冲
    var body_writer = std.Io.Writer.Allocating.init(allocator);
    defer body_writer.deinit();

    const resp = try client.fetch(.{
        .location = .{ .url = "http://httpbin.org/json" }, // 选个 HTTP 接口便于演示
        .response_writer = &body_writer.writer,
        .keep_alive = false,
    });
    if (resp.status != .ok) return error.UnexpectedStatus;

    // 拿到字节切片
    var body = body_writer.toArrayList();
    defer body.deinit(allocator);

    // 解析 JSON
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, body.items, .{});
    defer parsed.deinit();

    // 访问字段
    const slideshow = parsed.value.object.get("slideshow") orelse return error.MissingField;
    const title = slideshow.object.get("title") orelse return error.MissingField;

    std.debug.print("status={s}, title={s}\n", .{ @tagName(resp.status), title.string });
}
