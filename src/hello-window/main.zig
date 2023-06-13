const std = @import("std");
const info = std.debug.print;

const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

pub fn resizeCallback(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    info("window size w:{d} h:{d}\n", .{ width, height });
    c.glViewport(0, 0, width, height);
    _ = window;
}

pub fn main() !void {
    if (c.GLFW_TRUE != c.glfwInit()) {
        return error.GlfwInitError;
    }
    defer c.glfwTerminate();
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);
    c.glfwWindowHint(c.GLFW_OPENGL_FORWARD_COMPAT, c.GL_TRUE);

    const maby_window = c.glfwCreateWindow(800, 600, "Learnin Open GL!", null, null);
    if (maby_window == null) {
        return error.GlfwCreateWindowError;
    }
    const window = maby_window.?;
    c.glfwMakeContextCurrent(window);
    if (0 == c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, &c.glfwGetProcAddress))) {
        return error.gladLoadGlError;
    }
    c.glViewport(0, 0, 800, 600);
    _ = c.glfwSetFramebufferSizeCallback(window, resizeCallback);

    info("press q to quit\n", .{});
    while (c.glfwWindowShouldClose(window) != 1) {
        c.glClearColor(0.1, 0.3, 0.9, 0.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        if (c.glfwGetKey(window, c.GLFW_KEY_Q) == c.GLFW_PRESS) {
            info("byebye\n", .{});
            _ = c.glfwSetWindowShouldClose(window, c.GLFW_TRUE);
        }
        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
