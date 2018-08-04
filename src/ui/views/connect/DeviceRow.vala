using Gtk;

using Boiler.Bluetooth;
using Boiler.Devices.Abstract;

class Boiler.UI.Views.Connect.DeviceRow: Gtk.ListBoxRow
{
	public Bluez.Device device { get; construct; }
	
	private BTKettle? kettle;
	
	public signal void connected(BTKettle kettle);

	public DeviceRow(Bluez.Device device)
	{
		Object(device: device);
	}

	construct
	{
		var icon = device.icon ?? "bluetooth";
		if(device.name in Devices.WITH_ICONS) icon = "device-" + device.name;
		
		var image = new Image.from_icon_name(icon, IconSize.DND);

		var label = new Label(device.name ?? device.address);
		label.ellipsize = Pango.EllipsizeMode.END;
		label.hexpand = true;
		label.xalign = 0;

		var hbox = new Box(Orientation.HORIZONTAL, 8);
		hbox.margin = 8;
		hbox.add(image);
		hbox.add(label);
		
		if(device.name in Devices.SUPPORTED)
		{
			var connect_btn = new Button.with_label("Connect");
			
			connect_btn.clicked.connect(() => {
				kettle = Devices.connect(device);
				if(kettle != null) connected(kettle);
			});
			
			hbox.add(connect_btn);
		}

		child = hbox;
		show_all();
	}
}
