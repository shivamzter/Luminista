import dev.irisshaders.aperture.api.*;
import dev.irisshaders.aperture.api.objects.*;
import dev.irisshaders.aperture.api.pipeline.*;
import dev.irisshaders.aperture.api.renderer.*;

public class Luminista implements ShaderPack {

    public ArrayTexture tex_shadowColor;

    @Override
    public void configurePipeline(Screen screen, PipelineConfig pipeline) {

        final var translucentShadowUsages = new ProgramUsage[] {
			ProgramUsage.SHADOW_TERRAIN_TRANSLUCENT,
			ProgramUsage.SHADOW_ENTITY_TRANSLUCENT,
			ProgramUsage.SHADOW_BLOCK_ENTITY_TRANSLUCENT,
			ProgramUsage.SHADOW_PARTICLES_TRANSLUCENT
		};
        
        tex_shadowColor = pipeline.arrayTexture("tex_shadowColor", TextureFormat.RG11B10_UFLOAT).shadowSize().create();
    
        var tex_main = pipeline.texture2D("tex_main", TextureFormat.RGBA16_SFLOAT).renderSize().create();
        var tex_normal = pipeline.texture2D("tex_normal", TextureFormat.RGBA16_SFLOAT).renderSize().create();

        if (pipeline.settings().getBoolValue("SHADOW_ENABLED"))
        pipeline.object(ProgramUsage.SHADOW, "program/object/shadow_opaque", "ShadowOpaqueShader").writes("color", tex_shadowColor);

        for (var usage : translucentShadowUsages) {
            pipeline.object(usage, "program/object/shadow_translucent", "ShadowTranslucentShader").writes("color", tex_shadowColor);
        }

        pipeline.object(ProgramUsage.BASIC, "program/object/deferred", "DeferredShader").writes("color", tex_main).writes("normal", tex_normal);
        pipeline.object(ProgramUsage.TRANSLUCENT, "program/object/deferred", "DeferredShader").writes("color", tex_main).writes("normal", tex_normal);

        var sizeX_16 = Math.ceilDiv(screen.renderWidth(), 16);
        var sizeY_16 = Math.ceilDiv(screen.renderHeight(), 16);

        pipeline.stage(ProgramStage.PRE_TRANSLUCENT).compute("deferredLighting", "program/lighting/deferred", "main").dispatch2D(sizeX_16, sizeY_16);

        // pipeline.stage(ProgramStage.PRE_TRANSLUCENT).compute("histogramAverage", "compute/histogramAverage", "applyHistogramAverage").dispatch1D(1); //Calculate average
        // pipeline.object(ProgramUsage.SKYBOX, "program/object/basic", "BasicShader").writes("color", tex_main);

        pipeline.combinationPass("program/post/combination");
    }

    @Override
    public void configureRenderer(RendererConfig rendererConfig) {
        rendererConfig.setSunPathRotation(23.47f);
        rendererConfig.setShadowCascades(rendererConfig.getSettings().getIntValue("SHADOW_CASCADE_COUNT"));
        rendererConfig.setShadowDistance(rendererConfig.getSettings().getIntValue("SHADOW_DISTANCE"));
        rendererConfig.setShadowResolution(rendererConfig.getSettings().getIntValue("SHADOW_RESOLUTION"));
    }
}
