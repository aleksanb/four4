#version 450

layout(location = 0) out vec4 f_color;
layout(location = 1) in vec2 vuv;

const int depth = 256;

vec2 complexMult(vec2 a, vec2 b)
{
    float real = a.x * b.x - a.y * b.y;
    float complex = a.y * b.x + a.x * b.y;
    return vec2(real, complex);
}

float mandelbrot(vec2 c)
{
    vec2 z = vec2(0.0, 0.0);

    int depth_reached = depth;
    for (int i=0; i<depth; i++) {
        if (dot(z, z) > 4.0) {
            depth_reached = i;
            break;
        }
        z = complexMult(z, z) + c;
    }

    return 1.0 - float(depth - depth_reached) / float(depth);
}

void main() {
    vec2 uv = vec2(vuv.x * 16.0 / 9.0, vuv.y);
    //vec2 uv = vec2(vuv.x * 3.5 - 2.5, vuv.y * 2.0 - 1.0);

    //float zoom = pow(2.0, -time) * 3.5;
    //vec2 c = zoomCoordinate + uv * zoom;
    vec2 c = vec2(uv.x - 0.5, uv.y);

    float mandel = mandelbrot(c);
    f_color = vec4(mandel, 0.0, 0.0, 1.0);
}
