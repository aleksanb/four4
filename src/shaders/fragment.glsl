#version 450

layout(location = 0) out vec4 f_color;
layout(location = 1) in vec2 vuv;
layout(set = 0, binding = 0) uniform Data {
    float frame;
} uniforms;

// Combination operators
float op_union(float d1, float d2) {
    return min(d1, d2);
}

float op_subtract(float d1, float d2) {
    return max(-d1, d2);
}

float intersection(float d1, float d2) {
    return max(d1, d2);
}

float smin( float a, float b, float k ) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

// Geometric shapes
float sphere(vec3 point, vec3 sphere_center, float radius) {
    return length(sphere_center - point) - radius;
}

float torus(vec3 point, vec2 torus) {
  vec2 q = vec2(length(point.xz) - torus.x, point.y);
  return length(q) - torus.y;
}

float box(vec3 point, vec3 box_center, vec3 box) {
  return length(max(abs(box_center - point) - box, 0.0));
}

float distance(vec3 point, float time) {
    float s1 = sphere(point, vec3(-5.0 + sin(time / 60.0) * 10.0, 0.0 + cos(time / 40.0) * 3.0, 0.0), 3.0);
    float s2 = sphere(point, vec3(5.0 + cos(time / 60.0) * 10.0, 0.0, 0.0), 3.0);

    float s3 = sphere(point, vec3(-3.0 + cos(time / 50.0) * 10.0, 5.0 + sin(time / 30.0) * 2.0, 0.0), 3.0);
    float s4 = sphere(point, vec3(6.0 + sin(time / 80.0) * 10.0, 4.0, 0.0), 3.0);

    float b1 = box(point, vec3(-10, 0.0, 0.0), vec3(1.0, 20.0, 40.0));
    float b2 = box(point, vec3(10, 0.0, 0.0), vec3(1.0, 20.0, 40.0));

    float k = 1.0;
    float scene = b1;
    scene = smin(scene, b1, k);
    scene = smin(scene, b2, k);
    scene = smin(scene, s1, k);
    scene = smin(scene, s2, k);
    scene = smin(scene, s3, k);
    scene = smin(scene, s4, k);

    return scene;
}

vec3 calculate_normal(vec3 position, float time) {
    vec3 epsilon = vec3(0.001, 0.0, 0.0);
    vec3 surface_normal = vec3(
        distance(position + epsilon.xyy, time) - distance(position - epsilon.xyy, time),
        distance(position + epsilon.yxy, time) - distance(position - epsilon.yxy, time),
        distance(position + epsilon.yyx, time) - distance(position - epsilon.yyx, time)
    );

    return normalize(surface_normal);
}

vec2 cast_ray(vec3 ray_origin, vec3 ray_direction, float time) {
    const int max_steps = 64;
    const float max_distance = 10000.0;
    float total_distance = 0.0;

    for (int i=0; i<max_steps; i++) {
        vec3 point = ray_origin + ray_direction * total_distance;
        float distance = distance(point, time);
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
    vec2 uv = vec2(vuv.x * 16.0, vuv.y * 9.0);

    vec3 camera_position = vec3(
        0.0,//sin(uniforms.frame / 60.0) * 10.0,
        0.0,
        10.0
        //0.0,sin(uniforms.frame / 60.0) * 10.0
    );

    vec3 camera_look_at_position = vec3(0.0, 0.0, 0.0);

    vec3 screen_space_up = vec3(0.0, 1.0, 0.0);
    vec3 camera_forward = normalize(camera_look_at_position - camera_position);
    vec3 camera_right = cross(camera_forward, screen_space_up);
    vec3 camera_up  = cross(camera_right, camera_forward);

    float fov = 75.0;
    float fov_radians = (fov / 180) * 3.141592;
    float distance_to_virtual_screen = 8.0 / fov_radians;

    camera_position -= camera_forward * distance_to_virtual_screen;
    vec3 intersection_point_with_virtual_screen =  camera_position + camera_right * uv.x + camera_up * uv.y + camera_forward * distance_to_virtual_screen;
    vec3 ray_direction = normalize(intersection_point_with_virtual_screen - camera_position);

    float time = uniforms.frame;

    vec2 result = cast_ray(camera_position, ray_direction, time);
    float distance = result.x;
    float material = result.y;

    vec3 light = normalize(vec3(0.0, 5.0, 5.0));

    vec4 fog = vec4(0.5, 0.6, 0.7, 1.0);
    vec4 color = vec4(1.0, 0.5, 0.1, 1.0);
    if (material > 0.0) {
        vec3 intersection_point = camera_position + ray_direction * distance;
        vec3 surface_normal = calculate_normal(intersection_point, time);
        float diffusion = 1.5 * clamp(dot(surface_normal, light), 0.0, 1.0);

        color += diffusion * vec4(0.9, 0.5, 0.5, 1.0);

        float mixer =  1.0 - exp(-distance * 0.07);
        color = mix(color, fog, mixer);
    } else {
        color = fog;
    }

    f_color = color;
}
