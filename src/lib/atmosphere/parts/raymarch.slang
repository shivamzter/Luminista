implementing atmos_all;

Texture2D tex_skyTransmittanceLUT;

public struct PrimaryRayMarch{
    public float3 scattering;
    public float3 transmittance;
}

public float3 computeIntegratedSingleScatteringForCelestialLight(MediumSample mediumSample, float lightRayleighPhase, float lightMiePhase, float3 rayPos, float3 lightDir, float3 sampleTransmittance, float3 lightIlluminance) {

    float3 phaseTimesMediumScattering = mediumSample.rayleighScattering * lightRayleighPhase + mediumSample.mieScattering * lightMiePhase;

    float earthShadow = earthShadow(rayPos, lightDir);
        
    float3 sampleToLightTransmittance = computeTransmittanceToCelestialLight(rayPos, lightDir, tex_skyTransmittanceLUT);

    float3 singleScattering = lightIlluminance * phaseTimesMediumScattering * sampleToLightTransmittance * earthShadow;

    return (singleScattering - singleScattering * sampleTransmittance) / mediumSample.totalExtinction;
}

public PrimaryRayMarch rayMarch(in float3 entryPointPos, in float3 exitPointPos, in int numSteps) {

    PrimaryRayMarch ray;
    ray.scattering = float3(0.0);
    ray.transmittance = float3(1.0);

    float3 rayDir = normalize(exitPointPos - entryPointPos);

    float3 sunLightDir = normalize(ap.celestial.sunPosition);
    float3 moonLightDir = normalize(ap.celestial.moonPosition);

    float sunCosTheta = dot(rayDir, sunLightDir);
    float moonCosTheta = dot(rayDir, moonLightDir);

    float sunLightRayleighPhase = rayleighPhase(sunCosTheta);
    float moonLightRayleighPhase = rayleighPhase(moonCosTheta);

    float sunLightMiePhase = miePhaseCornetteShanks(sunCosTheta, MIE_PHASE_G);
    float moonLightMiePhase = miePhaseCornetteShanks(moonCosTheta, MIE_PHASE_G);

    float3 rayStep = (exitPointPos - entryPointPos) / float(numSteps);

    float rayStepLength = length(rayStep);

    for (int i = 0; i < numSteps; i++) {

        float3 rayPos = lerp(entryPointPos, exitPointPos, (float(i) + 0.5) / float(numSteps));

        float sampleRadius = length(rayPos);

        MediumSample mediumSample = sampleMedium(sampleRadius);

        float3 sampleTransmittance = exp(-mediumSample.totalExtinction * rayStepLength);

        float3 sunScattering = computeIntegratedSingleScatteringForCelestialLight(mediumSample, sunLightRayleighPhase, sunLightMiePhase, rayPos, sunLightDir, sampleTransmittance, SUN_ILLUMINANCE);
        float3 moonScattering = computeIntegratedSingleScatteringForCelestialLight(mediumSample, moonLightRayleighPhase, moonLightMiePhase, rayPos, moonLightDir, sampleTransmittance, MOON_ILLUMINANCE);

        ray.scattering += (sunScattering + moonScattering) * ray.transmittance;
        ray.transmittance *= sampleTransmittance;
    }

    return ray;
}