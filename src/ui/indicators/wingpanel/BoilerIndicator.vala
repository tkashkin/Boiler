using Gtk;
using GLib;
using Granite;
using Granite.Widgets;

using Boiler.UI.Indicators.WP.Widgets;

public class Boiler.UI.Indicators.WP.BoilerIndicator: Wingpanel.Indicator
{
	DisplayWidget? display_widget = null;
	//PopoverWidget? popover_widget = null;

	public BoilerIndicator()
	{

		Object(
			code_name: "boiler",
			display_name: "Boiler",
			description: _("Boiler indicator"),
			visible: true
		);

		display_widget = new DisplayWidget();
		//popover_widget = new PopoverWidget();
	}

	public override Gtk.Widget get_display_widget()
	{
		return display_widget;
	}

	public override Gtk.Widget? get_widget()
	{
		return null; //popover_widget;
	}

	public override void opened()
	{
		/*if(popover_widget != null)
		{
			popover_widget.opened();
		}*/
	}

	public override void closed()
	{
		/*if(popover_widget != null)
		{
			popover_widget.closed();
		}*/
	}
}

public Wingpanel.Indicator get_indicator(Module module, Wingpanel.IndicatorManager.ServerType server_type)
{
	debug("Activating Boiler indicator");

	var lang = Environment.get_variable("LC_ALL") ?? "";
	Intl.setlocale(LocaleCategory.ALL, lang);
	Intl.bindtextdomain(Boiler.ProjectConfig.GETTEXT_PACKAGE, Boiler.ProjectConfig.GETTEXT_DIR);
	Intl.textdomain(Boiler.ProjectConfig.GETTEXT_PACKAGE);

	weak IconTheme default_theme = IconTheme.get_default();
	default_theme.add_resource_path("/com/github/tkashkin/boiler/icons");

	return new Boiler.UI.Indicators.WP.BoilerIndicator();
}