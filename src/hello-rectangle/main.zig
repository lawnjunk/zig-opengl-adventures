const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

const std = @import("std");
const info = std.debug.print;
const shader_vertex_source: [:0]const u8 = @embedFile("./hello-rectangle.vertex.glsl");
const shader_fragment_source: [:0]const u8 = @embedFile("./hello-rectangle.fragment.glsl");

const Err = error{
    GlfwInit,
    GlfwCreateWindow,
    GladLoadGl,
    GlCompileShader,
    GlProgramLink,
};

pub fn shaderProgramLinkErrorCheck(program_id: c_uint, name: []const u8) Err!void {
    var is_success: c_int = undefined;
    var error_messsage: [512]u8 = undefined;

    c.glGetProgramiv(program_id, c.GL_LINK_STATUS, &is_success);
    if (is_success != 1) {
        c.glGetShaderInfoLog(program_id, 512, null, &error_messsage);
        info("ERROR GlProgramLink [{s}]: {s}", .{ name, error_messsage });
        return Err.GlProgramLink;
    }
}

pub fn shaderCompileErrorCheck(shader_id: c_uint, name: []const u8) Err!void {
    var is_success: c_int = undefined;
    var error_messsage: [512]u8 = undefined;

    c.glGetShaderiv(shader_id, c.GL_COMPILE_STATUS, &is_success);
    if (is_success != 1) {
        c.glGetShaderInfoLog(shader_id, 512, null, &error_messsage);
        info("ERROR GlCompileShader [{s}]: {s}", .{ name, error_messsage });
        return Err.GlCompileShader;
    }
}

pub fn windowResizeCallback(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    // info("window size w:{d} h:{d}\n", .{ width, height });
    c.glViewport(0, 0, width, height);
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
    if (0 == c.gladLoadGLLoader(@ptrCast(c.GLADloadproc, &c.glfwGetProcAddress))) {
        return Err.GladLoadGl;
    }
    c.glViewport(0, 0, 800, 600);
    _ = c.glfwSetFramebufferSizeCallback(window, windowResizeCallback);
    return window;
}

pub fn main() !void {
    var window = try windowCreate();
    defer c.glfwTerminate();

    // compile the virtex shader
    var shader_vertex_id: c_uint = c.glCreateShader(c.GL_VERTEX_SHADER);
    defer c.glDeleteShader(shader_vertex_id);
    c.glShaderSource(shader_vertex_id, 1, &shader_vertex_source.ptr, null);
    c.glCompileShader(shader_vertex_id);
    try shaderCompileErrorCheck(shader_vertex_id, "shader_vertex_source");

    // compile the fragment shader
    var shader_fragment_id: c_uint = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    defer c.glDeleteShader(shader_fragment_id);
    c.glShaderSource(shader_fragment_id, 1, &shader_fragment_source.ptr, null);
    c.glCompileShader(shader_fragment_id);
    try shaderCompileErrorCheck(shader_fragment_id, "shader_fragment");

    // create shader program
    var shader_program_id = c.glCreateProgram();
    c.glAttachShader(shader_program_id, shader_vertex_id);
    c.glAttachShader(shader_program_id, shader_fragment_id);
    c.glLinkProgram(shader_program_id);
    c.glUseProgram(shader_program_id);

    // create an array buffer with the virtexs for the triangle
    const vertex_list = [_]f32{
        -0.5, 0.5, // 0 top left
        0.5, 0.5, // 1 top right
        -0.5, -0.5, // 2 bottom left
        0.5, -0.5, // 3 bottom right
    };

    const index_list = [_]c_uint{
        0, 1, 2,
        1, 2, 3,
    };

    // create vertex array object
    var vao_id: c_uint = undefined;
    c.glGenVertexArrays(1, &vao_id);
    defer c.glDeleteVertexArrays(1, &vao_id);

    // create vertex buffer object
    var vbo_id: c_uint = 0;
    c.glGenBuffers(1, &vbo_id);
    defer c.glDeleteBuffers(1, &vbo_id);

    // create an element buffer object
    var ebo_id: c_uint = 0;
    c.glGenBuffers(1, &ebo_id);
    defer c.glDeleteBuffers(1, &ebo_id);

    // setup vao_id to hold vertex_list
    {
        // unbind vao_id and vbo_id after setting it up so
        // that any future gl calls wont them
        defer c.glBindVertexArray(0);

        // first bind vao
        c.glBindVertexArray(vao_id);

        // then bind vbo and copy in the vertex data
        c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo_id);
        c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertex_list)), &vertex_list, c.GL_STATIC_DRAW);

        // then bind ebo and copy in the index data
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, ebo_id);
        c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(index_list)), &index_list, c.GL_STATIC_DRAW);

        // link vertex attributes
        c.glVertexAttribPointer(0, 2, c.GL_FLOAT, c.GL_FALSE, 2 * @sizeOf(f32), &0);
        c.glEnableVertexAttribArray(0);
    }

    info("press q to quit\n", .{});
    while (c.glfwWindowShouldClose(window) != 1) {
        windowInputHandle(window);
        c.glClearColor(1.0, 1.0, 0.0, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT);

        // link vertex attributes
        c.glUseProgram(shader_program_id);
        c.glBindVertexArray(vao_id);
        c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, null);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
