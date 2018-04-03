#version 450

layout(location = 0) out vec4 f_color;
layout(location = 1) in vec2 vuv;
layout(set = 0, binding = 0) uniform Data {
    float frame;
} uniforms;

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

float sphere(vec3 position, vec3 sphere_center, float radius) {
    return length(position - sphere_center) - radius;
}

float distance(vec3 point) {
    float s = sphere(point, vec3(0.0), 3.0);

    return s;
}

vec3 calculate_normal(vec3 position) {
    vec3 epsilon = vec3(0.001, 0.0, 0.0);
    vec3 surface_normal = vec3(
        distance(position + epsilon.xyy) - distance(position - epsilon.xyy),
        distance(position + epsilon.yxy) - distance(position - epsilon.yxy),
        distance(position + epsilon.yyx) - distance(position - epsilon.yyx)
    );

    return normalize(surface_normal);
}

vec2 cast_ray(vec3 ray_origin, vec3 ray_direction) {
    const int max_steps = 64;
    const float max_distance = 40.0;
    float total_distance = 0.0;

    for (int i=0; i<max_steps; i++) {
        vec3 point = ray_origin + ray_direction * total_distance;
        float distance = distance(point);
        if (distance < 0.01 || total_distance >= max_distance) {
            break;
        }

        total_distance += distance;
    }

    float material = 1.0;
    if (total_distance >= max_distance) {
        material = 0.0;
    }

    return vec2(total_distance, material);
}

void main() {
    vec2 uv = vec2(vuv.x * 16.0 - 8.0, vuv.y * 9.0 - 4.5);

    vec3 forward = vec3(0.0, 0.0, -1.0);
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 right = cross(forward, up);

    const float fov = 75.0;
    const float fov_radians = (fov / 180) * 3.141592;
    const float distance_to_virtual_screen = 8.0 / fov_radians;

    vec3 eye = vec3(sin(uniforms.frame / 60.0) * 2.0, 0.0, 10.0) - forward * distance_to_virtual_screen;

    vec3 ray_origin = eye + right * uv.x + up * uv.y + forward * distance_to_virtual_screen;
    vec3 ray_destination = normalize(ray_origin - eye);

    vec2 result = cast_ray(ray_origin, ray_destination);
    float distance = result.x;
    float material = result.y;

    vec3 light = normalize(vec3(5.0));

    vec4 color = vec4(1.0, 0.5, 0.1, 1.0);
    if (material > 0.0) {
        vec3 intersection_point = ray_origin + forward * distance;
        vec3 surface_normal = calculate_normal(intersection_point);
        float diffusion = 1.5 * clamp(dot(surface_normal, light), 0.0, 1.0);

        color += diffusion * vec4(0.9, 0.5, 0.5, 1.0);
    } else {
        color = vec4(vec3(0.0), 1.0);
    }

    vec4 fog = vec4(0.5, 0.6, 0.7, 1.0);
    float mixer =  1.0 - exp(-distance * 0.07);
    color = mix(color, fog, mixer);

    f_color = color;
}

void old_main() {
    vec2 uv = vec2(vuv.x * 16.0 / 9.0, vuv.y);
    //vec2 uv = vec2(vuv.x * 3.5 - 2.5, vuv.y * 2.0 - 1.0);

    //float zoom = pow(2.0, -time) * 3.5;
    //vec2 c = zoomCoordinate + uv * zoom;
    vec2 c = uv + vec2(sin(uniforms.frame / 60.0), cos(uniforms.frame / 60.0));

    float mandel = mandelbrot(c);
    f_color = vec4(mandel, 0.0, 0.0, 1.0);
}
