using GLib;

namespace Boiler.Utils
{
	public uint8[] random_bytes(uint length, uint8[]? restricted_bytes=null)
	{
		uint8[] bytes = new uint8[length];

		for(uint i = 0; i < length; i++)
		{
			uint8 byte = 0;
			do
			{
				byte = (uint8) Random.int_range(0, 256);
			}
			while(restricted_bytes != null && byte in restricted_bytes);
			bytes[i] = byte;
		}

		return bytes;
	}

	public static string run(string[] cmd, string? dir=null, string[]? env=null)
	{
		string stdout;

		var cdir = dir ?? Environment.get_home_dir();
		var cenv = env ?? Environ.get();
		var ccmd = cmd;

		try
		{
			Process.spawn_sync(cdir, ccmd, cenv, SpawnFlags.SEARCH_PATH | SpawnFlags.STDERR_TO_DEV_NULL, null, out stdout);
		}
		catch (Error e)
		{
			warning(e.message);
		}
		return stdout;
	}
}
