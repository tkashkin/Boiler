using GLib;

using Boiler.Bluetooth;

public class Boiler.Devices.Kettle.Redmond.RK_G2XX: Boiler.Devices.Abstract.BTKettle
{
	public const string[] DEVICES = { "RK-G200S" };	
	
	private bool authenticated = false;
	private uint8 counter = 0;
	
	private HashTable<string, Variant> _params = new HashTable<string, Variant>(str_hash, null);
	
	private Bluez.GATTCharacteristic? cmd_char;
	private Bluez.GATTCharacteristic? res_char;
	
	public RK_G2XX(Bluez.Device device, Bluez.Manager btmgr)
	{
		Object(bt_device: device, btmgr: btmgr);
		
		debug("[RK-G2XX] %s: %s", device.name, device.address);
		
		device.connect.begin((obj, res) => {
			device.connect.end(res);
			
			debug("[RK-G2XX] Connected");
		
			btmgr.characteristics.foreach(@char => {
				char_added(@char);
				return true;
			});
		});
	}
	
	private void char_added(Bluez.GATTCharacteristic c)
	{
		debug("[RK-G2XX] Characteristic: %s", c.UUID);
			
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
		
		debug("[RK-G2XX] Init");
		
		res_char.start_notify();
		
		auth();
	}
	
	private uint8[] send_command(Command command, uint8[] args)
	{
		var cmd_index = counter++;
		
		try
		{
			var bytes = command.bytes(cmd_index, args);
			debug("[RK-G2XX] -> %s(%u): %s", command.name(), cmd_index, Converter.bin_to_hex(bytes, ' '));
			cmd_char.write_value(bytes, _params);
			
			var response = res_char.read_value(_params);
			debug("[RK-G2XX] <- %s(%u): %s", command.name(), cmd_index, Converter.bin_to_hex(response, ' '));
			return response;
		}
		catch(Error e)
		{
			authenticated = true;
			return {};
		}
	}
	
	private void auth()
	{
		debug("[RK-G2XX] Authenticating...");
		
		while(true)
		{
			var res = send_command(Command.AUTH, AUTH_KEY);
			if(res.length < 4 || res[3] == 0)
			{
				warning("[RK-G2XX] Authentication failed, retrying...");
			}
			else
			{
				debug("[RK-G2XX] Authentication succeeded");
				authenticated = true;
				start_status_thread();
				break;
			}
		}
	}
	
	public override void start_boiling()
	{
		debug("[RK-G2XX] Starting boiling...");
		send_command(Command.START_BOILING, {});
		is_boiling = true;
	}
	
	public override void stop_boiling()
	{
		if(!is_boiling) return;
		debug("[RK-G2XX] Stopping boiling...");
		send_command(Command.STOP_BOILING, {});
		is_boiling = false;
	}
	
	private void start_status_thread()
	{
		new Thread<void*>("RK-G2XX-status-thread", () => {		
			while(true)
			{
				var status = send_command(Command.STATUS, {});
				if(status.length < 12) break;
				temperature = status[8];
				is_boiling = status[11] != 0;
				Thread.usleep(1000000);
			}
			
			return null;
		});
	}
	
	private const string UART_SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
	private const string CMD_CHAR_UUID	 = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
	private const string RES_CHAR_UUID	 = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
	private const string CMD_DESC_UUID	 = "00002902-0000-1000-8000-00805f9b34fb";
	
	private const uint8[] COMMAND_START = { 0x55 };
	private const uint8[] COMMAND_END   = { 0xAA };
	private const uint8[] AUTH_KEY	  = { 0xB5, 0x4C, 0x75, 0xB1, 0xB4, 0x0C, 0x88, 0xEF }; // maybe random
	
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
