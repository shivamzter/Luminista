import aperture;
import lib.shadow;

RWTexture2D tex_main;
RWTexture2D tex_normal;

public float3 projectAndDivide(float4x4 invProj, float3 pos) {
    float4 homePos = mul(invProj, float4(pos, 1.0));
    return homePos.xyz / homePos.w;
}

[shader("compute")]
[numthreads(16, 16)]
void main(uint2 coord: SV_DispatchThreadID) {

    if (all(coord < ap.game.renderSize)) {

        float2 texcoord = (coord + 0.5) / ap.game.renderSize;

        float4 color = tex_main[coord];
        float4 normal = tex_normal[coord];

        float depth = ap.opaqueDepth[coord];

        // Space conversions
        float3 ndcPos = float3(texcoord * 2.0 - 1.0, depth);
        float3 viewPos = projectAndDivide(ap.camera.projectionInv, ndcPos);
        float3 playerPos = mul(ap.camera.viewInv, float4(viewPos, 1.0)).xyz;

        float3 sunLightPos = normalize(ap.celestial.sunPosition);

        if (depth > 0.0) {

        float3 shadow = getShadow(playerPos, normal.xyz);

        float3 sunLighting = shadow * max(0.0, dot(normal.xyz, sunLightPos));

        color.rgb = sunLighting;

        } else {
            float4 skyColor = pow(ap.world.skyColor, 2.2);
            color.rgb = skyColor.rgb;
        }

        tex_main[coord] = color;
    }
}