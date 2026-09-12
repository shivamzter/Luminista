import aperture;
import object_shader;

// This will not be documented. See basic.slang for what everything here does.

struct FragmentOutput {}

struct VertexOutput {
    float2 uv : TEXCOORD;
}

struct ShadowOpaqueShader : Shader<VertexOutput, FragmentOutput> {
    static void emitVertex(Vertex input, ObjectTransforms transforms, out VertexOutput vOut, out float4 pos) {

        pos = mul(transforms.projection, mul(transforms.view, input.pos()));

        vOut.uv = input.uv();
    }

    static FragmentOutput shadeSurface(PixelData objectData, VertexOutput vIn) {
        
        FragmentOutput output;

        if (let texture = objectData.albedo()) {
            ap.discardCutout(texture.sampleTexture(vIn.uv));
        }

        return FragmentOutput();
    }
}
