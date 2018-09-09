using GLib;
using Gee;

namespace Boiler.Application
{
	[DBus(name="com.github.tkashkin.boiler.Daemon")]
	public interface DBusServer: Object
	{
		public abstract string[] get_kettles();
		public signal void kettle_added(string path);
		public signal void kettle_removed(string path);
	}

	[DBus(name="com.github.tkashkin.boiler.Daemon.Data.Kettle")]
	public interface DBusKettle: Object
	{
		public abstract string device { owned get; set; }

		public abstract string name { owned get; set; }
		public abstract string description { owned get; set; }
		public abstract string status { owned get; set; }
		public abstract string pairing_info { owned get; set; }

		public abstract bool is_paired { owned get; set; }
		public abstract bool is_connected { owned get; set; }
		public abstract bool is_ready { owned get; set; }

		public abstract bool is_boiling { owned get; set; }
		public abstract int temperature { owned get; set; }

		public signal void update();

		public abstract void start_boiling() throws Error;
		public abstract void stop_boiling() throws Error;
		public abstract void toggle() throws Error;
	}

	public class DBusClient: Object
	{
		public signal void kettle_added(DBusKettle kettle);
		public signal void kettle_removed(DBusKettle kettle);

		private DBusServer server;
		private HashMap<string, DBusKettle> _kettles;

		public static DBusClient instance;

		construct
		{
			instance = this;

			_kettles = new HashMap<string, DBusKettle>();

			Bus.get_proxy.begin<DBusServer>(BusType.SESSION, "com.github.tkashkin.boiler.Daemon", "/com/github/tkashkin/boiler/daemon", DBusProxyFlags.NONE, null, (obj, res) => {
				try
				{
					server = Bus.get_proxy<DBusServer>.end(res);

					var sk = server.get_kettles();
					if(sk != null)
					{
						foreach(var path in sk)
						{
							add_kettle(path);
						}
					}

					server.kettle_added.connect(add_kettle);
					server.kettle_removed.connect(remove_kettle);
				}
				catch(Error e)
				{
					warning(e.message);
				}
			});
		}

		[CCode(instance_pos=-1)]
		private void add_kettle(string path)
		{
			debug("DBus path `%s` added", path);
			DBusKettle kettle = null;
			try
			{
				kettle = Bus.get_proxy_sync(BusType.SESSION, "com.github.tkashkin.boiler.Daemon", path, DBusProxyFlags.NONE);
				lock(_kettles)
				{
					_kettles.set(path, kettle);
				}
				kettle_added(kettle);
			}
			catch(Error e)
			{
				debug("Connecting to daemon failed: %s", e.message);
			}
		}

		[CCode(instance_pos=-1)]
		public void remove_kettle(string path)
		{
			debug("DBus path `%s` removed", path);
			lock(_kettles)
			{
				var kettle = _kettles.get(path);
				if(kettle != null)
				{
					_kettles.unset(path);
					kettle_removed(kettle);
					return;
				}
			}
		}

		public Collection<DBusKettle> kettles
		{
			owned get
			{
				lock(_kettles)
				{
					return _kettles.values;
				}
			}
		}
	}
}
