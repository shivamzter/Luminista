implementing lighting_all;

public float3 directLight(float3 albedo, float3 normal, float3 playerPos, float4 labSpecular, Texture2D transmittanceLUT) {
    float3 cameraPos = float3(0.0, ap.camera.position.y, 0.0);
    float3 rayOrigin = playerToAtmosphere(playerPos + cameraPos);

    float3 sunDir  = normalize(ap.celestial.sunPosition);
    float3 moonDir = normalize(ap.celestial.moonPosition);

    float3 viewDir = normalize(-playerPos);

    float roughness = labSpecular.r;
    roughness = pow(1.0 - (max(roughness, 0.04)), 2.0);
    float reflectance = labSpecular.g;

    float3 sunLighting = earthShadow(rayOrigin, sunDir) * computeTransmittanceToCelestialLight(rayOrigin, sunDir, transmittanceLUT) * disneyBRDF(sunDir, viewDir, albedo, reflectance, normal, roughness, SUN_ILLUMINANCE);
    float3 moonLighting = earthShadow(rayOrigin, moonDir) * computeTransmittanceToCelestialLight(rayOrigin, moonDir, transmittanceLUT) * disneyBRDF(moonDir, viewDir, albedo, reflectance, normal, roughness, MOON_ILLUMINANCE);

    return sunLighting + moonLighting;
}