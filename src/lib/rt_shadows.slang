public module rt_shadows;

import aperture;
import settings;
import rt_pipeline;

public static float3 getShadow(float3 localPos, float3 normal) {

    float3 color = 1.0;

    var query = HWRT.startQuery(
        localPos + 0.002 * normal,
        normalize(ap.celestial.position),
        0.0, max(ap.world.renderDistance, 1.0),
        HWRT.HitType.TERRAIN | HWRT.HitType.ENTITY,
        HWRT.RTFlags.ACCEPT_FIRST_HIT_AND_END_SEARCH
    );

    while(query.proceed()) {
        let hit = query.getCandidate();

        var surface = HWRT.decodeHit(hit);

        float2 hit_uv = surface.getUV();
        let hit_color = surface.albedo().sampleLevel(hit_uv, 0.0) * surface.getColor();

        if (hit_color.a >= 0.99) {
            query.acceptCandidate();
        } else {
            color *= (1.0 - pow(hit_color.a, 2.0));
        }

    }

    if (query.hasHit()) {
        return 0.0;
    };

    return color;
}