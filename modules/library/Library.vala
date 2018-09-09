using GLib;

namespace Boiler
{
	public class LibBoiler
	{
		public static async void init()
		{
			yield Boiler.Devices.load_plugins({
				File.new_for_path("../plugins/devices/kettle"),
				File.new_for_path("plugins/devices/kettle"),
				File.new_for_path("modules/plugins/devices/kettle"),
				null
			});
		}
	}
}
