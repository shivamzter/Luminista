import aperture;
import object_shader;

struct PixelOut {}

struct Interpolants {}

struct BasicShader : Shader<Interpolants, PixelOut> {
    static void emitVertex(Vertex v, ObjectTransforms transforms, out Interpolants interpOut, out float4 pos) {
        pos = v.pos();
        pos = mul(transforms.view, float4(pos.xyz, 1.0));
        pos = mul(transforms.projection, pos);
    }

    static PixelOut shadeSurface(PixelData objectData, Interpolants interpIn) {

        discard;
   
        return {};
    }
}