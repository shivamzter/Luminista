module lighting_all;

import aperture;
import settings;
import lib.atmosphere.atmos_all;
import lib.rt_shadows;
import helper.util;

// returns light arriving at the surface (multiply by linear albedo)
public float3 surfaceLighting(float3 playerPos, float3 normal, float4 lightMap, Texture2D transmittanceLUT, Texture2D skyViewLUT) {
    
    float3 cameraPos = float3(0.0, ap.camera.position.y, 0.0);
    float3 rayOrigin = playerToAtmosphere(playerPos + cameraPos);

    float3 shadow = getShadow(playerPos, normal);

    float3 sunDir  = normalize(ap.celestial.sunPosition);
    float3 moonDir = normalize(ap.celestial.moonPosition);

    float3 sunLighting  = earthShadow(rayOrigin, sunDir)  * SUN_ILLUMINANCE  * computeTransmittanceToCelestialLight(rayOrigin, sunDir,  transmittanceLUT) * max(0.0, dot(normal, sunDir))  / PI;
    float3 moonLighting = earthShadow(rayOrigin, moonDir) * MOON_ILLUMINANCE * computeTransmittanceToCelestialLight(rayOrigin, moonDir, transmittanceLUT) * max(0.0, dot(normal, moonDir)) / PI;

    float2 upUV = fromUnitToSubUvs(getUvFromLonLatNonLinear(getLonLatFromDir(float3(0.0, 1.0, 0.0))), float2(SKY_VIEW_LUT_SIZE));
    float3 skyLighting = decodeColorRgbm16F(skyViewLUT.SampleLevel(apt_linearSampler, upUV, 0));

    float vanillaSkyLight = lightMap.g;

    float ambientOcclusion = 1.0;
    if (userSettings.VANILLA_AO) {
        ambientOcclusion = lerp(1.0, srgbToLinear(lightMap.b), userSettings.VANILLA_AO_INTENSITY);
    }

    float3 directLight = shadow * (sunLighting + moonLighting);
    float3 indirectLight = (skyLighting * vanillaSkyLight) * ambientOcclusion;

    return directLight + indirectLight;
}