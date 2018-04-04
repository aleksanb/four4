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

// Geometric shapes
float sphere(vec3 position, vec3 sphere_center, float radius) {
    return length(position - sphere_center) - radius;
}

float torus(vec3 point, vec2 torus) {
  vec2 q = vec2(length(point.xz) - torus.x, point.y);
  return length(q) - torus.y;
}

float box(vec3 point, vec3 box) {
  return length(max(abs(point) - box, 0.0));
}

float distance(vec3 point) {
    float s1 = sphere(point, vec3(5.0, 0.0, 0.0), 3.0);
    float s2 = sphere(point, vec3(-5.0, 0.0, 0.0), 3.0);
    float s3 = sphere(point, vec3(0.0, 5.0, 0.0), 3.0);

    return op_union(op_union(s1, s2), s3);
    //float s = box(point, vec3(3.0, 1.0, 1.0));
    //float deform = sin(2.0 * point.x) * sin(20. * point.y) * sin(2.0 * point.y);
    //return s + deform;
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

    vec3 screen_space_up = vec3(0.0, 1.0, 0.0);
    vec3 camera_position = vec3(
        10.0 + sin(uniforms.frame / 60.0) * 10.0,
        10.0 + cos(uniforms.frame / 60.0) * 10.0,
        10.0 + sin(uniforms.frame / 60.0) * 10.0
    );
    vec3 camera_look_at_position = vec3(0.0, 0.0, 0.0);
    vec3 camera_forward = normalize(camera_look_at_position - camera_position);
    vec3 camera_right = cross(camera_forward, screen_space_up);
    vec3 camera_up  = cross(camera_right, camera_forward);

    float fov = 75.0;
    float fov_radians = (fov / 180) * 3.141592;
    float distance_to_virtual_screen = 8.0 / fov_radians;

    camera_position -= camera_forward * distance_to_virtual_screen;
    vec3 intersection_point_with_virtual_screen =  camera_position + camera_right * uv.x + camera_up * uv.y + camera_forward * distance_to_virtual_screen;
    vec3 ray_direction = normalize(intersection_point_with_virtual_screen - camera_position);

    vec2 result = cast_ray(camera_position, ray_direction);
    float distance = result.x;
    float material = result.y;

    vec3 light = normalize(vec3(5.0));

    vec4 fog = vec4(0.5, 0.6, 0.7, 1.0);
    vec4 color = vec4(1.0, 0.5, 0.1, 1.0);
    if (material > 0.0) {
        vec3 intersection_point = camera_position + ray_direction * distance;
        vec3 surface_normal = calculate_normal(intersection_point);
        float diffusion = 1.5 * clamp(dot(surface_normal, light), 0.0, 1.0);

        color += diffusion * vec4(0.9, 0.5, 0.5, 1.0);

        float mixer =  1.0 - exp(-distance * 0.07);
        color = mix(color, fog, mixer);
    } else {
        color = fog;
    }

    f_color = color;
}
