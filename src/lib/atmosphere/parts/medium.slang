implementing atmos_all;

public struct MediumSample {
    float3 rayleighScattering;
    float3 rayleighExtinction;

    float3 mieScattering;
    float3 mieExtinction;
    
    float3 ozoneExtinction;

    float3 totalScattering;
    float3 totalExtinction;
}

public MediumSample sampleMedium(float sampleRadius) {
    float altitude = max(sampleRadius - ATMOSPHERE_BOTTOM_RADIUS_KM, 0.0);

    float rayleighDensity = exp(RAYLEIGH_DENSITY_EXP_SCALE * altitude);
    float mieDensity = exp(MIE_DENSITY_EXP_SCALE * altitude);
    float ozoneDensity = saturate(select(
        altitude < OZONE_LAYER0_WIDTH,
        fma(OZONE_LAYER0_LINEAR_TERM, altitude, OZONE_LAYER0_CONSTANT_TERM),
        fma(OZONE_LAYER1_LINEAR_TERM, altitude, OZONE_LAYER1_CONSTANT_TERM)
    ));

    MediumSample sample;

    sample.rayleighScattering = RAYLEIGH_SCATTERING * rayleighDensity;
    sample.rayleighExtinction = RAYLEIGH_EXTINCTION * rayleighDensity;

    sample.mieScattering = MIE_SCATTERING * mieDensity;
    sample.mieExtinction = MIE_EXTINCTION * mieDensity;

    sample.ozoneExtinction = OZONE_EXTINCTION * ozoneDensity;

    sample.totalScattering = sample.rayleighScattering + sample.mieScattering;
    sample.totalExtinction = sample.rayleighExtinction + sample.mieExtinction + sample.ozoneExtinction;

    return sample;
}

public float rayleighPhase(float cosTheta) {
    const static float factor = 3.0 / (16.0 * PI);
    return factor * (1.0 + cosTheta * cosTheta);
}

public float miePhaseCornetteShanks(float cosTheta, float g) {
    float gSqr = g * g;
    float k = 3.0 / (8.0 * PI) * (1.0 - gSqr) / (2.0 + gSqr);

    // the last cosTheta is -cosTheta??
    return k * (1.0 + cosTheta * cosTheta) / pow(1.0 + gSqr - 2.0 * g * cosTheta, 1.5);
}