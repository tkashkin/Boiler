using GLib;

using Boiler;

namespace Boiler.Daemon
{
	public class Daemon
	{
		public static Daemon instance;

		private Server dbus_server;
		private MainLoop loop;

		private const OptionEntry[] options = {
			{ "debug", 'd', 0, OptionArg.NONE, out opt_debug, N_("Print debug information"), null},
			{ "version", 'v', 0, OptionArg.NONE, out opt_version, N_("Print version info and exit"), null},
			{ null }
		};
		private static bool opt_debug;
		private static bool opt_version;

		public Daemon()
		{
			loop = new MainLoop();
		}

		public int run(string[] args)
		{
			Process.signal(ProcessSignal.INT, quit);
			Process.signal(ProcessSignal.TERM, quit);

			OptionContext context = new OptionContext("");
			context.add_main_entries(options, null);

			try
			{
				context.parse(ref args);
			}
			catch(OptionError e)
			{
				error(e.message);
			}

			Granite.Services.Logger.initialize("Boiler daemon");
			Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.WARN;

			if(opt_debug)
			{
				Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;
			}

			if(opt_version)
			{
				message("Boiler daemon");
				message("Version: %s", Config.VERSION);
				return 0;
			}

			Boiler.LibBoiler.init.begin((obj, res) => {
				Boiler.LibBoiler.init.end(res);
				dbus_server = new Server();
			});

			loop.run();
			return 0;
		}

		public void quit()
		{
			loop.quit();
		}

		public static int main(string[] args)
		{
			instance = new Daemon();
			return instance.run(args);
		}
	}
}
