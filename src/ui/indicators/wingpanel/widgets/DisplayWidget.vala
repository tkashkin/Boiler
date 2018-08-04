using Gtk;
using GLib;
using Granite;
using Granite.Widgets;

public class Boiler.UI.Indicators.WP.Widgets.DisplayWidget: Gtk.Grid
{
	private Gtk.Image image;
	private Gtk.Label temp_label;

	private int temp = -1;

	construct
	{
		valign = Align.CENTER;

		image = new Image();
		image.icon_name = Boiler.ProjectConfig.PROJECT_NAME + "-symbolic";
		image.pixel_size = 24;

		temp_label = new Label("");
		temp_label.margin_start = 6;

		add(image);
		add(temp_label);

		temperature = temp;
	}

	public int temperature
	{
		get
		{
			return temp;
		}
		set
		{
			temp = value;
			temp_label.label = @"$(temp) \u2103";
		}
	}
}