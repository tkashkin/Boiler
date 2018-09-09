using Gtk;
using Gdk;
using Granite;

using Boiler.Application.UI.Windows;

namespace Boiler.Application
{
	public class Application: Granite.Application
	{
		private MainWindow? main_window;

		public static Application instance;

		public bool kettle_toggle_pending = false;
		public signal void toggle_kettle();

		construct
		{
			application_id = Config.PROJECT_NAME;
			flags = ApplicationFlags.HANDLES_COMMAND_LINE;
			program_name = "Boiler";
			build_version = Config.VERSION;
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

				var loop = new MainLoop();
				Boiler.LibBoiler.init.begin((obj, res) => {
					Boiler.LibBoiler.init.end(res);
					main_window = new MainWindow(this);
					main_window.show_all();
					loop.quit();
				});
				loop.run();
			}
		}

		public static int main(string[] args)
		{
			Utils.run({ "systemctl", "--user", "start", "com.github.tkashkin.boiler.daemon.service" });

			var app = new Application();

			var lang = Environment.get_variable("LC_ALL") ?? "";
			Intl.setlocale(LocaleCategory.ALL, lang);
			Intl.bindtextdomain(Config.GETTEXT_PACKAGE, Config.GETTEXT_DIR);
			Intl.textdomain(Config.GETTEXT_PACKAGE);

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
