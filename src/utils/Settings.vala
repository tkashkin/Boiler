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
}
