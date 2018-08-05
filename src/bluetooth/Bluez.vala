using GLib;

// DBus interfaces from https://github.com/elementary/switchboard-plug-bluetooth
namespace Boiler.Bluetooth.Bluez
{
	[DBus(name="org.bluez.Adapter1")]
	public interface Adapter: Object
	{
		public abstract void remove_device(ObjectPath device) throws Error;
		public abstract void set_discovery_filter(HashTable<string, Variant> properties) throws Error;
		public abstract async void start_discovery() throws Error;
		public abstract async void stop_discovery() throws Error;

		public abstract string[] UUIDs { owned get; }
		public abstract bool discoverable { get; set; }
		public abstract bool discovering { get; }
		public abstract bool pairable { get; set; }
		public abstract bool powered { get; set; }
		public abstract string address { owned get; }
		public abstract string alias { owned get; set; }
		public abstract string modalias { owned get; }
		public abstract string name { owned get; }
		public abstract uint @class { get; }
		public abstract uint discoverable_timeout { get; }
		public abstract uint pairable_timeout { get; }
	}
	
	[DBus(name="org.bluez.Device1")]
	public interface Device: Object
	{
		public abstract void cancel_pairing() throws Error;
		public abstract async void connect() throws Error;
		public abstract void connect_profile(string UUID) throws Error;
		public abstract async void disconnect() throws Error;
		public abstract void disconnect_profile(string UUID) throws Error;
		public abstract async void pair() throws Error;

		public abstract string[] UUIDs { owned get; }
		public abstract bool blocked { owned get; set; }
		public abstract bool connected { owned get; }
		public abstract bool legacy_pairing { owned get; }
		public abstract bool paired { owned get; }
		public abstract bool trusted { owned get; set; }
		public abstract int16 RSSI { owned get; }
		public abstract ObjectPath adapter { owned get; }
		public abstract string address { owned get; }
		public abstract string alias { owned get; set; }
		public abstract string icon { owned get; }
		public abstract string modalias { owned get; }
		public abstract string name { owned get; }
		public abstract uint16 appearance { owned get; }
		public abstract uint32 @class { owned get; }
	}
	
	[DBus(name="org.bluez.GattService1")]
	public interface GATTService: Object
	{
		public abstract ObjectPath[] includes { owned get; }
		public abstract bool primary { owned get; }
		public abstract ObjectPath device { owned get; }
		public abstract string UUID { owned get; }
	}
	
	[DBus(name="org.bluez.GattCharacteristic1")]
	public interface GATTCharacteristic: Object
	{
		public abstract uint8[] read_value(HashTable<string, Variant> options) throws Error;
		public abstract void write_value(uint8[] value, HashTable<string, Variant> options) throws Error;
		public abstract void start_notify() throws Error;
		public abstract void stop_notify() throws Error;
		
		public abstract uint8[] value { owned get; }
		public abstract string[] flags { owned get; }
		public abstract bool notify_acquired { owned get; }
		public abstract bool notifying { owned get; }
		public abstract bool write_acquired { owned get; }
		public abstract ObjectPath service { owned get; }
		public abstract string UUID { owned get; }
	}
	
	[DBus(name="org.bluez.GattDescriptor1")]
	public interface GATTDescriptor: Object
	{
		public abstract uint8[] read_value(HashTable<string, Variant> options) throws Error;
		public abstract void write_value(uint8[] value, HashTable<string, Variant> options) throws Error;
		
		public abstract uint8[] value { owned get; }
		public abstract ObjectPath characteristic { owned get; }
		public abstract string UUID { owned get; }
	}
	
	[DBus(name="org.freedesktop.DBus.ObjectManager")]
	public interface DBusInterface: Object
	{
		public signal void interfaces_added(ObjectPath object_path, HashTable<string, HashTable<string, Variant>> param);
		public signal void interfaces_removed(ObjectPath object_path, string[] string_array);
		public abstract HashTable<ObjectPath, HashTable<string, HashTable<string, Variant>>> get_managed_objects() throws Error;
	}

	public class Manager: Object
	{
		public signal void state_changed(bool enabled, bool connected);
		public signal void adapter_added(Adapter adapter);
		public signal void adapter_removed(Adapter adapter);
		public signal void device_added(Device device);
		public signal void device_removed(Device device);
		
		public signal void service_added(GATTService svc);
		public signal void service_removed(GATTService svc);
		public signal void characteristic_added(GATTCharacteristic @char);
		public signal void characteristic_removed(GATTCharacteristic @char);
		public signal void descriptor_added(GATTDescriptor desc);
		public signal void descriptor_removed(GATTDescriptor desc);

