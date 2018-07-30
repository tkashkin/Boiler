namespace Boiler.Converter
{
	public void int64_to_bin(int64 val, out uint8[] result)
	{
		var size = (int) sizeof(int64);
		result = new uint8[size];
		for (int i = size - 1; i >= 0; i--)
		{
			result[i] = (uint8)(val & 0xFF);
			val >>= 8;
		}
	}

	public bool bin_to_int64(uint8[] array, out int64 result)
	{
		result = 0;
		if (array.length > sizeof(int64))
			return false;
		
		for (int i = 0; i < array.length; i++)
		{
			result <<= 8;
			result |= (int64)(array[i] & 0xFF);
		}
		return true;
	}

	public string bin_to_hex(uint8[] array, char separator='\0')
	{
		var size = separator == '\0' ? 2 * array.length : 3 * array.length - 1;
		var buffer = new StringBuilder.sized(size);
		bin_to_hex_buf(array, buffer, separator);
		return buffer.str;
	}

	public void bin_to_hex_buf(uint8[] array, StringBuilder buffer, char separator='\0')
	{
		string hex_chars = "0123456789abcdef";
		for (var i = 0; i < array.length; i++)
		{
			if (i > 0 && separator != '\0')
				buffer.append_c(separator);
			buffer.append_c(hex_chars[(array[i] >> 4) & 0x0F]).append_c(hex_chars[array[i] & 0x0F]);
		}
	}

	public bool uint8v_equal(uint8[] array1, uint8[] array2)
	{
		if (array1.length != array2.length)
			return false;
		for (var i = 0; i < array1.length; i++)
			if (array1[i] != array2[i])
				return false;
		return true;
	}

	public bool hex_to_bin(string hex, out uint8[] result, char separator='\0')
	{
		result = null;
		unowned uint8[] hex_data = (uint8[]) hex;
		hex_data.length = hex.length;
		return_val_if_fail(hex != null && hex_data.length > 0, false);
		
		int size = hex_data.length;
		if (separator != '\0')
		{
			// "aa:bb:cc" -> 8 chars, 3 bytes 
			size++;
			if (size % 3 != 0)
				return false;
			size /= 3;
		}
		else
		{
			// "aabbcc" -> 6 chars, 3 bytes
			if (size % 2 != 0)
				return false;
			size /= 2;
		}
		
		result = new uint8[size];
		uint8 c;
		uint8 j;
		for(int i = 0, pos = 0; (c = hex_data[pos++]) != 0 && i < 2 * size; i++)
		{
			if (c == separator)
			{
				i--;
				continue;
			}
			
			switch (c)
			{
				 case '0': j = 0; break;
		         case '1': j = 1; break;
		         case '2': j = 2; break;
		         case '3': j = 3; break;
		         case '4': j = 4; break;
		         case '5': j = 5; break;
		         case '6': j = 6; break;
		         case '7': j = 7; break;
		         case '8': j = 8; break;
		         case '9': j = 9; break;
		         case 'A': j = 10; break;
		         case 'B': j = 11; break;
		         case 'C': j = 12; break;
		         case 'D': j = 13; break;
		         case 'E': j = 14; break;
		         case 'F': j = 15; break;
		         case 'a': j = 10; break;
		         case 'b': j = 11; break;
		         case 'c': j = 12; break;
		         case 'd': j = 13; break;
		         case 'e': j = 14; break;
		         case 'f': j = 15; break;
		         default: 
					return false;
			}
			
			if(i % 2 == 0)
				result[i/2] += (j << 4);
			else
				result[i/2] += j;
		}
		return true;
	}

	public bool hex_to_int64(string hex, out int64 result, char separator='\0')
	{
		uint8[] data;
		return_val_if_fail(hex_to_bin(hex, out data, separator), false);
		return_val_if_fail(bin_to_int64(data, out result), false);
		return true;
	}

	public string int64_to_hex(int64 val, char separator='\0')
	{
		uint8[] data;
		int64_to_bin(val, out data);
		return bin_to_hex(data, separator);
	}

	public void uint32_to_bytes(ref uint8[] buffer, uint32 data, uint offset=0)
	{
		var size = sizeof(uint32);
		assert(buffer.length >= offset + size);
		for(var i = 0; i < size; i ++)
			buffer[offset + i] = (uint8)((data >> ((size - 1 - i) * 8)) & 0xFF);
	}

	public void int32_to_bytes(ref uint8[] buffer, int32 data, uint offset=0)
	{
		var size = sizeof(int32);
		assert(buffer.length >= offset + size);
		for(var i = 0; i < size; i ++)
			buffer[offset + i] = (uint8)((data >> ((size - 1 - i) * 8)) & 0xFF);
	}

	public void uint32_from_bytes(uint8[] buffer, out uint32 data, uint offset=0)
	{
		var size = sizeof(uint32);
		assert(buffer.length >= offset + size);
		data = 0;
		for(var i = 0; i < size; i ++)
			data += buffer[offset + i] * (1 << ((uint32)size - 1 - i) * 8);
	}
	
	public void int32_from_bytes(uint8[] buffer, out int32 data, uint offset=0)
	{
		var size = sizeof(int32);
		assert(buffer.length >= offset + size);
		data = 0;
		for(var i = 0; i < size; i ++)
			data += buffer[offset + i] * (1 << ((int32)size - 1 - i) * 8);
	}
}
