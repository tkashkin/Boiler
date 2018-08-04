using GLib;

using Boiler.Bluetooth;

public class Boiler.Devices.Kettle.Redmond.RK_G2XX: Boiler.Devices.Abstract.BTKettle
{
	public const string[] DEVICES = { "RK-G200S", "RK-G211S" };
	
	private bool is_authenticated = false;
	private bool status_thread_running = false;
	private uint8 counter = 0;
	
	private HashTable<string, Variant> _params = new HashTable<string, Variant>(str_hash, null);
	
	private Bluez.GATTCharacteristic? cmd_char;
	private Bluez.GATTCharacteristic? res_char;
	
	public RK_G2XX(Bluez.Device device, Bluez.Manager btmgr)
	{
		Object(bt_device: device, btmgr: btmgr);
		
		connect();
	}

	private void connect()
	{
		if(is_connected) return;
		
		log("Connecting to %s [%s]".printf(bt_device.name, bt_device.address));

		try
		{
			bt_device.connect.begin((obj, res) => {
				try
				{
					bt_device.connect.end(res);

					is_connected = true;

					log("Connected");

					if(cmd_char == null || res_char == null)
					{
						btmgr.characteristics.foreach(@char => {
							char_added(@char);
							return true;
						});
					}
				}
				catch(Error e)
				{
					warning(e.message);
				}
			});
		}
		catch(Error e)
		{
			warning(e.message);
		}
	}
	
	private void reconnect()
	{
		log("Reconnecting to %s [%s]".printf(bt_device.name, bt_device.address));

		new Thread<void*>("RK-G2XX-reconnect-thread", () => {
			while(true)
			{
				connect();
				Thread.usleep(5000000);
				if(is_connected) break;
			}

			return null;
		});
	}

	private void char_added(Bluez.GATTCharacteristic c)
	{
		log("Characteristic: " + c.UUID);
			
		switch(c.UUID)
		{
			case CMD_CHAR_UUID:
				cmd_char = c;
				break;
				
			case RES_CHAR_UUID:
				res_char = c;
				break;
		}
		
		init();
	}
	
	private void init()
	{
		if(cmd_char == null || res_char == null) return;
		
		log("Init");
		
		try
		{
			res_char.start_notify();
		}
		catch(Error e)
		{
			warning(e.message);
		}
		
		auth();
	}
	
	private uint8[] send_command(Command command, uint8[] args)
	{
		if(!is_connected || cmd_char == null || res_char == null) return {};

		var cmd_index = counter++;
		
		try
		{
			var bytes = command.bytes(cmd_index, args);
			log("-> %s(%u): %s".printf(command.name(), cmd_index, Converter.bin_to_hex(bytes, ' ')));
			cmd_char.write_value(bytes, _params);
			
			if(!is_connected || cmd_char == null || res_char == null) return {};

			var response = res_char.read_value(_params);
			log("<- %s(%u): %s".printf(command.name(), cmd_index, Converter.bin_to_hex(response, ' ')));
			return response;
		}
		catch(Error e)
		{
			warning(e.message);
			is_authenticated = is_connected = false;
			cmd_char = res_char = null;
			reconnect();
			return {};
		}
	}
	
	private void auth()
	{
		log("Authenticating...");
		
		while(true)
		{
			if(!is_connected) return;

			var res = send_command(Command.AUTH, AUTH_KEY);
			if(res.length < 4 || res[3] == 0)
			{
				log("Authentication failed, retrying...");
			}
			else
			{
				log("Authentication succeeded");
				is_authenticated = true;
				start_status_thread();
				break;
			}
		}
	}
	
	public override void start_boiling()
	{
		log("Starting boiling...");
		send_command(Command.START_BOILING, {});
		is_boiling = true;
	}
	
	public override void stop_boiling()
	{
		if(!is_boiling) return;
		log("Stopping boiling...");
		send_command(Command.STOP_BOILING, {});
		is_boiling = false;
	}
	
	private void start_status_thread()
	{
		if(status_thread_running) return;
		new Thread<void*>("RK-G2XX-status-thread", () => {
			while(true)
			{
				status_thread_running = true;
				var status = send_command(Command.STATUS, {});
				if(status.length < 12) break;
				temperature = status[8];
				is_boiling = status[11] != 0;
				Thread.usleep(is_boiling || temperature > 95 ? 1000000 : 10000000);
				if(!is_authenticated || !is_connected)
				{
					reconnect();
					break;
				}
			}
			
			status_thread_running = false;

			return null;
		});
	}
	
	private void log(string s)
	{
		status = s;
		debug("[RK-G2XX] " + s);
	}

	private const string UART_SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
	private const string CMD_CHAR_UUID     = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
	private const string RES_CHAR_UUID     = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
	private const string CMD_DESC_UUID     = "00002902-0000-1000-8000-00805f9b34fb";
	
	private const uint8[] COMMAND_START = { 0x55 };
	private const uint8[] COMMAND_END   = { 0xAA };
	private const uint8[] AUTH_KEY      = { 0xB5, 0x4C, 0x75, 0xB1, 0xB4, 0x0C, 0x88, 0xEF }; // maybe random
	
	private enum Command
	{
		AUTH, STATUS, START_BOILING, STOP_BOILING;
		
		public uint8 byte()
		{
			switch(this)
			{
				case Command.AUTH:          return 0xFF;
				case Command.STATUS:        return 0x06;
				case Command.START_BOILING: return 0x03;
				case Command.STOP_BOILING:  return 0x04;
			}
			return 0x00;
		}
		
		public uint8[] bytes(uint8 counter, uint8[] args)
		{
			var list = new Array<uint8>();
			list.append_vals(COMMAND_START, COMMAND_START.length);
			
			list.append_val(counter);
			var cmd = byte();
			list.append_val(cmd);
			
			list.append_vals(args, args.length);
			
			list.append_vals(COMMAND_END, COMMAND_END.length);
			return list.data;
		}
		
		public string name()
		{
			EnumClass enumc = (EnumClass) typeof(Command).class_ref();
			unowned EnumValue? eval = enumc.get_value(this);
			return_val_if_fail(eval != null, null);
			return eval.value_nick;
		}
	}
}
