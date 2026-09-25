implementing atmos_all;

public float3 computeTransmittanceToCelestialLight(float3 atmospherePos, float3 lightDir, Texture2D transmittanceLut) {
    float viewHeight = length(atmospherePos);
    float3 upDir = atmospherePos / viewHeight;
    float viewZenithCosAngle = dot(lightDir, upDir);

    float2 uv;
    LutTransmittanceParamsToUv(viewHeight, viewZenithCosAngle, uv);
    return transmittanceLut.SampleLevel(apt_linearSampler, uv, 0.0).rgb;
}