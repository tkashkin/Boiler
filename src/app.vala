using Gtk;
using Gdk;
using Granite;

namespace Boiler
{
	public class Application: Granite.Application
	{
		construct
		{
			application_id = ProjectConfig.PROJECT_NAME;
			flags = ApplicationFlags.FLAGS_NONE;
			program_name = "Boiler";
			build_version = ProjectConfig.VERSION;
		}

		protected override void activate()
		{
			weak IconTheme default_theme = IconTheme.get_default();
			default_theme.add_resource_path("/com/github/tkashkin/boiler/icons");

			var provider = new CssProvider();
			provider.load_from_resource("/com/github/tkashkin/boiler/Boiler.css");
			StyleContext.add_provider_for_screen(Screen.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

			new Boiler.UI.Windows.MainWindow(this).show_all();
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
				var bytes = Utils.random_bytes(8);
				rk_g2xx_auth.auth_key = Converter.bin_to_hex(bytes, ' ');
			}

			return app.run(args);
		}
	}
}
