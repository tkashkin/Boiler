using Gtk;
using GLib;
using Granite;
using Granite.Widgets;
using Boiler.UI.Windows;
using Boiler.UI.Views.Kettle;

using Boiler.Bluetooth;
using Boiler.Devices.Abstract;

namespace Boiler.UI.Views.Connect
{
	public class ConnectView: BaseView
	{
		private Bluez.Manager btmgr;
		
		private Stack stack;
		private Grid devices_grid;
		private ListBox devices_list;
		private AlertView empty_view;
		
		construct
		{
			margin = column_spacing = 8;
			orientation = Orientation.HORIZONTAL;
			
			stack = new Stack();
			stack.transition_type = StackTransitionType.CROSSFADE;

			devices_grid = new Grid();
			devices_grid.valign = Align.CENTER;
			empty_view = new AlertView("No devices", "Make sure devices are in bluetooth range", "bluetooth");
			empty_view.get_style_context().remove_class(Gtk.STYLE_CLASS_VIEW);
			empty_view.get_children().data.margin = 0;

			var icon_overlay = new Overlay();
			icon_overlay.valign = Align.START;
			var icon = new Image.from_icon_name("bluetooth", IconSize.DIALOG);
			
			var spinner = new Spinner();
			spinner.valign = Align.END;
			spinner.halign = Align.END;
			spinner.set_size_request(16, 16);
			spinner.active = true;
			
			icon_overlay.add(icon);
			icon_overlay.add_overlay(spinner);
			
			devices_list = new ListBox();
			devices_list.get_style_context().add_class("devices-list");
			devices_list.hexpand = devices_list.vexpand = true;
			devices_list.valign = Align.CENTER;
			devices_list.selection_mode = SelectionMode.NONE;
			
			devices_grid.attach(icon_overlay, 0, 0);
			devices_grid.attach(devices_list, 1, 0);

			stack.add(empty_view);
			stack.add(devices_grid);

			stack.visible_child = empty_view;

			add(stack);
			
			btmgr = new Bluez.Manager();
			btmgr.discoverable = true;
			btmgr.start_discovery.begin();
			
			btmgr.device_added.connect(add_device);
			btmgr.device_removed.connect_after(remove_device);
			
			foreach(var device in btmgr.devices)
			{
				add_device(device);
			}
			
			btmgr.notify["retrieve-finished"].connect(() => spinner.active = !btmgr.retrieve_finished);
		}
		
		private void add_device(Bluez.Device device)
		{
			remove_device(device);
			if(device.name in Devices.SUPPORTED)
			{
				var row = new DeviceRow(device);
				row.connected.connect(kettle_connected);
				devices_list.add(row);
			}

			update_view();
		}
		
		private void remove_device(Bluez.Device device)
		{
			foreach(var row in devices_list.get_children())
			{
				if(((DeviceRow) row).device == device)
				{
					devices_list.remove(row);
					break;
				}
			}
			update_view();
		}

		private void update_view()
		{
			stack.visible_child = devices_list.get_children().length() > 0 ? devices_grid : empty_view;
		}

		private void kettle_connected(BTKettle kettle)
		{
			window.add_view(new KettleView(kettle));
		}
	}
}
