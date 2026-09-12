import aperture; // Required import. Always.
import object_shader; // Required import for object shaders. Not recommended otherwise.
import settings; // Contains your shader settings, both realtime and compile time.

// What you intend to output (color). Name these with what you have put as the bindings in Java.
struct FragmentOutput {
    float4 color;
    float4 normal;
}

// What you intend to pass from the vertex shader to the fragment shader. Can have whatever you want.
struct VertexOutput {
    float2 uv : TEXCOORD; // This : TEXCOORD at the end is called a "semantic". It is used to hint to Aperture what it is. Not required, but recommended. In the future, a list of recommended semantics will be provided.
    float3 pos;
    float4 color : COLOR;
    float3 normal;
    float3 light;
}

struct DeferredShader : Shader<VertexOutput, FragmentOutput> {
    static void emitVertex(Vertex input, ObjectTransforms transforms, out VertexOutput output, out float4 pos) {
        pos = mul(transforms.projection, mul(transforms.view, input.pos()));

        output.uv = input.uv();
        output.pos = pos.xyz;
        output.color = input.color();
        output.normal = input.normal().value;
        output.light = float3(input.lightCoord(), input.vertexAO().value);
    }

    static FragmentOutput shadeSurface(PixelData objectData, VertexOutput vIn) {

        FragmentOutput output;

        float4 color = vIn.color;

        if (let texture = objectData.albedo()) { // Since `albedo()` returns an Optional<Sampleable>, this is one of a few ways to get the true type. You can also do albedo().hasValue and albedo().value, of course.
            color *= texture.sampleTexture(vIn.uv); // Some objects simply don't have a texture, such as clouds
        }

        // This is equivalent to `if (objectIsCutout && alpha < 0.1) discard;`. It will determine if the object needs it.
        ap.discardCutout(color);

        color.rgb = pow(color.rgb, float3(2.2));

        ////////// OUTPUTS //////////
        output.color = color;
        output.normal = float4(vIn.normal, 1.0);

        return output;
    }
}