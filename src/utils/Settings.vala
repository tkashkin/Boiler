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
			base(ProjectConfig.PROJECT_NAME + ".saved-state");
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
			base(ProjectConfig.PROJECT_NAME + ".devices");
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

	public class Dev.Redmond.RK_G2XX: Granite.Services.Settings
	{
		public string auth_key { get; set; }

		public RK_G2XX()
		{
			base(ProjectConfig.PROJECT_NAME + ".dev.redmond.rk-g2xx");
		}

		private static RK_G2XX? instance;
		public static unowned RK_G2XX get_instance()
		{
			if(instance == null)
			{
				instance = new RK_G2XX();
			}
			return instance;
		}
	}
}
