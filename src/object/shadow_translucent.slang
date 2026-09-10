import aperture;
import object_shader;

// This will not be documented. See basic.slang for what everything here does.

struct ShadowOut {
    float4 color;
}

struct ShadowVOut {
    float2 uv : TEXCOORD;
    float4 color : COLOR;
}

struct translucentShadowShader : Shader<ShadowVOut, ShadowOut> {
    static void emitVertex(Vertex v, ObjectTransforms transforms, out ShadowVOut vOut, out float4 pos) {
        pos = v.pos();
        pos = mul(transforms.view, float4(pos.xyz, 1.0));
        pos = mul(transforms.projection, pos);
        vOut.uv = v.uv();
        vOut.color = v.color();
    }

    static ShadowOut shadeSurface(PixelData objectData, ShadowVOut vi) {

        float4 color = vi.color;

        if (let texture = objectData.albedo()) {
            color *= texture.sampleTexture(vi.uv);
        }

        ap.discardCutout(color);


        return ShadowOut(color);
    }
}
