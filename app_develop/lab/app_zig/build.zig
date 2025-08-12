const std = @import("std");

pub fn build(b: *std.Build) void {
    // const target = b.standardTargetOptions(.{});
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .arm,
        .os_tag = .linux,
        .abi = .musleabihf,
    });
    const optimize = b.standardOptimizeOption(.{});

    const app_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    });

    const app_exe = b.addExecutable(.{ .name = "app_zig", .root_module = app_mod });
    b.installArtifact(app_exe);
}
