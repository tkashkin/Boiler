using GLib;

using Boiler.Bluetooth;

namespace Boiler.Devices
{
	public const string[] SUPPORTED = { "RK-G200S", "RK-G211S" };
	public const string[] WITH_ICONS = { "RK-G200S" };
	
	public static Boiler.Devices.Abstract.BTKettle? connect(Bluez.Device device)
	{
		if(device.name in Boiler.Devices.Kettle.Redmond.RK_G2XX.DEVICES)
		{
			return new Boiler.Devices.Kettle.Redmond.RK_G2XX(device, Bluez.Manager.instance);
		}
		return null;
	}
}
