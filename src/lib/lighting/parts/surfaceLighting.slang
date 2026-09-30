implementing lighting_all;

public float3 surfaceLighting(float3 albedo, float3 normal, float4 lightMap, float3 playerPos, Texture2D transmittanceLUT, Texture2D skyViewLUT, float4 labSpecular) {
    
    // SHADOW
    float3 shadow = float3(1.0);

    if (userSettings.SHADOW_ENABLED) {
        shadow = getShadow(playerPos, normal);
    }

    float3 directLight = shadow * directLight(albedo, normal, playerPos, labSpecular, transmittanceLUT);
    float3 indirectLight = indirectLight(albedo, lightMap, skyViewLUT);

    return directLight + indirectLight;
}