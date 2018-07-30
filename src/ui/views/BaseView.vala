using Gtk;
using Granite;
using Boiler.UI.Windows;

namespace Boiler.UI.Views
{
	public abstract class BaseView: Gtk.Grid
	{
		protected MainWindow window;
		
		construct
		{
		    
		}
		
		public virtual void attach_to_window(MainWindow wnd)
		{
			window = wnd;
			show();
		}
		
		public virtual void on_show()
		{
			
		}
		
		public virtual void on_window_focus()
		{
			
		}
	}
}
