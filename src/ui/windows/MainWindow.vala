using Gtk;

using Boiler.Settings;

using Boiler.UI.Views;
using Boiler.UI.Views.Connect;

namespace Boiler.UI.Windows
{
	public class MainWindow: Gtk.Dialog
	{
		public static MainWindow instance;
		
		private SavedState saved_state;
		
		private Stack stack;
		
		public MainWindow(Boiler.Application app)
		{
			Object(
				application: app,
				icon_name: ProjectConfig.PROJECT_NAME,
				resizable: false,
				title: _("Boiler"),
				window_position: WindowPosition.CENTER
			);
			instance = this;
		}
		
		construct
		{
			var header = new Gtk.HeaderBar();
			header.show_close_button = true;
			var header_context = header.get_style_context();
			header_context.add_class("titlebar");
			header_context.add_class("default-decoration");
			header_context.add_class(Gtk.STYLE_CLASS_FLAT);
			
			var context = get_style_context();
			context.add_class("rounded");
			context.add_class(Gtk.STYLE_CLASS_FLAT);
			
			set_titlebar(header);

			set_size_request(480, -1);
			
			var vbox = new Box(Orientation.VERTICAL, 0);
			
			stack = new Stack();
			stack.transition_type = StackTransitionType.CROSSFADE;
			stack.notify["visible-child"].connect(stack_updated);
			
			add_view(new ConnectView());
			
			vbox.add(stack);
			
			get_content_area().add(vbox);
			
			notify["has-toplevel-focus"].connect(() => {
				current_view.on_window_focus();
			});
			
			saved_state = SavedState.get_instance();
			
			delete_event.connect(() => { quit(); return false; });
			
			restore_saved_state();
		}
		
		public void add_view(BaseView view, bool show=true)
		{
			view.attach_to_window(this);
			stack.add(view);
			if(show)
			{
				stack.set_visible_child(view);
				view.show();
			}
			stack_updated();
		}
		
		private void stack_updated()
		{
			current_view.on_show();
		}
		
		private void restore_saved_state()
		{
			if(saved_state.window_x > -1 && saved_state.window_y > -1)
				move(saved_state.window_x, saved_state.window_y);
		}
		
		private void update_saved_state()
		{
			int x, y;
			get_position(out x, out y);
			saved_state.window_x = x;
			saved_state.window_y = y;
		}

		private void quit()
		{
			update_saved_state();
		}
		
		public BaseView current_view
		{
			get
			{
				return stack.visible_child as BaseView;
			}
		}
	}
}
