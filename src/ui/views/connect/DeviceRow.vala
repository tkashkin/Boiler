using Gtk;

using Boiler.Bluetooth;

class Boiler.UI.Views.Connect.DeviceRow: Gtk.ListBoxRow
{
	public Bluez.Device device { get; construct; }
	
	private Boiler.Devices.Abstract.BTKettle? kettle;
	
	private Label label;
	private ToggleButton? boil_btn;

	public DeviceRow(Bluez.Device device)
	{
		Object(device: device);
	}

	construct
	{
		var icon = device.icon ?? "bluetooth";
		if(device.name in Devices.WITH_ICONS) icon = "device-" + device.name;
		
		var image = new Image.from_icon_name(icon, IconSize.DND);

		label = new Label(device.name ?? device.address);
		label.ellipsize = Pango.EllipsizeMode.END;
		label.hexpand = true;
		label.xalign = 0;

		var hbox = new Box(Orientation.HORIZONTAL, 8);
		hbox.margin = 8;
		hbox.add(image);
		hbox.add(label);
		
		kettle = Devices.connect(device);
		if(kettle != null)
		{
			kettle.notify["temperature"].connect(update);
			kettle.notify["is-boiling"].connect(update);
			
			boil_btn = new ToggleButton.with_label("Boil");
			
			boil_btn.toggled.connect(() => {
				if(boil_btn.active && !kettle.is_boiling)
				{
					kettle.start_boiling();
				}
				else if(!boil_btn.active && kettle.is_boiling)
				{
					kettle.stop_boiling();
				}
			});
			
			hbox.add(boil_btn);
		}

		child = hbox;
		show_all();
	}
	
	private void update()
	{
		if(kettle == null || boil_btn == null) return;
		
		label.label = @"$(device.name): $(kettle.temperature)°; " + (kettle.is_boiling ? "boiling" : "");
		boil_btn.active = kettle.is_boiling;
	}
}
