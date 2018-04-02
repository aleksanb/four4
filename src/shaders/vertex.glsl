#version 450

layout(location = 0) in vec2 position;
layout(location = 1) out vec2 vuv;

void main() {
    vuv = position;
    gl_Position = vec4(position, 0.0, 1.0);
}
