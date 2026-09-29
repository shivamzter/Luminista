import aperture; // Required import. Always.
import object_shader; // Required import for object shaders. Not recommended otherwise.
import settings; // Contains your shader settings, both realtime and compile time.
import helper.util;

// What you intend to output (color). Name these with what you have put as the bindings in Java.
struct FragmentOutput {
    float4 color;
    float4 normal;
    float4 lightMap;
    float4 labSpecular;
}

// What you intend to pass from the vertex shader to the fragment shader. Can have whatever you want.
struct VertexOutput {
    float2 uv : TEXCOORD; // This : TEXCOORD at the end is called a "semantic". It is used to hint to Aperture what it is. Not required, but recommended. In the future, a list of recommended semantics will be provided.
    float3 pos;
    float4 color : COLOR;
    float3 normal;
    float3 light;
}

float linearStep(float min, float max, float x) {
	return saturate((x - min) / (max - min));
}

struct DeferredOpaqueShader : Shader<VertexOutput, FragmentOutput> {
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

        if (let texture = objectData.albedo()) { 
            color *= texture.sampleTexture(vIn.uv);
        }
        
        ap.discardCutout(color);

        ///// VANILLA STUFF ////////////////////
        // The following 2 lines were copied from Amaryllis shader
        const float lmcoordLowerBound = 1.0 / 32.0;
        const float lmcoordUpperBound = 31.0 / 32.0;

        float vanillaBlockLight = linearStep(lmcoordLowerBound, lmcoordUpperBound, vIn.light.r);
        float vanillaSkyLight = linearStep(lmcoordLowerBound, lmcoordUpperBound, vIn.light.g);
        float vanillaAO = select(vIn.light.b == 0.0, 1.0, vIn.light.b);

        ///// NORMAL ////////////////////


        ///// SPECULAR ////////////////////
        float4 labSpecular = float4(0.0, 0.0, 0.0, 1.0);

        if (let specularTex = objectData.specular()) {
            labSpecular = specularTex.sampleTexture(vIn.uv);
        }

        ///// OUTPUTS ////////////////////
        output.color = float4(color.rgb, 1.0);
        output.normal = float4(octEncode(vIn.normal), 1.0, 1.0);
        output.lightMap = float4(vanillaBlockLight, vanillaSkyLight, vanillaAO, 1.0);
        output.labSpecular = float4(labSpecular);

        return output;
    }
}