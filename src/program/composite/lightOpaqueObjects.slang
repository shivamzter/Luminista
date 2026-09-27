import aperture;
import settings;
import lib.atmosphere.atmos_all;
import lib.rt_shadows;
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

        float2 texcoord = (coord + 0.5) / ap.game.renderSize;

        float4 color = tex_main[coord];
        color.rgb = decodeColorRgbm16F(color);
        
        float4 normal = tex_normal[coord];
        normal.xyz = octDecode(normal.xy);

        float4 lightMap = tex_lightMap[coord];
        // lightMap.rgb = pow(lightMap.rgb, float3(2.2));

        float vanillaBlockLight = lightMap.r;
        float vanillaSkyLight = lightMap.g;

        float depth = ap.opaqueDepth[coord];

        if (depth > 0.0) {
            color.rgb = srgbToLinear(color.rgb);

            if (userSettings.DEBUG_WHITE_WORLD) {
                color.rgb = float3(userSettings.DEBUG_ALBEDO);
            }

            float vanillaAO = srgbToLinear(lightMap.b);

            // Space conversions
            float3 ndcPos = float3(texcoord * 2.0 - 1.0, depth);
            float3 viewPos = projectAndDivide(ap.camera.projectionInv, ndcPos);
            float3 playerPos = mul(ap.camera.viewInv, float4(viewPos, 1.0)).xyz;

            float3 cameraPos = float3(0.0, ap.camera.position.y, 0.0);
            float3 rayOrigin = playerToAtmosphere(playerPos + cameraPos);

            float3 surfaceNormal = normalize(normal.xyz);

            color.rgb *= surfaceLighting(playerPos, surfaceNormal, lightMap, tex_skyTransmittanceLUT, tex_skyViewScatteringLUT);

            // color.rgb *= directLighting + indirectLighting;
        }

        tex_main[coord] = encodeColorRgbm16F(color.rgb);
    }
}