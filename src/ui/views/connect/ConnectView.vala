using Gtk;
using GLib;
using Granite;
using Boiler.UI.Windows;

using Boiler.Bluetooth;

namespace Boiler.UI.Views.Connect
{
	public class ConnectView: BaseView
	{
		private Bluez.Manager btmgr;
		
		private ListBox devices_list;
		
		construct
		{
			margin = column_spacing = 8;
			orientation = Orientation.HORIZONTAL;
			
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
			
			attach(icon_overlay, 0, 0);
			attach(devices_list, 1, 0);
			
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
			//if(device.name in Devices.SUPPORTED)
				devices_list.add(new DeviceRow(device));
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
		}
	}
}
