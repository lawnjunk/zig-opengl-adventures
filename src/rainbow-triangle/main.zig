const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});

const std = @import("std");
const info = std.debug.print;
const triangle_vertex_source: [:0]const u8 = @embedFile("./rainbow-triangle.vertex.glsl");
const triangle_fragment_source: [:0]const u8 = @embedFile("./rainbow-triangle.fragment.glsl");
const background_vertex_source: [:0]const u8 = @embedFile("./background.v.glsl");
const background_fragment_source: [:0]const u8 = @embedFile("./background.f.glsl");

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

    const maby_window = c.glfwCreateWindow(1800, 600, "Learnin Open GL!", null, null);
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

const MouseNormal = struct {
    x: f32,
    y: f32,
};

pub fn mouseNormalGet(window: ?*c.GLFWwindow) MouseNormal {
    var mouse_x: f64 = undefined;
    var mouse_y: f64 = undefined;

    var width: c_int = undefined;
    var height: c_int = undefined;

    c.glfwGetCursorPos(window, &mouse_x, &mouse_y);
    c.glfwGetWindowSize(window, &width, &height);

    const x = @floatCast(f32, mouse_x) / @intToFloat(f32, width);
    const y = @floatCast(f32, mouse_y) / @intToFloat(f32, height);
    return .{
        .x = std.math.clamp(x, 0.0, 1.0),
        .y = std.math.clamp(y, 0.0, 1.0),
    };
}

pub fn shaderProgramCreate(comptime name: []const u8, virtex_source: []const u8, fragment_source: []const u8) Err!c_uint {
    var shader_vertex_id: c_uint = c.glCreateShader(c.GL_VERTEX_SHADER);
    defer c.glDeleteShader(shader_vertex_id);
    c.glShaderSource(shader_vertex_id, 1, &virtex_source.ptr, null);raiboraiboraibo
    c.glCompileShader(shader_vertex_id);
    try shaderCompileErrorCheck(shader_vertex_id, name ++ "_shader_vertex_source");

    // compile the rainbow-triangle fragment shader
    var shader_fragment_id: c_uint = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    defer c.glDeleteShader(shader_fragment_id);
    c.glShaderSource(shader_fragment_id, 1, &fragment_source.ptr, null);
    c.glCompileShader(shader_fragment_id);
    try shaderCompileErrorCheck(shader_fragment_id, name ++ "_shader_fragment");

    var program_id = c.glCreateProgram();
    c.glAttachShader(program_id, shader_vertex_id);
    c.glAttachShader(program_id, shader_fragment_id);
    c.glLinkProgram(program_id);
    return program_id;
}

pub fn main() !void {
    var window = try windowCreate();
    defer c.glfwTerminate();

    const background_program_id = try shaderProgramCreate("background", background_vertex_source, background_fragment_source);

    const background_vertex_list = [_]f32{
        -1, -1, 0, // bottom left
        -1, 1, 0, // top left
        1, 1, 0, // top right
        1, -1, 0, // bottom right
    };

    const background_index_list = [_]c_uint{
        0, 1, 2,
        0, 2, 3,
    };

    // setup background vao
    var background_vao_id: c_uint = undefined;
    c.glGenVertexArrays(1, &background_vao_id);
    defer c.glDeleteVertexArrays(1, &background_vao_id);

    var background_vbo_id: c_uint = undefined;
    c.glGenBuffers(1, &background_vbo_id);
    defer c.glDeleteBuffers(1, &background_vbo_id);

    var background_ebo_id: c_uint = undefined;
    c.glGenBuffers(1, &background_ebo_id);
    defer c.glDeleteBuffers(1, &background_ebo_id);

    // setup background vao
    {
        // first bind vao
        c.glBindVertexArray(background_vao_id);
        defer c.glBindVertexArray(0);

        // then bind vbo and copy in the vertex data
        c.glBindBuffer(c.GL_ELEMENT_ARRAY_BUFFER, background_ebo_id);
        c.glBufferData(c.GL_ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(background_index_list)), &background_index_list, c.GL_STATIC_DRAW);

        // then bind vbo and copy in the vertex data
        c.glBindBuffer(c.GL_ARRAY_BUFFER, background_vbo_id);
        c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(background_vertex_list)), &background_vertex_list, c.GL_STATIC_DRAW);

        // link vertex attributes
        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 3 * @sizeOf(f32), @intToPtr(?*const anyopaque, 0));
        c.glEnableVertexAttribArray(0);
    }

    var rainbow_triangle_program_id = try shaderProgramCreate("triangle", triangle_vertex_source, triangle_fragment_source);

    // create an array buffer with the virtexs for the triangle
    const vertex_list = [_]f32{
        // triangle 1
        -0.5, 0.5, 0.0, // 0 top left
        1.0, 0.0, 0.0, // red
        0.5, 0.5, 0.0, // 1 top right
        0.0, 0.0, 1.0, // blue
        -0.5, -0.5, 0.0, // 2 bottom left
        0.0, 0.0, 0.0, // black

        // triangle 2
        0.5, 0.5, 0.0, // top right
        0.0, 0.0, 0.0, // black
        0.5, -0.5, 0.0, // bottom right
        0.0, 0.0, 1.0, // blue
        -0.5, -0.5, 0.0, // bottom left
        1.0, 0.0, 0.0, // red
    };

    // create vertex array object
    var triangle_vao_id: c_uint = undefined;
    c.glGenVertexArrays(1, &triangle_vao_id);
    defer c.glDeleteVertexArrays(1, &triangle_vao_id);

    // create vertex buffer object
    var triangle_vbo_id: c_uint = 0;
    c.glGenBuffers(1, &triangle_vbo_id);
    defer c.glDeleteBuffers(1, &triangle_vbo_id);
    // setup triangle_vao_id to hold vertex_list
    {
        // unbind triangle_vao_id and triangle_vbo_id after setting it up so
        // that any future gl calls wont them
        defer c.glBindVertexArray(0);

        // first bind vao
        c.glBindVertexArray(triangle_vao_id);

        // then bind vbo and copy in the vertex data
        c.glBindBuffer(c.GL_ARRAY_BUFFER, triangle_vbo_id);
        c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertex_list)), &vertex_list, c.GL_STATIC_DRAW);

        // link vertex attributes
        c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), @intToPtr(?*const anyopaque, 0));
        c.glEnableVertexAttribArray(0);

        c.glVertexAttribPointer(1, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), @intToPtr(*void, 3 * @sizeOf(f32)));
        c.glEnableVertexAttribArray(1);
    }

    // uniform
    var mouse_x_uniform = c.glGetUniformLocation(background_program_id, "mouse_x");
    var mouse_y_uniform = c.glGetUniformLocation(background_program_id, "mouse_y");

    info("press q to quit\n", .{});
    // render loop
    while (c.glfwWindowShouldClose(window) != 1) {
        windowInputHandle(window);

        // draw background
        c.glUseProgram(background_program_id);
        c.glBindVertexArray(background_vao_id);
        const mouse_normal = mouseNormalGet(window);
        c.glUniform1f(mouse_x_uniform, mouse_normal.x);
        c.glUniform1f(mouse_y_uniform, mouse_normal.y);
        c.glDrawElements(c.GL_TRIANGLES, 6, c.GL_UNSIGNED_INT, @intToPtr(?*const anyopaque, 0));

        // draw triangles
        c.glUseProgram(rainbow_triangle_program_id);
        c.glBindVertexArray(triangle_vao_id);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 6);

        c.glfwSwapBuffers(window);
        c.glfwPollEvents();
    }
}
