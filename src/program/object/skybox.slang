import aperture;
import object_shader;

struct PixelOut {}

struct Interpolants {}

struct SkyShader : Shader<Interpolants, PixelOut> {
    static void emitVertex(Vertex input, ObjectTransforms transforms, out Interpolants interpOut, out float4 pos) {
        pos = mul(transforms.projection, mul(transforms.view, input.pos()));
    }

    static PixelOut shadeSurface(PixelData objectData, Interpolants interpIn) {

        discard;
   
        return {};
    }
}