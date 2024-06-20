#version 330 core
layout (location = 0) in vec3 point;
layout (location = 1) in vec3 point_color_in;
out vec3 point_color;

void main(){
  gl_Position = vec4(point, 1.0);
  point_color = point_color_in;
}
