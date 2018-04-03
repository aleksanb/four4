mod vertex_shader {
    #[derive(VulkanoShader)]
    #[ty = "vertex"]
    #[path = "src/shaders/vertex.glsl"]
    struct Dummy;
}

mod fragment_shader {
    #[derive(VulkanoShader)]
    #[ty = "fragment"]
    #[path = "src/shaders/fragment.glsl"]
    struct Dummmy;
}

struct MandelbrotScene;

impl MandelbrotScene {
    fn
}

let vs = vertex_shader::Shader::load(device.clone()).expect("failed to create shader module");
let fs = fragment_shader::Shader::load(device.clone()).expect("failed to create shader module");
