using Gtk;
using Gdk;
using Granite;

using Boiler.UI.Windows;

namespace Boiler
{
	public class Application: Granite.Application
	{
		private MainWindow? main_window;

		public static Application instance;

		public bool kettle_toggle_pending = false;
		public signal void toggle_kettle();

		construct
		{
			application_id = ProjectConfig.PROJECT_NAME;
			flags = ApplicationFlags.HANDLES_COMMAND_LINE;
			program_name = "Boiler";
			build_version = ProjectConfig.VERSION;
			instance = this;
		}

		protected override void activate()
		{
			if(main_window == null)
			{
				weak IconTheme default_theme = IconTheme.get_default();
				default_theme.add_resource_path("/com/github/tkashkin/boiler/icons");

				var provider = new CssProvider();
				provider.load_from_resource("/com/github/tkashkin/boiler/Boiler.css");
				StyleContext.add_provider_for_screen(Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

				main_window = new Boiler.UI.Windows.MainWindow(this);
				main_window.show_all();
			}
		}

		public static int main(string[] args)
		{
			#if USE_IVY
			Ivy.Stacktrace.register_handlers();
			#endif

			var app = new Application();

			var lang = Environment.get_variable("LC_ALL") ?? "";
			Intl.setlocale(LocaleCategory.ALL, lang);
			Intl.bindtextdomain(ProjectConfig.GETTEXT_PACKAGE, ProjectConfig.GETTEXT_DIR);
			Intl.textdomain(ProjectConfig.GETTEXT_PACKAGE);

			var rk_g2xx_auth = Settings.Dev.Redmond.RK_G2XX.get_instance();
			if(rk_g2xx_auth.auth_key == "")
			{
				var bytes = Boiler.Devices.Kettle.Redmond.RK_G2XX.generate_auth_key();
				rk_g2xx_auth.auth_key = Converter.bin_to_hex(bytes, ' ');
			}

			return app.run(args);
		}

		public override int command_line(ApplicationCommandLine cmd)
		{
			string[] oargs = cmd.get_arguments ();
			unowned string[] args = oargs;

			bool toggle = false;
			bool show = false;

			OptionEntry[] options = new OptionEntry[3];
			options[0] = { "toggle", 't', 0, OptionArg.NONE, out toggle, "Start or stop kettle", null };
			options[1] = { "show", 's', 0, OptionArg.NONE, out show, "Show window", null };
			options[2] = { null };

			var ctx = new OptionContext();
			ctx.add_main_entries(options, null);
			try
			{
				ctx.parse(ref args);
			}
			catch(Error e)
			{
				warning(e.message);
			}

			if(toggle)
			{
				kettle_toggle_pending = true;
				toggle_kettle();
			}

			activate();

			if(show) main_window.present();

			return 0;
		}
	}
}
