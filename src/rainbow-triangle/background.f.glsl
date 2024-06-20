#version 330
out vec4 FragColor;

uniform float mouse_x;
uniform float mouse_y;

void main(){
  float delta_color = 1.0f - mouse_x;
  FragColor = vec4(mouse_x, mouse_x, mouse_x + ((1.0 - mouse_y) * delta_color), 1.0f);
}
