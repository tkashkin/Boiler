using GLib;
using Granite;

using Boiler;
using Boiler.Utils;

public class RK_G2XXSettings: Granite.Services.Settings
{
	public string auth_key { get; set; }

	public RK_G2XXSettings()
	{
		base(Config.PROJECT_NAME + ".plugins.devices.kettle.redmond.rk-g2xx");
		if(auth_key == "")
		{
			var bytes = RK_G2XXDevice.generate_auth_key();
			auth_key = Boiler.Converter.bin_to_hex(bytes, ' ');
		}
	}

	private static RK_G2XXSettings? instance;
	public static unowned RK_G2XXSettings get_instance()
	{
		if(instance == null)
		{
			instance = new RK_G2XXSettings();
		}
		return instance;
	}
}
