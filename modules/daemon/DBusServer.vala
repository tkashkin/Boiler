using GLib;
using Gee;

using Boiler;
using Boiler.Bluetooth;

using Boiler.Daemon.Data;

namespace Boiler.Daemon
{
	[DBus(name="com.github.tkashkin.boiler.Daemon")]
	public class DBusServer: Object
	{
		public string[] kettles;

		public string[] get_kettles()
		{
			return kettles;
		}

		public signal void kettle_added(string path);
		public signal void kettle_removed(string path);
	}

	public class Server
	{
		private DBusConnection dbus_conn;
		private uint bus_name_id;
		public DBusServer server;

		private ArrayList<DBusKettle> kettles = new ArrayList<DBusKettle>();

		public Server()
		{
			server = new DBusServer();
			bus_name_id = Bus.own_name(BusType.SESSION, "com.github.tkashkin.boiler.Daemon", BusNameOwnerFlags.NONE,
				on_bus_acquired, on_bus_name_acquired, on_bus_name_lost);
		}

		private void on_bus_acquired(DBusConnection conn, string name)
		{
			dbus_conn = conn;
			try
			{
				dbus_conn.register_object("/com/github/tkashkin/boiler/daemon", server);

				var btmgr = new Bluez.Manager();
				btmgr.discoverable = true;
				btmgr.start_discovery.begin();

				btmgr.device_added.connect(add_device);
				btmgr.device_removed.connect_after(remove_device);

				foreach(var device in btmgr.devices)
				{
					add_device(device);
				}
			}
			catch(IOError e)
			{
				error("Error registering DBusServer: %s", e.message);
			}
		}

		private void add_device(Bluez.Device device)
		{
			remove_device(device);
			var kettle = Devices.connect(device);
			if(kettle != null)
			{
				kettle.connect_async.begin();
				var dbus_kettle = new DBusKettle(kettle);
				kettles.add(dbus_kettle);
				dbus_kettle.dbus_id = dbus_conn.register_object(DBusKettle.path(dbus_kettle), dbus_kettle);
				server.kettle_added(DBusKettle.path(dbus_kettle));
			}
			update();
		}

		private void remove_device(Bluez.Device device)
		{
			foreach(var dbus_kettle in kettles)
			{
				if(dbus_kettle.kettle.bt_device == device)
				{
					server.kettle_removed(DBusKettle.path(dbus_kettle));
					dbus_conn.unregister_object(dbus_kettle.dbus_id);
					kettles.remove(dbus_kettle);
					break;
				}
			}
			update();
		}

		private void update()
		{
			var paths = new string[0];
			foreach(var dbus_kettle in kettles)
			{
				paths += DBusKettle.path(dbus_kettle);
			}
			server.kettles = paths;
		}

		private void on_bus_name_acquired(DBusConnection conn, string name)
		{

		}

		private void on_bus_name_lost(DBusConnection conn, string name)
		{

		}

		~Server()
		{
			Bus.unown_name(bus_name_id);
		}
	}
}
