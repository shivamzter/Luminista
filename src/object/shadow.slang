import aperture;
import object_shader;

// This will not be documented. See basic.slang for what everything here does.

struct ShadowOut {}

struct ShadowVOut {
    float2 uv : TEXCOORD;
}

struct ShadowShader : Shader<ShadowVOut, ShadowOut> {
    static void emitVertex(Vertex v, ObjectTransforms transforms, out ShadowVOut vOut, out float4 pos) {
        pos = v.pos();
        pos = mul(transforms.view, float4(pos.xyz, 1.0));
        pos = mul(transforms.projection, pos);
        vOut.uv = v.uv();
    }

    static ShadowOut shadeSurface(PixelData objectData, ShadowVOut vi) {
        if (let texture = objectData.albedo()) {
            ap.discardCutout(texture.sampleTexture(vi.uv));
        }
        return ShadowOut();
    }
}
