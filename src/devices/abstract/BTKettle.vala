using GLib;

using Boiler.Bluetooth;

public abstract class Boiler.Devices.Abstract.BTKettle: Object
{
	public Bluez.Device bt_device { get; construct; }
	public Bluez.Manager btmgr { get; construct; }
	
	public string name { get; protected set; default = ""; }
	public string description { get; protected set; default = ""; }
	public string status { get; protected set; default = ""; }
	public string? pairing_info { get; protected set; default = null; }

	public bool is_paired { get; protected set; default = true; }
	public bool is_connected { get; protected set; default = false; }

	public bool is_boiling { get; protected set; default = false; }
	public int temperature { get; protected set; default = -1; }
	
	public abstract void start_boiling();
	public abstract void stop_boiling();
}
