const c = @import("./c.zig");

const Window = struct {
    c_window: ?*c.GLFWWindow,

    fn init() Window {
        if (c.GLFW_TRUE != c.glfwInit()) {
            return error.GlfwInit;
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
            return error.GlLoad;
        };

        _ = c.glfwSetFramebufferSizeCallback(window, windowResizeCallback);

        return .{
            .c_window = window,
        };
    }


};
