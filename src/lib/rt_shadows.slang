public module rt_shadows;

import aperture;
import settings;
import rt_pipeline;
import helper.util;

public static float3 getShadow(float3 albedo, float3 localPos, float3 normal) {

    float3 color = float3(1.0);

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

        let hitColor = surface.albedo().sampleLevel(surface.getUV(), 0.0) * surface.getColor();

        if (hitColor.a >= 0.99) {
            query.acceptCandidate();
        } else {
            float3 hitAlbedo = srgbToLinear(hitColor.rgb);
            color *= lerp(albedo, hitAlbedo, hitColor.a);
        }
    }

    if (query.hasHit()) {
        return 0.0;
    };

    return color;
}