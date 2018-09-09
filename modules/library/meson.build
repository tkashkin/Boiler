plugdir = get_option('prefix') + '/' + get_option('libdir') + '/' + meson.project_name()

conf_data = configuration_data()
conf_data.set_quoted('PROJECT_NAME', meson.project_name())
conf_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf_data.set_quoted('GETTEXT_DIR', get_option('prefix') + '/' + get_option('localedir'))
conf_data.set_quoted('VERSION', meson.project_version())
conf_data.set_quoted('PREFIX', get_option('prefix'))
conf_data.set_quoted('DATADIR', get_option('prefix') + '/' + get_option('datadir'))
conf_data.set_quoted('PLUGDIR', plugdir)
libboiler_config = configure_file(
	input: 'Config.vala.in',
	output: 'Config.vala',
	configuration: conf_data
)

libboiler_deps = [
	dependency('granite'),
	dependency('glib-2.0'),
	dependency('gmodule-2.0'),
	dependency('gee-0.8'),
	meson.get_compiler('vala').find_library('posix'),
	meson.get_compiler('vala').find_library('linux')
]

libboiler_include = include_directories('.')
libboiler_interface = 'PluginInterfaces.vala'

libboiler = shared_library('boiler',
	[
		libboiler_config,
		
		libboiler_interface,

		'Library.vala',

		'PluginLoader.vala',

		'bluetooth/Bluez.vala',

		'devices/Devices.vala',
		'devices/abstract/BTKettle.vala',

		'utils/Utils.vala',
		'utils/Converter.vala',
		'utils/Settings.vala'
	],

	dependencies: libboiler_deps,
	install: true
)
