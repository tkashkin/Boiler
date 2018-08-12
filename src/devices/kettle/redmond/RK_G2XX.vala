using GLib;

using Boiler.Bluetooth;

public class Boiler.Devices.Kettle.Redmond.RK_G2XX: Boiler.Devices.Abstract.BTKettle
{
	public const string[] DEVICES = { "RK-G200S", "RK-G210S", "RK-G211S" };
	
	private uint8[] auth_key = DEFAULT_AUTH_KEY;

	private bool is_authenticated = false;

	private bool reconnect_thread_running = false;
	private bool auth_thread_running = false;
	private bool status_thread_running = false;

	private uint8 counter = 0;
	
	private HashTable<string, Variant> _params = new HashTable<string, Variant>(str_hash, null);
	
	private Bluez.GATTCharacteristic? cmd_char;
	private Bluez.GATTCharacteristic? res_char;
	
	private SourceFunc connect_callback;

	public RK_G2XX(Bluez.Device device, Bluez.Manager btmgr)
	{
		Object(bt_device: device, btmgr: btmgr);
		
		name = bt_device.name;
		description = bt_device.address;
		pairing_info = _("Your PC is not paired to the kettle.\nHold kettle power button for 5 seconds");

		var key = Boiler.Settings.Dev.Redmond.RK_G2XX.get_instance().auth_key;

		if(key != "")
		{
			if(!Converter.hex_to_bin(key, out auth_key, ' '))
			{
				auth_key = DEFAULT_AUTH_KEY;
			}
		}
	}

	public override async void connect_async()
	{
		connect_callback = connect_async.callback;
		
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
						btmgr.characteristic_added.connect(char_added);
					}
				}
				catch(Error e)
				{
					warning(e.message);
					reconnect();
				}
			});
		}
		catch(Error e)
		{
			warning(e.message);
		}

		yield;
	}
	
	private void reconnect()
	{
		log("Reconnecting to %s [%s]".printf(bt_device.name, bt_device.address));

		if(reconnect_thread_running) return;
		new Thread<void*>("RK-G2XX-reconnect-thread", () => {
			while(true)
			{
				reconnect_thread_running = true;
				connect_async.begin();
				Thread.usleep(5000000);
				if(is_connected) break;
			}

			reconnect_thread_running = false;

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
		
		if(connect_callback != null) Idle.add(connect_callback);

		auth();
	}
	
	private uint8[] send_command(Command command, uint8[] args)
	{
		if(!is_connected || cmd_char == null || res_char == null) return {};

		lock(counter)
		{
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
	}
	
	private void auth()
	{
		log("Authenticating...");
		
		if(auth_thread_running) return;
		new Thread<void*>("RK-G2XX-auth-thread", () => {
			var tries = 0;
			while(true)
			{
				auth_thread_running = true;
				if(!is_connected) break;

				var res = send_command(Command.AUTH, auth_key);
				if(res.length < 4 || res[3] == 0)
				{
					log("Authentication failed, retrying...");
					tries++;
					if(tries > 5) is_paired = false;
					Thread.usleep(1000000);
				}
				else
				{
					log("Authentication succeeded");
					is_authenticated = true;
					is_paired = true;
					description = @"$(bt_device.address) (fw $(get_fw_version()))";
					start_status_thread();
					break;
				}
			}

			auth_thread_running = false;

			return null;
		});
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
	private string get_fw_version()
	{
		log("Getting firmware version...");
		var res = send_command(Command.FW_VERSION, {});
		return @"$(res[3]).$(res[4])";
	}

	private void start_status_thread()
	{
		if(status_thread_running) return;
		new Thread<void*>("RK-G2XX-status-thread", () => {
			while(true)
			{
				status_thread_running = true;
				var status = send_command(Command.STATUS, {});
				is_ready = status.length == 20;
				if(is_ready)
				{
					temperature = status[8];
					is_boiling = status[11] != 0;
					Thread.usleep(is_boiling || temperature > 95 ? 1000000 : 10000000);
				}
				if(!is_ready || !is_authenticated || !is_connected)
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
	
	private const uint8[] COMMAND_START    = { 0x55 };
	private const uint8[] COMMAND_END      = { 0xAA };
	private const uint8[] DEFAULT_AUTH_KEY = { 0xB5, 0x4C, 0x75, 0xB1, 0xB4, 0x0C, 0x88, 0xEF };
	
	public static uint8[] generate_auth_key()
	{
		return Boiler.Utils.random_bytes(8, { COMMAND_START[0], COMMAND_END[0] });
	}

	private enum Command
	{
		AUTH, STATUS, START_BOILING, STOP_BOILING, FW_VERSION;
		
		public uint8 byte()
		{
			switch(this)
			{
				case Command.AUTH:          return 0xFF;
				case Command.STATUS:        return 0x06;
				case Command.START_BOILING: return 0x03;
				case Command.STOP_BOILING:  return 0x04;
				case Command.FW_VERSION:    return 0x01;
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