		public bool discoverable { get; set; default = false; }
		public bool has_object { get; private set; default = false; }
		public bool retrieve_finished { get; private set; default = false; }

		private bool is_discovering = false;

		private DBusInterface object_interface;
		private Gee.HashMap<string, Adapter> _adapters;
		private Gee.HashMap<string, Device> _devices;
		
		private Gee.HashMap<string, GATTService> _services;
		private Gee.HashMap<string, GATTCharacteristic> _characteristics;
		private Gee.HashMap<string, GATTDescriptor> _descriptors;
		
		public static Manager instance;

		construct
		{
			instance = this;
			
			_adapters = new Gee.HashMap<string, Adapter>(null, null);
			_devices = new Gee.HashMap<string, Device>(null, null);
			
			_services = new Gee.HashMap<string, GATTService>(null, null);
			_characteristics = new Gee.HashMap<string, GATTCharacteristic>(null, null);
			_descriptors = new Gee.HashMap<string, GATTDescriptor>(null, null);

			Bus.get_proxy.begin<DBusInterface>(BusType.SYSTEM, "org.bluez", "/", DBusProxyFlags.NONE, null, (obj, res) => {
				try
				{
					object_interface = Bus.get_proxy.end(res);
					object_interface.get_managed_objects().foreach(add_path);
					object_interface.interfaces_added.connect(add_path);
					object_interface.interfaces_removed.connect(remove_path);
				}
				catch(Error e)
				{
					warning(e.message);
				}
				retrieve_finished = true;
			});

			notify["discoverable"].connect(() => {
				lock(_adapters)
				{
					foreach(var adapter in _adapters.values)
					{
						adapter.discoverable = discoverable;
					}
				}
			});
		}

		[CCode(instance_pos=-1)]
		private void add_path(ObjectPath path, HashTable<string, HashTable<string, Variant>> param)
		{
			debug("DBus path `%s` added", path);
			if("org.bluez.Adapter1" in param)
			{
				try
				{
					Adapter adapter = Bus.get_proxy_sync(BusType.SYSTEM, "org.bluez", path, DBusProxyFlags.GET_INVALIDATED_PROPERTIES);
					lock(_adapters)
					{
						_adapters.set(path, adapter);
					}
					has_object = true;

					adapter_added(adapter);

					(adapter as DBusProxy).g_properties_changed.connect((changed, invalid) => {
						var powered = changed.lookup_value("Powered", GLib.VariantType.BOOLEAN);
						if(powered != null)
						{
							check_global_state();
						}

						var discovering = changed.lookup_value("Discovering", GLib.VariantType.BOOLEAN);
						if(discovering != null)
						{
							check_discovering();
						}

						var adapter_discoverable = changed.lookup_value("Discoverable", GLib.VariantType.BOOLEAN);
						if(adapter_discoverable != null)
						{
							check_discoverable();
						}
					});
				}
				catch(Error e)
				{
					debug("Connecting to bluetooth adapter failed: %s", e.message);
				}
			}
			else if("org.bluez.Device1" in param)
			{
				try
				{
					Device device = Bus.get_proxy_sync(BusType.SYSTEM, "org.bluez", path, DBusProxyFlags.GET_INVALIDATED_PROPERTIES);
					lock(_devices)
					{
						_devices.set(path, device);
					}

					device_added(device);

					(device as DBusProxy).g_properties_changed.connect((changed, invalid) => {
						var connected = changed.lookup_value("Connected", GLib.VariantType.BOOLEAN);
						if(connected != null)
						{
							check_global_state();
						}
					});
				}
				catch(Error e)
				{
					debug("Connecting to bluetooth device failed: %s", e.message);
				}
			}
			else if("org.bluez.GattService1" in param)
			{
				try
				{
					GATTService svc = Bus.get_proxy_sync(BusType.SYSTEM, "org.bluez", path, DBusProxyFlags.GET_INVALIDATED_PROPERTIES);
					lock(_services)
					{
						_services.set(path, svc);
					}
					service_added(svc);
				}
				catch(Error e)
				{
					debug("Connecting to GATT service failed: %s", e.message);
				}
			}
			else if("org.bluez.GattCharacteristic1" in param)
			{
				try
				{
					GATTCharacteristic c = Bus.get_proxy_sync(BusType.SYSTEM, "org.bluez", path, DBusProxyFlags.GET_INVALIDATED_PROPERTIES);
					lock(_characteristics)
					{
						_characteristics.set(path, c);
					}
					characteristic_added(c);
				}
				catch(Error e)
				{
					debug("Connecting to GATT characteristic failed: %s", e.message);
				}
			}
			else if("org.bluez.GattDescriptor1" in param)
			{
				try
				{
					GATTDescriptor desc = Bus.get_proxy_sync(BusType.SYSTEM, "org.bluez", path, DBusProxyFlags.GET_INVALIDATED_PROPERTIES);
					lock(_descriptors)
					{
						_descriptors.set(path, desc);
					}
					descriptor_added(desc);
				}
				catch(Error e)
				{
					debug("Connecting to GATT descriptor failed: %s", e.message);
				}
			}
		}

