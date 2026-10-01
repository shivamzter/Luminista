implementing lighting_all;

public float ndfGGX(float nDotH, float alpha) {
    float a2 = alpha * alpha;

    float nDotH2 = nDotH * nDotH;

    float nom = a2;
    float denom = nDotH2 * (a2 - 1.0) + 1.0;
    denom = PI * denom * denom;

    return nom / denom;
}

public float3 fresnelSchlick(float cosTheta, float3 F0) {
    return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}

public float3 fresnelLazanyi2019(in float cosTheta, in float3 f0, in float3 f82) {
    float3 a = (823543.0 / 46656.0) * (f0 - f82) + (49.0 / 6.0) * (1.0 - f0);

    return f0 + (1.0 - f0) * pow(1.0 - cosTheta, 5.0) - a * cosTheta * pow(1.0 - cosTheta, 6.0);
}

public float3 fresnelF82Tint(float cosTheta, float3 f0, float3 f82Tint) {
    const float cosThetaMax = 1.0 / 7.0;               // ≈ 82°
    const float oneMinusCosMax = 1.0 - cosThetaMax;

    float3 schlickAtMax = f0 + (1.0 - f0) * pow(oneMinusCosMax, 5.0);
    float3 b = schlickAtMax * (1.0 - f82Tint) / (cosThetaMax * pow(oneMinusCosMax, 6.0));

    float oneMinusCos = 1.0 - cosTheta;
    return saturate(f0 + (1.0 - f0) * pow(oneMinusCos, 5.0) - b * cosTheta * pow(oneMinusCos, 6.0));
}

public float visibilitySmithGGXCorrelated(float nDotV, float nDotL, float roughness) {
    float a2 = roughness * roughness;
    float lambdaV = nDotL * sqrt(nDotV * nDotV * (1.0 - a2) + a2);
    float lambdaL = nDotV * sqrt(nDotL * nDotL * (1.0 - a2) + a2);
    return 0.5 / (lambdaV + lambdaL + 1e-5);
}

public float3 hammondDiffuse(float roughness, float nDotL, float nDotV, float nDotH, float lDotV, float3 albedo) {
    float safeNdotH = max(nDotH, 0.05);

    float facing = 0.5 + 0.5 * lDotV;
    float rough = facing * (0.9 - 0.4 * facing) * ((0.5 + safeNdotH) / (safeNdotH));
    float smooth = 1.05 * (1.0 - pow(1.0 - nDotL, 5.0)) * (1.0 - pow(1.0 - nDotV, 5.0));
    float single = (1.0 / PI) * lerp(smooth, rough, roughness);
    float multi = 0.1159 * roughness;
    return albedo * (single + albedo * multi);
}

public float3 evaluateBRDF(LabPBRData labPBRData, float3 lightDir, float3 viewDir, float3 normal, float3 radiance) {

    float3 halfwayDir = normalize(lightDir + viewDir);
    
    float nDotH = max(dot(normal, halfwayDir), 0.0);
    float vDotH = max(dot(viewDir, halfwayDir), 0.0);

    float nDotV = saturate(dot(normal, viewDir));
    float nDotL = saturate(dot(normal, lightDir));
    float lDotV = saturate(dot(lightDir, viewDir));

    // Distribution function
    float D = ndfGGX(nDotH, labPBRData.roughness);

    // Fresnel equation
    float3 F = labPBRData.isMetal ? fresnelF82Tint(vDotH, labPBRData.f0, labPBRData.f82Tint) : fresnelSchlick(vDotH, labPBRData.f0);

    // Geometry function
    float V = visibilitySmithGGXCorrelated(nDotV, nDotL, labPBRData.roughness);

    ///// SPECULAR ////////////////////
    float3 specular = D * V * F;

    ///// DIFFUSE ////////////////////
    float3 kD = 1.0 - F;
    kD = (labPBRData.isMetal) ? float3(0.0) : kD;

    float3 diffuse = kD * hammondDiffuse(labPBRData.roughness, nDotL, nDotV, nDotH, lDotV, labPBRData.albedo);

    ///// OUTPUT ////////////////////

    return (diffuse + specular) * radiance * nDotL;
}