import aperture;
import settings;
import helper.util;
import lib.lighting.lighting_all;

RWTexture2D tex_main;
RWTexture2D tex_normal;
RWTexture2D tex_lightMap;

Texture2D tex_skyTransmittanceLUT;
Texture2D tex_skyViewScatteringLUT;

[shader("compute")]
[numthreads(16, 16)]
void main(uint2 coord: SV_DispatchThreadID) {

    if (all(coord < ap.game.renderSize)) {

        float4 color = tex_main[coord];
        color.rgb = decodeColorRgbm16F(color);
        
        float3 normal = normalize(octDecode(tex_normal[coord].xy));

        float4 lightMap = tex_lightMap[coord];

        float depth = ap.opaqueDepth[coord];

        float2 texcoord = (coord + 0.5) / ap.game.renderSize;

        // Space conversions
        float3 ndcPos = float3(texcoord * 2.0 - 1.0, depth);
        float3 viewPos = projectAndDivide(ap.camera.projectionInv, ndcPos);
        float3 playerPos = mul(ap.camera.viewInv, float4(viewPos, 1.0)).xyz;

        if (depth > 0.0) {

            color.rgb = srgbToLinear(color.rgb);

            if (userSettings.DEBUG_WHITE_WORLD) {
                color.rgb = float3(1.0);
            }

            color.rgb *= surfaceLighting(playerPos, normal, lightMap, tex_skyTransmittanceLUT, tex_skyViewScatteringLUT);
        }

        tex_main[coord] = encodeColorRgbm16F(color.rgb);
    }
}