import aperture;
import lib.shadow;

RWTexture2D tex_main;
RWTexture2D tex_normal;

[shader("compute")]
[numthreads(16, 16)]
void main(uint2 coord: SV_DispatchThreadID) {

    if (all(coord < ap.game.renderSize)) {

        float4 color = tex_main[coord];
        float4 normal = tex_normal[coord];

        float depth = ap.opaqueDepth[coord];
    

        tex_main[coord] = color;
    }
}