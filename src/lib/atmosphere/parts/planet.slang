implementing atmos_all;

public float3 playerToAtmosphere(float3 playerPos) {
    return fma(playerPos, rcp(1000.0), CAMERA_OFFSET_KM);
}

public float3 atmosphereToPlayer(float3 atmospherePos) {
    return (atmospherePos - CAMERA_OFFSET_KM) * 1000.0;
}

float2 sphIntersect(in float3 ro, in float3 rd, in float3 ce, float ra) {
    float3 oc = ro - ce;
    float b = dot(oc, rd);
    float3 qc = oc - b * rd;
    float h = ra * ra - dot(qc, qc);

    if (h < 0.0) return float2(-1.0); // no intersection
    h = sqrt(h);
    return float2(-b - h, -b + h);
}

public float earthShadow(float3 rayPos, float3 lightDir) {
    float3 localUpVec = normalize(rayPos) * 0.01;
    float2 earthShadowIntersection = sphIntersect(rayPos + localUpVec, lightDir, CENTER_OF_EARTH, EARTH_RADIUS_KM);
    return earthShadowIntersection.y < 0.0 ? 1.0 : 0.0;
}

bool getDistances(in float2 atmosLayerTop, in float2 atmosLayerBottom, inout float closestDistance, out float furthestDistance) {

    float atmosTopEntry = atmosLayerTop.x;
    float atmosTopExit = atmosLayerTop.y;

    float atmosBottomEntry = atmosLayerBottom.x;
    float atmosBottomExit = atmosLayerBottom.y;

    // ray didn't exit the top sphere, it missed the atmosphere entirely
    if (atmosTopExit < 0.0) {
        return false;
    } 

    // ray exited the top sphere but didn't enter, its origin is inside of the atmosphere
    else if (atmosTopEntry < 0.0) {
        closestDistance = 0.0;
        furthestDistance = atmosBottomEntry >= 0.0 ? min(atmosTopExit, atmosBottomEntry) : atmosTopExit;
        return true;
    }

    // ray entered and exited the top, it's origin is outside of the atmosphere
    else {
        closestDistance = atmosTopEntry;
        furthestDistance = atmosBottomEntry >= 0.0 ? min(atmosTopExit, atmosBottomEntry) : atmosTopExit;
        return true;
    }
}

public bool getRayMarchEndpoints(float3 rayOrigin, float3 rayDir, out float3 entryPointPosition, out float3 exitPointPosition) {

    float2 atmosLayerBottom = sphIntersect(rayOrigin, rayDir, CENTER_OF_EARTH, ATMOSPHERE_BOTTOM_RADIUS_KM);
    float2 atmosLayerTop = sphIntersect(rayOrigin, rayDir, CENTER_OF_EARTH, ATMOSPHERE_TOP_RADIUS_KM);

    float closestDistance = 0.0;
    float furthestDistance = 0.0;

    // Check if need to raymarch
    bool needToRayMarch = getDistances(atmosLayerTop, atmosLayerBottom, closestDistance, furthestDistance);

    entryPointPosition = rayOrigin + rayDir * closestDistance;
    exitPointPosition = rayOrigin + rayDir * furthestDistance;

    return needToRayMarch;
}

