using GLib;
using Granite;

namespace Boiler.Settings
{
	public class SavedState: Granite.Services.Settings
	{
		public int window_x { get; set; }
		public int window_y { get; set; }

		public SavedState()
		{
			base(Config.PROJECT_NAME + ".saved-state");
		}

		private static SavedState? instance;
		public static unowned SavedState get_instance()
		{
			if(instance == null)
			{
				instance = new SavedState();
			}
			return instance;
		}
	}

	public class Devices: Granite.Services.Settings
	{
		public string last_device { get; set; }

		public Devices()
		{
			base(Config.PROJECT_NAME + ".devices");
		}

		private static Devices? instance;
		public static unowned Devices get_instance()
		{
			if(instance == null)
			{
				instance = new Devices();
			}
			return instance;
		}
	}
}
