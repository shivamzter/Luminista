import aperture;
import settings;
import lib.lighting.lighting_all;
import helper.util;

RWTexture2D tex_main;
Texture2D tex_translucent;
Texture2D tex_translucentNormal;
Texture2D tex_translucentLightMap;

Texture2D tex_skyTransmittanceLUT;
Texture2D tex_skyViewScatteringLUT;

[shader("compute")]
[numthreads(16, 16)]
void main(uint2 coord: SV_DispatchThreadID) {
    if (all(coord < ap.game.renderSize)) {

        float4 translucent = tex_translucent[coord];
        if (translucent.a <= 0.0) return;            // no water on this pixel

        float2 texcoord = (coord + 0.5) / ap.game.renderSize;

        float depth = ap.depth[coord];                    // depth of the water surface

float3 ndcPos    = float3(texcoord * 2.0 - 1.0, depth);
float3 viewPos   = projectAndDivide(ap.camera.projectionInv, ndcPos);
float3 playerPos = mul(ap.camera.viewInv, float4(viewPos, 1.0)).xyz;

        float3 normal   = normalize(octDecode(tex_translucentNormal[coord].xy));
        float4 lightMap = tex_translucentLightMap[coord];

        float3 albedo = srgbToLinear(translucent.rgb);
        float3 litWater = albedo * surfaceLighting(playerPos, normal, lightMap, tex_skyTransmittanceLUT, tex_skyViewScatteringLUT);

        float3 litBehind = decodeColorRgbm16F(tex_main[coord]);   // already lit terrain or sky

        tex_main[coord] = encodeColorRgbm16F(lerp(litBehind, litWater, translucent.a));
    }
}