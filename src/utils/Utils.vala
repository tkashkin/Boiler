using GLib;

namespace Boiler.Utils
{
	public uint8[] random_bytes(uint length)
	{
		uint8[] bytes = new uint8[length];

		for(uint i = 0; i < length; i++)
		{
			bytes[i] = (uint8) Random.int_range(0, 256);
		}

		return bytes;
	}
}