		public void check_discovering()
		{
			foreach(var adapter in _adapters.values)
			{
				if(adapter.discovering != is_discovering)
				{
					if(is_discovering)
					{
						adapter.start_discovery.begin();
					}
					else
					{
						adapter.stop_discovery.begin();
					}
				}
			}
		}

		public void check_discoverable()
		{
			foreach(var adapter in _adapters.values)
			{
				if(adapter.discoverable != discoverable)
				{
					adapter.discoverable = discoverable;
				}
			}
		}

		[CCode(instance_pos=-1)]
		public void remove_path(ObjectPath path)
		{
			debug("DBus path `%s` removed", path);
			lock(_adapters)
			{
				var adapter = _adapters.get(path);
				if(adapter != null)
				{
					_adapters.unset(path);
					has_object = !adapters.is_empty;
					adapter_removed(adapter);
					return;
				}
			}
			lock(_devices)
			{
				var device = _devices.get(path);
				if(device != null)
				{
					_devices.unset(path);
					device_removed(device);
				}
			}
			lock(_services)
			{
				var svc = _services.get(path);
				if(svc != null)
				{
					_services.unset(path);
					service_removed(svc);
				}
			}
			lock(_characteristics)
			{
				var @char = _characteristics.get(path);
				if(@char != null)
				{
					_characteristics.unset(path);
					characteristic_removed(@char);
				}
			}
			lock(_descriptors)
			{
				var desc = _descriptors.get(path);
				if(desc != null)
				{
					_descriptors.unset(path);
					descriptor_removed(desc);
				}
			}
		}

		public Gee.Collection<Adapter> adapters
		{
			owned get
			{
				lock(_adapters)
				{
					return _adapters.values;
				}
			}
		}

		public Gee.Collection<Device> devices
		{
			owned get
			{
				lock(_devices)
				{
					return _devices.values;
				}
			}
		}
		
		public Gee.Collection<GATTService> services
		{
			owned get
			{
				lock(_services)
				{
					return _services.values;
				}
			}
		}
		
		public Gee.Collection<GATTCharacteristic> characteristics
		{
			owned get
			{
				lock(_characteristics)
				{
					return _characteristics.values;
				}
			}
		}
		
		public Gee.Collection<GATTDescriptor> descriptors
		{
			owned get
			{
				lock(_descriptors)
				{
					return _descriptors.values;
				}
			}
		}

		public Adapter? get_adapter(string path)
		{
			lock(_adapters)
			{
				return _adapters.get(path);
			}
		}

		private void check_global_state()
		{
			state_changed(is_powered, is_connected);
		}

		public async void start_discovery()
		{
			lock(_adapters)
			{
				is_discovering = true;
				foreach(var adapter in _adapters.values)
				{
					try
					{
						yield adapter.start_discovery();
					}
					catch(Error e)
					{
						warning(e.message);
					}
				}
			}
		}

		public async void stop_discovery()
		{
			lock(_adapters)
			{
				is_discovering = false;
				foreach(var adapter in _adapters.values)
				{
					try
					{
						yield adapter.stop_discovery();
					}
					catch(Error e)
					{
						warning(e.message);
					}
				}
			}
		}
		
		public bool is_connected
		{
			get
			{
				lock(_devices)
				{
					foreach(var device in _devices.values)
					{
						if(device.connected)
						{
							return true;
						}
					}
				}
				return false;
			}
		}
		
		public bool is_powered
		{
			get
			{
				lock(_adapters)
				{
					foreach(var adapter in _adapters.values)
					{
						if(adapter.powered)
						{
							return true;
						}
					}
				}
				return false;
			}
			set
			{
				lock(_devices)
				{
					foreach(var device in _devices.values)
					{
						if(device.connected)
						{
							try
							{
								device.disconnect.begin();
							}
							catch (Error e)
							{
								warning(e.message);
							}
						}
					}
				}

				lock(_adapters)
				{
					foreach(var adapter in _adapters.values)
					{
						adapter.powered = value;
					}
				}
			}
		}
	}
}
