const std = @import("std");

const Program = struct {
    name: []const u8,
    description: []const u8,
    has_test: bool,
};

const program_list = [_]Program{
    .{
        .name = "hello-window",
        .description = "a resizeable window that is all ways blue",
        .has_test = false,
    },
    .{
        .name = "hello-triangle",
        .description = "display a tringle created with virtex and fragment shaders",
        .has_test = false,
    },
    .{
        .name = "hello-rectangle",
        .description = "display a rectangle created with ellement array buffer",
        .has_test = false,
    },
    .{
        .name = "rainbow-triangle",
        .description = "display a rainbow-triangle",
        .has_test = false,
    },
    .{
        .name = "basic-gradient",
        .description = "display a gradient rectangle",
        .has_test = false,
    },
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    inline for (program_list) |program| {
        // const gl = b.addStaticLibrary(.{
        //     .name = "gl",
        //     .root_source_file = .{ .path = "res/zig/gl.zig" },
        //     .optimize = optimize,
        //     .target = target,
        // });

        const exe = b.addExecutable(.{
            .name = program.name,
            .root_source_file = .{ .path = "src/" ++ program.name ++ "/main.zig" },
            .target = target,
            .optimize = optimize,
        });

        // setup and link dependencys
        exe.addLibraryPath("res/lib");
        exe.addIncludePath("res/include");
        exe.linkLibC();
        // exe.linkLibrary(gl);
        const flags = [_][]const u8{};
        exe.addCSourceFile("res/src/glad.c", flags[0..]);
        exe.linkSystemLibrary("glfw3");
        exe.linkSystemLibrary("X11");

        b.installArtifact(exe);
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        const run_step = b.step("run-" ++ program.name, program.description);
        run_step.dependOn(&run_cmd.step);

        if (program.has_test) {
            const unit_tests = b.addTest(.{
                .root_source_file = .{ .path = "src/" ++ program.name ++ "/main.zig" },
                .target = target,
                .optimize = optimize,
            });
            const run_unit_tests = b.addRunArtifact(unit_tests);
            const test_step = b.step("test-" ++ program.name, "run unit tests for " ++ program.name);
            test_step.dependOn(&run_unit_tests.step);
        }
    }
}
