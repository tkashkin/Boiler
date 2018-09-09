using Gtk;

using Boiler.Bluetooth;
using Boiler.Devices.Abstract;

class Boiler.Application.UI.Views.Connect.KettleRow: ListBoxRow
{
	public DBusKettle kettle { get; construct; }

	public signal void connected(DBusKettle kettle);

	public KettleRow(DBusKettle kettle)
	{
		Object(kettle: kettle);
	}

	construct
	{
		var icon = Devices.get_icon(kettle.name);

		var image = new Image.from_icon_name(icon, IconSize.DND);

		var label = new Label(kettle.name ?? kettle.device);
		label.ellipsize = Pango.EllipsizeMode.END;
		label.hexpand = true;
		label.xalign = 0;

		var hbox = new Box(Orientation.HORIZONTAL, 8);
		hbox.margin = 8;
		hbox.add(image);
		hbox.add(label);

		var connect_btn = new Button.with_label(_("Connect"));

		var settings = Boiler.Settings.Devices.get_instance();

		connect_btn.clicked.connect(() => {
			settings.last_device = kettle.device;
			connected(kettle);
		});

		if(settings.last_device == kettle.device)
		{
			Idle.add(() => {
				connect_btn.clicked();
				return Source.REMOVE;
			});
		}

		hbox.add(connect_btn);

		child = hbox;
		show_all();
	}
}
