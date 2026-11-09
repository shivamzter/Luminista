import aperture;
import settings;
import helper.util;

[shader("compute")]
[numthreads(16, 16)]
void main(uint2 coord: SV_DispatchThreadID) {

    if (all(coord < ap.game.renderSize)) {

        float depth = ap.opaqueDepth[coord];
        float2 texcoord = (coord + 0.5) / ap.game.renderSize;
    }
}