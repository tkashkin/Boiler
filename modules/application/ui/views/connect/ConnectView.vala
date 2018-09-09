using Gtk;
using GLib;
using Granite;
using Granite.Widgets;
using Boiler.Application.UI.Windows;
using Boiler.Application.UI.Views.Kettle;

namespace Boiler.Application.UI.Views.Connect
{
	public class ConnectView: BaseView
	{
		private DBusClient dbus_client;

		private Stack stack;
		private Grid kettles_grid;
		private ListBox kettles_list;
		private AlertView empty_view;

		construct
		{
			margin = column_spacing = 8;
			orientation = Orientation.HORIZONTAL;

			stack = new Stack();
			stack.transition_type = StackTransitionType.CROSSFADE;

			kettles_grid = new Grid();
			kettles_grid.valign = Align.CENTER;
			empty_view = new AlertView(_("No devices"), _("Make sure devices are in bluetooth range"), "bluetooth");
			empty_view.get_style_context().remove_class(Gtk.STYLE_CLASS_VIEW);
			empty_view.get_children().data.margin = 0;

			var icon = new Image.from_icon_name("bluetooth", IconSize.DIALOG);
			icon.valign = Align.START;

			kettles_list = new ListBox();
			kettles_list.get_style_context().add_class("devices-list");
			kettles_list.hexpand = kettles_list.vexpand = true;
			kettles_list.valign = Align.CENTER;
			kettles_list.selection_mode = SelectionMode.NONE;

			kettles_grid.attach(icon, 0, 0);
			kettles_grid.attach(kettles_list, 1, 0);

			stack.add(empty_view);
			stack.add(kettles_grid);

			stack.visible_child = empty_view;

			add(stack);

			dbus_client = new DBusClient();

			dbus_client.kettle_added.connect(add_kettle);
			dbus_client.kettle_removed.connect_after(remove_kettle);

			foreach(var kettle in dbus_client.kettles)
			{
				add_kettle(kettle);
			}
		}

		private void add_kettle(DBusKettle kettle)
		{
			remove_kettle(kettle);
			var row = new KettleRow(kettle);
			row.connected.connect(kettle_connected);
			kettles_list.add(row);
			update_view();
		}

		private void remove_kettle(DBusKettle kettle)
		{
			foreach(var row in kettles_list.get_children())
			{
				if(((KettleRow) row).kettle.device == kettle.device)
				{
					kettles_list.remove(row);
					break;
				}
			}
			update_view();
		}

		private void update_view()
		{
			var view = kettles_list.get_children().length() > 0 ? kettles_grid : empty_view;
			kettles_grid.hide();
			empty_view.hide();
			stack.visible_child = view;
			view.show();
		}

		private void kettle_connected(DBusKettle kettle)
		{
			window.add_view(new KettleView(kettle));
		}
	}
}
