import dev.irisshaders.aperture.api.PackSettings;
import dev.irisshaders.aperture.api.settings.OptionType;
import dev.irisshaders.aperture.api.settings.SettingsManager;
import dev.irisshaders.aperture.api.settings.SettingsScreen;

public class LuministaSettings implements PackSettings {

    @Override
    public void createSettings(SettingsManager manager, SettingsScreen screen) {
		final var screenResourcePack = screen.child("resourcePack");
		screenResourcePack.option("NORMAL_MAPPING", OptionType.boolType(true), false);
		screenResourcePack.option("MATERIAL_AO", OptionType.boolType(true), false);

		final var screenIndirectLighting = screen.child("indirectLighting");

		final var screenSSAO = screenIndirectLighting.child("ssao");
		screenSSAO.option("SSAO", OptionType.boolType(true), false);
		screenSSAO.option("SSAO_SAMPLE_COUNT", OptionType.intType(1, 16, 1, 16), true);
		screenSSAO.option("SSAO_RADIUS", OptionType.floatType(0.1f, 5.0f, 0.1f, 1.0f), true);

		final var screenVanillaAO = screenIndirectLighting.child("vanillaAO");
		screenVanillaAO.option("VANILLA_AO", OptionType.boolType(true), false);
		screenVanillaAO.option("VANILLA_AO_INTENSITY", OptionType.floatType(0.01f, 1.0f, 0.01f, 1.0f), true);

		final var screenShadow = screen.child("shadow");
        screenShadow.option("SHADOW_ENABLED", OptionType.boolType(true), false);
        screenShadow.option(
			"SHADOW_CASCADE_COUNT",
			OptionType.intType(1, 16, 1, 4),
			false
		);
        screenShadow.option(
			"SHADOW_RESOLUTION",
			OptionType.intType(512, 4096, 512, 2048),
			false
		);
        screenShadow.option(
			"SHADOW_DISTANCE",
			OptionType.intType(16, 1024, 16, 160),
			false
		);

		final var screenPostProcess = screen.child("postProcess");

		final var screenExposure = screenPostProcess.child("exposure");
		screenExposure.option("AUTO_EXPOSURE", OptionType.boolType(true), false);
		screenExposure.option("MANUAL_EXPOSURE", OptionType.floatType(0.0f, 5.0f, 0.1f, 0.0f), true);

		final var screenToneMapping = screenPostProcess.child("toneMapping");
		screenToneMapping.option("TONE_MAPPING", OptionType.enumType("ToneMapping", 1, "Reinhard", "PBRNeutral", "ReinhardLuminance"), false);
    }
    
}
