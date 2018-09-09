using GLib;
using Gee;

using Boiler.Bluetooth;

namespace Boiler.Devices
{
	private static ArrayList<BTKettlePlugin> plugins;

	public static async void load_plugins(File?[] dirs)
	{
		foreach(var dir in dirs)
		{
			if(dir == null || dir.query_exists())
			{
				yield load_plugins_recursive(dir);
				break;
			}
		}
	}

	public static async void load_plugins_recursive(File? dir=null)
	{
		dir = dir ?? File.new_for_path(Config.PLUGDIR).get_child("devices").get_child("kettle");

		debug(dir.get_path());

		if(!dir.query_exists()) return;

		try
		{
			FileInfo? finfo = null;
			var enumerator = yield dir.enumerate_children_async("standard::*", FileQueryInfoFlags.NONE);
			while((finfo = enumerator.next_file()) != null)
			{
				var child = dir.get_child(finfo.get_name());

				if(finfo.get_file_type() == FileType.DIRECTORY)
				{
					yield load_plugins_recursive(child);
				}
				else if(finfo.get_name().has_suffix(".so"))
				{
					try
					{
						yield load_plugin(child);
					}
					catch(Error e)
					{
						warning(e.message);
					}
				}
			}
		}
		catch(Error e)
		{
			warning(e.message);
		}
	}

	public static async BTKettlePlugin load_plugin(File? file) throws PluginLoadError
	{
		if(plugins == null)
		{
			plugins = new ArrayList<BTKettlePlugin>();
		}

		var plugin = PluginLoader.load(file);
		if(!(plugin is BTKettlePlugin))
		{
			throw new PluginLoadError.UNEXPECTED_TYPE(@"Plugin '$(plugin.get_name())' is not derived from BTKettlePlugin");
		}

		var kp = plugin as BTKettlePlugin;

		if(kp == null)
		{
			throw new PluginLoadError.FAILED(@"Plugin '$(plugin.get_name())': can't cast to BTKettlePlugin");
		}

		plugins.add(kp);
		return kp;
	}

	public static bool is_supported(string device_name, out BTKettlePlugin? plugin=null)
	{
		plugin = null;
		foreach(var p in plugins)
		{
			if(p.supports_device(device_name))
			{
				plugin = p;
				return true;
			}
		}
		return false;
	}

	public static bool has_icon(string device_name, out BTKettlePlugin? plugin=null)
	{
		plugin = null;
		foreach(var p in plugins)
		{
			if(p.has_device_icon(device_name))
			{
				plugin = p;
				return true;
			}
		}
		return false;
	}

	public static Boiler.Devices.Abstract.BTKettle? connect(Bluez.Device device)
	{
		BTKettlePlugin plugin;
		if(is_supported(device.name, out plugin) && plugin != null)
		{
			return plugin.create_device(device, Bluez.Manager.instance);
		}
		return null;
	}

	public static string get_icon(string device_name, string def="bluetooth")
	{
		if(has_icon(device_name))
		{
			return "device-" + device_name;
		}
		return def;
	}
}
