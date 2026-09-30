implementing lighting_all;

public struct LabPBRData {
    public float3 albedo;

    // R: smoothness
    public float roughness;

    // G: reflectance
    public bool isMetal;
    public float3 f0;
    public float3 f82Tint;
    
    // B: porosity or subsurface
    public float porosity;
    public float subsurface;

    // A: emission
    public float emission;
}

struct LabPBRv1_3ConductorData {
    float3 f0;
    float3 f82Tint;
}

LabPBRv1_3ConductorData getLabPBRv1_3ConductorData(in int conductor, in float3 albedo) {
    LabPBRv1_3ConductorData data;

    data.f0 = albedo;
    data.f82Tint = float3(1.0);

    // Iron
    if (conductor == 230) {
        data.f0 = float3(0.8951, 0.8755, 0.8154);
        data.f82Tint = float3(0.8551, 0.8800, 0.8966);
    }
    // Gold
    else if (conductor == 231) {
        data.f0 = float3(1.0000, 0.7099, 0.3148);
        data.f82Tint = float3(0.9408, 0.9636, 0.9099);
    }
    // Aluminum
    else if (conductor == 232) {
        data.f0 = float3(0.9157, 0.9226, 0.9236);
        data.f82Tint = float3(0.9090, 0.9365, 0.9596);
    }
    // Chrome
    else if (conductor == 233) {
        data.f0 = float3(0.5496, 0.5561, 0.5531);
        data.f82Tint = float3(0.7372, 0.7511, 0.8170);
    }
    // Copper
    else if (conductor == 234) {
        data.f0 = float3(1.0000, 0.6504, 0.5274);
        data.f82Tint = float3(0.9755, 0.9349, 0.9301);
    }
    // Lead
    else if (conductor == 235) {
        data.f0 = float3(0.6325, 0.6259, 0.6415);
        data.f82Tint = float3(0.8348, 0.8441, 0.8843);
    }
    // Platinum
    else if (conductor == 236) {
        data.f0 = float3(0.9602, 0.9317, 0.8260);
        data.f82Tint = float3(0.9501, 0.9461, 0.9352);
    }
    // Silver
    else if (conductor == 237) {
        data.f0 = float3(0.9868, 0.9830, 0.9667);
        data.f82Tint = float3(0.9929, 0.9961, 1.0000);
    }
    // Albedo Metal
    else {
        data.f0 = albedo;
        data.f82Tint = float3(1.0);
    }

    return data;
}

LabPBRData decodeLabPBRv1_3(float3 albedo, float4 specular) {

    LabPBRData labPBR;
    labPBR.albedo = albedo;

    // R: perceptual smoothness to linear roughness
    labPBR.roughness = pow(1.0 - specular.r, 2.0);

    // G: 0-229 f0, 230-237 predefined metals, 238-254 reserved, 255 albedo as metal
    int g = int(round(specular.g * 255.0));
    labPBR.isMetal = g >= 230;

    if (labPBR.isMetal) {
        LabPBRv1_3ConductorData conductor = getLabPBRv1_3ConductorData(g, albedo);
        labPBR.f0 = conductor.f0;
        labPBR.f82Tint = conductor.f82Tint;
    } else {
        labPBR.f0 = float3(g >= 1 ? float(g) / 255.0 : 0.04);
        labPBR.f82Tint = float3(1.0);
    }

    // B: 0-64 porosity, 65-255 subsurface
    int b = int(round(specular.b * 255.0));
    labPBR.porosity = b <= 64 ? float(b) / 64.0 : 0.0;
    labPBR.subsurface = b >= 65 ? float(b - 65) / 190.0 : 0.0;

    // A: 0-254 emission, 255 is ignored so not emissive;
    int a = int(round(specular.a * 255.0));
    labPBR.emission = a < 255 ? float(a) / 254.0 : 0.0;

    return labPBR;
}
