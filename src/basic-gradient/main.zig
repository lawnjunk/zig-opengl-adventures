const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});

const gl = @import("./gl.zig");

const std = @import("std");
const info = std.debug.print;
const shader_vertex_source: [:0]const u8 = @embedFile("./hello-rectangle.vertex.glsl");
const shader_fragment_source: [:0]const u8 = @embedFile("./hello-rectangle.fragment.glsl");

pub fn glGetProcAddress(p: void, proc_name: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    if (c.glfwGetProcAddress(proc_name)) |proc_address| {
        return proc_address;
    }
    return null;
}

const Err = error{
    GlfwInit,
    GlfwCreateWindow,
    GladLoadGl,
    GlCompileShader,
    GlProgramLink,
};

pub fn windowResizeCallback(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    // info("window size w:{d} h:{d}\n", .{ width, height });
    gl.viewport(0, 0, width, height);
    _ = window;
}

pub fn windowInputHandle(window: ?*c.GLFWwindow) void {
    if (c.glfwGetKey(window, c.GLFW_KEY_Q) == c.GLFW_PRESS) {
        info("byebye\n", .{});
        _ = c.glfwSetWindowShouldClose(window, c.GLFW_TRUE);
    }
}

pub fn windowCreate() Err!?*c.GLFWwindow {
    if (c.GLFW_TRUE != c.glfwInit()) {
        return Err.GlfwInit;
    }
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);
    c.glfwSwapInterval(1);

    const maby_window = c.glfwCreateWindow(800, 600, "Learnin Open GL!", null, null);
    if (maby_window == null) {
        return Err.GlfwCreateWindow;
    }

    const window = maby_window.?;
    c.glfwMakeContextCurrent(window);

    gl.load({}, glGetProcAddress) catch {
        return Err.GladLoadGl;
    };

    _ = c.glfwSetFramebufferSizeCallback(window, windowResizeCallback);
    return window;
}

pub fn main() !void {
    var window = try windowCreate();
    defer c.glfwTerminate();

    info("press q to quit\n", .{});
    while (c.glfwWindowShouldClose(window) != 1) {
        windowInputHandle(window);

        gl.clearColor(0, 0, 1.0, 0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
