import aperture;
import object_shader;

// This will not be documented. See basic.slang for what everything here does.

struct FragmentOutput {
    float4 color;
}

struct VertexOutput {
    float2 uv : TEXCOORD;
    float4 color : COLOR;
}

struct ShadowTranslucentShader : Shader<VertexOutput, FragmentOutput> {
    static void emitVertex(Vertex input, ObjectTransforms transforms, out VertexOutput vOut, out float4 pos) {
        
        pos = mul(transforms.projection, mul(transforms.view, input.pos()));

        vOut.uv = input.uv();
        vOut.color = input.color();
    }

    static FragmentOutput shadeSurface(PixelData objectData, VertexOutput vIn) {

        FragmentOutput output;

        float4 color = vIn.color;

        if (let texture = objectData.albedo()) {
            color *= texture.sampleTexture(vIn.uv);
        }

        ap.discardCutout(color);

        output.color = color;
        
        return output;
    }
}
