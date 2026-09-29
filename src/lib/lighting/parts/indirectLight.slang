implementing lighting_all;

public float3 indirectLight(float4 lightMap, Texture2D skyViewScatterLUT) {
    float ambientOcclusion = 1.0;
    if (userSettings.VANILLA_AO) {
        ambientOcclusion = lerp(1.0, srgbToLinear(lightMap.b), userSettings.VANILLA_AO_INTENSITY);
    }

    float2 upUV = fromUnitToSubUvs(getUvFromLonLatNonLinear(getLonLatFromDir(float3(0.0, 1.0, 0.0))), float2(SKY_VIEW_LUT_SIZE));
    float3 skyLighting = decodeColorRgbm16F(skyViewScatterLUT.SampleLevel(apt_linearSampler, upUV, 0));

    return skyLighting * ambientOcclusion;
}