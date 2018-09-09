using GLib;

namespace Boiler
{
	public errordomain PluginLoadError { NOT_FOUND, NOT_SUPPORTED, UNEXPECTED_TYPE, NO_PLUGINIT, FAILED }

	private class PlugInfo: Object
	{
		public Module module;
		public Type gtype;
		public PlugInfo(Type type, owned Module module)
		{
			this.module = (owned) module;
			this.gtype = type;
		}
	}

	public class PluginLoader
	{
		private static PlugInfo[]? loaded = null;
		private static Plugin[]? plugins = null;

		[CCode(has_target=false)]
		private delegate Type PlugTypeFunc();

		[CCode(has_target=false)]
		private delegate Plugin PlugInitFunc();

		public static Plugin load(File? file) throws PluginLoadError
		{
			if(loaded == null)
			{
				loaded = new PlugInfo[0];
			}
			if(plugins == null)
			{
				plugins = new Plugin[0];
			}

			var plugpath = file != null ? file.get_path() : "null";

			if(file == null || !file.query_exists())
			{
				throw new PluginLoadError.NOT_FOUND(@"Plugin '$(plugpath)' not found");
			}

			Module module = Module.open(plugpath, ModuleFlags.BIND_LAZY);
			if(module == null)
			{
				throw new PluginLoadError.FAILED(Module.error());
			}

			void* plugtype_ptr;
			module.symbol("plugtype", out plugtype_ptr);
			unowned PlugTypeFunc plugtype = (PlugTypeFunc) plugtype_ptr;
			if(plugtype_ptr == null || plugtype == null)
			{
				throw new PluginLoadError.NO_PLUGINIT(@"Plugin '$(plugpath)' does not have plugtype()");
			}

			var type = plugtype();
			if(!type.is_a(typeof(Plugin)))
			{
				throw new PluginLoadError.UNEXPECTED_TYPE("Plugin '$(plugpath)' does not have inherit Plugin");
			}

			var plugin = Object.new(type) as Plugin;

			if(plugin == null)
			{
				throw new PluginLoadError.FAILED(@"Plugin '$(plugpath)': failed to create instance'");
			}

			loaded += new PlugInfo(type, (owned) module);
			plugins += plugin;

			debug(@"Plugin '$(plugpath)': %s", plugin.get_name());

			plugin.plugmain();

			return plugin;
		}
	}
}
