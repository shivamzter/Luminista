import aperture; // Required import. Always.
import object_shader; // Required import for object shaders. Not recommended otherwise.
import settings; // Contains your shader settings, both realtime and compile time.

// What you intend to output (color). Name these with what you have put as the bindings in Java.
struct FragmentOutput {
    float4 color;
}

// What you intend to pass from the vertex shader to the fragment shader. Can have whatever you want.
struct VertexOutput {
    float2 uv : TEXCOORD; // This : TEXCOORD at the end is called a "semantic". It is used to hint to Aperture what it is. Not required, but recommended. In the future, a list of recommended semantics will be provided.
    float3 pos;
    float4 color : COLOR;
    // float3 normal;
    // float4 tangent;
    float3 light;
}

// TBN matrix thanks to Jake Michie
// float3x3 computeTbnMatrix(float3 normal, float4 tangent) {
//     float3x3 tbnMatrix;
//     tbnMatrix[2] = normal;
//     tbnMatrix[0] = tangent.xyz;
//     tbnMatrix[1] = cross(tbnMatrix[0], tbnMatrix[2]) * select(tangent.w >= 0.0, 1.0, -1.0);

//     return tbnMatrix;
// }

// float linearStep(float min, float max, float x) {
// 	return saturate((x - min) / (max - min));
// }

struct ForwardTranslucentShader : Shader<VertexOutput, FragmentOutput> {
    static void emitVertex(Vertex input, ObjectTransforms transforms, out VertexOutput output, out float4 pos) {
        pos = mul(transforms.projection, mul(transforms.view, input.pos()));

        output.uv = input.uv();
        output.pos = pos.xyz;
        output.color = input.color();
        // output.normal = input.normal().value;
        // output.tangent = input.tangent().value;
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

        // The following 2 lines were copied from Amaryllis shader
        // const float lmcoordLowerBound = 1.0 / 32.0;
        // const float lmcoordUpperBound = 31.0 / 32.0;

        ////////// Vanilla stuff //////////

        // float vanillaBlockLight = linearStep(lmcoordLowerBound, lmcoordUpperBound, vIn.light.r);
        // float vanillaSkyLight = linearStep(lmcoordLowerBound, lmcoordUpperBound, vIn.light.g);
        // float vanillaAO = pow(vIn.light.b, float(2.2));
        // float vanillaAO = vIn.light.b;

        ////////// LabPBR Normal //////////

        // float4 labNormal = float4(0.0, 0.0, 1.0, 0.0);

        // Sample LabPBR normal map
        // if (let normalTex = objectData.normal()) {
        //     labNormal = normalTex.sampleTexture(vIn.uv);
        // }

        // Storing AO and Heightmap before modification
        // float labAO = labNormal.b;
        // float labHeightmap = labNormal.a;

        // Remap and calculate z component
        // labNormal.xy = labNormal.xy * 2.0 - 1.0;
	    // labNormal.z = sqrt(1.0 - dot(labNormal.xy, labNormal.xy));

        // float3x3 tbn = computeTbnMatrix(vIn.normal, vIn.tangent);

        // labNormal.xyz = normalize(mul(labNormal.xyz, tbn));

        ////////// LabPBR Specular //////////

        // float4 labSpecular = float4(0.0, 0.0, 0.0, 1.0);

        // Sample LabPBR specular map
        // if (let specularTex = objectData.specular()) {
        //     labSpecular = specularTex.sampleTexture(vIn.uv);
        // }

        // float roughness = pow(1.0 - (labSpecular.r), 2.0);
        // roughness = float(roughness / 255);

        // color.rgb *= vanillaAO;

        ////////// OUTPUTS //////////
        output.color = color;

        return output;
    }
}