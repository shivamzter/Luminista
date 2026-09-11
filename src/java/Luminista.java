import dev.irisshaders.aperture.api.*;
import dev.irisshaders.aperture.api.objects.*;
import dev.irisshaders.aperture.api.pipeline.*;
import dev.irisshaders.aperture.api.renderer.*;

public class Luminista implements ShaderPack {

    public ArrayTexture shadowColor;

    @Override
    public void configurePipeline(Screen screen, PipelineConfig pipeline) {

        final var translucentShadowUsages = new ProgramUsage[] {
			ProgramUsage.SHADOW_TERRAIN_TRANSLUCENT,
			ProgramUsage.SHADOW_ENTITY_TRANSLUCENT,
			ProgramUsage.SHADOW_BLOCK_ENTITY_TRANSLUCENT,
			ProgramUsage.SHADOW_PARTICLES_TRANSLUCENT
		};

        shadowColor = pipeline.arrayTexture("texShadowColor", TextureFormat.RG11B10_UFLOAT).shadowSize().create();
    
        var mainTexture = pipeline.texture2D("mainTexture", TextureFormat.RGBA16_SFLOAT).renderSize().create();

        if (pipeline.settings().getBoolValue("SHADOW_ENABLED"))
        pipeline.object(ProgramUsage.SHADOW, "object/shadow", "ShadowShader");

        for (var usage : translucentShadowUsages) {
            pipeline.object(usage, "object/shadow_translucent", "translucentShadowShader").writes("color", shadowColor);
        }

        pipeline.object(ProgramUsage.BASIC, "object/basic", "BasicShader").writes("color", mainTexture);
        pipeline.object(ProgramUsage.TRANSLUCENT, "object/basic", "BasicShader").writes("color", mainTexture);
    }

    @Override
    public void configureRenderer(RendererConfig rendererConfig) {
        rendererConfig.setSunPathRotation(23.47f);
        rendererConfig.setShadowCascades(rendererConfig.getSettings().getIntValue("SHADOW_CASCADE_COUNT"));
        rendererConfig.setShadowDistance(rendererConfig.getSettings().getIntValue("SHADOW_DISTANCE"));
        rendererConfig.setShadowResolution(rendererConfig.getSettings().getIntValue("SHADOW_RESOLUTION"));
    }
}
