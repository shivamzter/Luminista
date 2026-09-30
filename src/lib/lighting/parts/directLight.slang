implementing lighting_all;

public float3 directLight(float3 albedo, float3 normal, float3 playerPos, float4 labSpecular, Texture2D transmittanceLUT) {
    float3 cameraPos = float3(0.0, ap.camera.position.y, 0.0);
    float3 rayOrigin = playerToAtmosphere(playerPos + cameraPos);

    float3 sunDir  = normalize(ap.celestial.sunPosition);
    float3 moonDir = normalize(ap.celestial.moonPosition);

    float3 viewDir = normalize(-playerPos);

    LabPBRData labPBR = decodeLabPBRv1_3(albedo, labSpecular);

    float3 sunLighting = earthShadow(rayOrigin, sunDir) * computeTransmittanceToCelestialLight(rayOrigin, sunDir, transmittanceLUT) * evaluateBRDF(labPBR, sunDir, viewDir, normal, SUN_ILLUMINANCE);
    float3 moonLighting = earthShadow(rayOrigin, moonDir) * computeTransmittanceToCelestialLight(rayOrigin, moonDir, transmittanceLUT) * evaluateBRDF(labPBR, moonDir, viewDir, normal, MOON_ILLUMINANCE);

    return sunLighting + moonLighting;
}