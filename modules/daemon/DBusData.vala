using GLib;

using Boiler;
using Boiler.Bluetooth;
using Boiler.Devices.Abstract;

namespace Boiler.Daemon.Data
{
	[DBus(name="com.github.tkashkin.boiler.Daemon.Data.Kettle")]
	public class DBusKettle: Object
	{
		public uint dbus_id;
		public BTKettle kettle;

		public string device { owned get; construct; }

		public string name { owned get { return kettle.name; } }
		public string description { owned get { return kettle.description; } }
		public string status { owned get { return kettle.status; } }
		public string pairing_info { owned get { return kettle.pairing_info; } }

		public bool is_paired { get { return kettle.is_paired; } }
		public bool is_connected { get { return kettle.is_connected; } }
		public bool is_ready { get { return kettle.is_ready; } }

		public bool is_boiling { get { return kettle.is_boiling; } }
		public int temperature { get { return kettle.temperature; } }

		public signal void update();

		public DBusKettle(BTKettle kettle)
		{
			Object(device: kettle.bt_device.address);
			this.kettle = kettle;

			this.kettle.notify["name"].connect(invoke_update);
			this.kettle.notify["description"].connect(invoke_update);
			this.kettle.notify["status"].connect(invoke_update);
			this.kettle.notify["pairing_info"].connect(invoke_update);
			this.kettle.notify["is-paired"].connect(invoke_update);
			this.kettle.notify["is-connected"].connect(invoke_update);
			this.kettle.notify["is-ready"].connect(invoke_update);
			this.kettle.notify["is-boiling"].connect(invoke_update);
			this.kettle.notify["temperature"].connect(invoke_update);
			invoke_update();
		}

		private void invoke_update()
		{
			update();
		}

		public void start_boiling() throws Error
		{
			kettle.start_boiling();
		}
		public void stop_boiling() throws Error
		{
			kettle.stop_boiling();
		}
		public void toggle() throws Error
		{
			kettle.toggle();
		}

		public static string path(DBusKettle dbus_kettle)
		{
			return "/com/github/tkashkin/boiler/daemon/kettles/" + dbus_kettle.kettle.bt_device.address.replace(":", "_");
		}
	}
}
