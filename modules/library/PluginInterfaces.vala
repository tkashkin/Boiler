using GLib;

namespace Boiler
{
	public abstract class Plugin: Object
	{
		public abstract string get_name();
		public virtual void plugmain(){}
	}

	public abstract class BTKettlePlugin: Plugin
	{
		public abstract bool supports_device(string name);
		public abstract bool has_device_icon(string name);
		public abstract Boiler.Devices.Abstract.BTKettle? create_device(Boiler.Bluetooth.Bluez.Device device, Boiler.Bluetooth.Bluez.Manager btmgr);
	}
}
