public module shadows;

import aperture;
import settings;

internal Texture2DArray<float3> texShadowColor;

static bool projectShadow(float3 playerPos, float3 normal, out int cascadeIndex, out float2 uv, out float depth) {

    uint cascadeCount = min(userSettings.SHADOW_CASCADE_COUNT, max(1u, ap.celestial.cascadeCount));

    float3 shadowViewPos = mul(ap.celestial.view, float4(playerPos, 1.0)).xyz;
    float4 shadowClipPos;

    int cascade;

    for (cascade = 0; cascade < cascadeCount; cascade++) {

    shadowClipPos = mul(ap.celestial.projection[cascade], float4(shadowViewPos, 1.0));

    if (!isfinite(shadowClipPos.w) || abs(shadowClipPos.w) < 0.00001) {
    continue;
    }

    if (all(clamp(shadowClipPos.xy, float2(-1.0), float2(1.0)) == shadowClipPos.xy))
    break;
    
    }

    cascadeIndex = cascade;

    float3 shadowViewNormal = mul(float3x3(ap.celestial.view), normal);
    float3 shadowClipNormal = mul(float3x3(ap.celestial.projection[cascade]), shadowViewNormal);

    shadowClipPos.xyz += shadowClipNormal * 0.02 * pow(2.0, cascade);

    float3 ndc = shadowClipPos.xyz / shadowClipPos.w;
    uv = ndc.xy * 0.5 + 0.5;
    depth = ndc.z;

    float3 shadowPos = float3(uv, depth);
    return all(shadowPos >= 0.0 && shadowPos <= 1.0);
}

public static float3 getShadow(float3 playerPos, float3 normal) {

    int cascade;
    float2 uv;
    float depth;

    bool shadowScreenPos = projectShadow(playerPos, normal, cascade, uv, depth);
    
    float shadow = 0.0;
    float3 color = float3(0.0);

    float translucentDepth = ap.shadow.sampleNearest(uv, cascade);

    float opaqueDepth = ap.opaqueShadow.sampleNearest(uv, cascade);

    float3 translucentColor = texShadowColor.Sample(apt_nearestSampler, float3(uv, cascade));

    shadow += ap.opaqueShadow.compare(uv, cascade, depth);

    color += select(translucentDepth < depth && translucentDepth != opaqueDepth, translucentColor, float3(1.0));

    return shadow * color;
    // return opaqueDepth;
    // return translucentDepth;
    // return translucentColor;
}