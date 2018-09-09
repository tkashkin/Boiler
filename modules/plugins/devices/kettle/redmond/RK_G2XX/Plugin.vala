using GLib;

using Boiler;
using Boiler.Utils;
using Boiler.Bluetooth;

public class RK_G2XXPlugin: Boiler.BTKettlePlugin
{
	private const string[] DEVICES = { "RK-G200S", "RK-G210S", "RK-G211S" };
	private const string[] ICONS = { "RK-G200S", "RK-G210S", "RK-G211S" };

	public override string get_name(){ return "Redmond RK-G2XX support plugin"; }

	public override bool supports_device(string name)
	{
		return name in DEVICES;
	}
	public override bool has_device_icon(string name)
	{
		return name in ICONS;
	}
	public override Boiler.Devices.Abstract.BTKettle? create_device(Bluez.Device device, Bluez.Manager btmgr)
	{
		return new RK_G2XXDevice(device, btmgr);
	}
}

public static Type plugtype()
{
	return typeof(RK_G2XXPlugin);
}

public static RK_G2XXPlugin pluginit()
{
	return new RK_G2XXPlugin();
}
