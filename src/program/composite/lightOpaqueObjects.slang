import aperture;
import settings;
import lib.atmosphere.atmos_all;
import lib.rt_shadows;
import helper.util;

RWTexture2D tex_main;
RWTexture2D tex_normal;
RWTexture2D tex_lightMap;

Texture2D tex_skyViewScatteringLUT;

[shader("compute")]
[numthreads(16, 16)]
void main(uint2 coord: SV_DispatchThreadID) {

    if (all(coord < ap.game.renderSize)) {

        float2 texcoord = (coord + 0.5) / ap.game.renderSize;

        float4 color = tex_main[coord];
        
        float4 normal = tex_normal[coord];
        normal.xyz = octDecode(normal.xy);

        float4 lightMap = tex_lightMap[coord];
        // lightMap.rgb = pow(lightMap.rgb, float3(2.2));

        float vanillaBlockLight = lightMap.r;
        float vanillaAO = lightMap.b;

        float depth = ap.opaqueDepth[coord];

        if (depth > 0.0) {
            // Space conversions
            float3 ndcPos = float3(texcoord * 2.0 - 1.0, depth);
            float3 viewPos = projectAndDivide(ap.camera.projectionInv, ndcPos);
            float3 playerPos = mul(ap.camera.viewInv, float4(viewPos, 1.0)).xyz;

            float3 cameraPos = float3(0.0, ap.camera.position.y, 0.0);
            float3 rayOrigin = playerToAtmosphere(playerPos + cameraPos);

            float3 shadow = getShadow(playerPos, normal.xyz);

            float sunShadow = earthShadow(rayOrigin, normalize(ap.celestial.sunPosition));
            float moonShadow = earthShadow(rayOrigin, normalize(ap.celestial.moonPosition));

            float3 sunLighting = sunShadow * SUN_ILLUMINANCE * max(0.0, dot(normalize(normal.xyz), normalize(ap.celestial.sunPosition))) / PI;
            float3 moonLighting = moonShadow * MOON_ILLUMINANCE * max(0.0, dot(normalize(normal.xyz), normalize(ap.celestial.moonPosition))) / PI;

            float2 upUV = getUvFromLonLatNonLinear(getLonLatFromDir(float3(0.0, 1.0, 0.0)));
            upUV = fromUnitToSubUvs(upUV, float2(SKY_VIEW_LUT_SIZE));

            float3 skyLighting = tex_skyViewScatteringLUT.SampleLevel(apt_linearSampler, upUV, 0).rgb;

            float ambientOcclusion = 1.0;

            if (userSettings.VANILLA_AO) {
                ambientOcclusion *= lerp(1.0, vanillaAO, userSettings.VANILLA_AO_INTENSITY);
            }

            float3 directLighting = shadow * (sunLighting + moonLighting);
            // float3 indirectLighting = skyLighting;

            color.rgb *= directLighting;

            tex_main[coord] = float4(color.rgb, 1.0);
        }
    }
}