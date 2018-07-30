using GLib;

using Boiler.Bluetooth;

public abstract class Boiler.Devices.Abstract.BTKettle: Object
{
	public Bluez.Device bt_device { get; construct; }
	public Bluez.Manager btmgr { get; construct; }
	
	public int temperature { get; protected set; default = -1; }
	public bool is_boiling { get; protected set; default = false; }
	
	public abstract void start_boiling();
	public abstract void stop_boiling();
}
