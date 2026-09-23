import dev.irisshaders.aperture.api.PackSettings;
import dev.irisshaders.aperture.api.settings.OptionType;
import dev.irisshaders.aperture.api.settings.SettingsManager;
import dev.irisshaders.aperture.api.settings.SettingsScreen;

public class LuministaSettings implements PackSettings {

    @Override
    public void createSettings(SettingsManager manager, SettingsScreen screen) {
		final var screenIndirectLighting = screen.child("indirectLighting");

		final var screenVanillaAO = screenIndirectLighting.child("vanillaAO");
		screenVanillaAO.option("VANILLA_AO", OptionType.boolType(true), false);
		screenVanillaAO.option("VANILLA_AO_INTENSITY", OptionType.floatType(0.01f, 1.0f, 0.01f, 1.0f), true);

		final var screenPostProcess = screen.child("postProcess");

		final var screenExposure = screenPostProcess.child("exposure");
		screenExposure.option("AUTO_EXPOSURE", OptionType.boolType(true), false);
		screenExposure.option("MANUAL_EXPOSURE", OptionType.floatType(0.0f, 5.0f, 0.1f, 0.0f), true);

		final var screenToneMapping = screenPostProcess.child("toneMapping");
		screenToneMapping.option("TONE_MAPPING", OptionType.enumType("ToneMapping", 1, "Reinhard", "Reinhard2", "ReinhardJodie", "ACES", "Neutral"), false);
    }
    
}
