import aperture;
import settings;
import lib.lighting.lighting_all;
import helper.util;

Texture2D tex_translucentMain;
Texture2D tex_translucentNormal;
Texture2D tex_translucentLightMap;

Texture2D tex_skyTransmittanceLUT;
Texture2D tex_skyViewScatteringLUT;

RWTexture2D tex_main;

[shader("compute")]
[numthreads(16, 16)]
void main(uint2 coord: SV_DispatchThreadID) {
    if (all(coord < ap.game.renderSize)) {

        float4 colorTranslucent = tex_translucentMain[coord];

        float3 normal = normalize(octDecode(tex_translucentNormal[coord].xy));

        float4 lightMap = tex_translucentLightMap[coord];

        float depth = ap.depth[coord];

        float2 texcoord = (coord + 0.5) / ap.game.renderSize;

        // Space conversions
        float3 ndcPos    = float3(texcoord * 2.0 - 1.0, depth);
        float3 viewPos   = projectAndDivide(ap.camera.projectionInv, ndcPos);
        float3 playerPos = mul(ap.camera.viewInv, float4(viewPos, 1.0)).xyz;

        if (depth > 0.0) {

            colorTranslucent.rgb = srgbToLinear(colorTranslucent.rgb);

            colorTranslucent.rgb *= surfaceLighting(playerPos, normal, lightMap, tex_skyTransmittanceLUT, tex_skyViewScatteringLUT);
        }

        float3 litOpaqueObjects = decodeColorRgbm16F(tex_main[coord]);

        tex_main[coord] = encodeColorRgbm16F(lerp(litOpaqueObjects, colorTranslucent.rgb, colorTranslucent.a));
    }
}