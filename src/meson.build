conf_data = configuration_data()
conf_data.set_quoted('PROJECT_NAME', meson.project_name())
conf_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf_data.set_quoted('GETTEXT_DIR', get_option('prefix') + '/' + get_option('localedir'))
conf_data.set_quoted('VERSION', meson.project_version())
conf_data.set_quoted('PREFIX', get_option('prefix'))
conf_data.set_quoted('DATADIR', get_option('prefix') + '/' + get_option('datadir'))
project_config = configure_file(
	input: 'ProjectConfig.vala.in',
	output: 'ProjectConfig.vala',
	configuration: conf_data
)

deps = [
	dependency('granite'),
	dependency('gdk-3.0'),
	dependency('glib-2.0'),
	dependency('gee-0.8'),
	meson.get_compiler('vala').find_library('posix'),
	meson.get_compiler('vala').find_library('linux')
]

gtk322 = dependency('gtk+-3.0', version: '>=3.22', required: false)
if gtk322.found()
	add_global_arguments('-D', 'GTK_3_22', language: 'vala')
	deps += gtk322
else
	deps += dependency('gtk+-3.0')
endif

if get_option('use_ivy')
	add_global_arguments('-g', '-X', '-rdynamic', '-D', 'USE_IVY', language: 'vala')
endif

executable(
	meson.project_name(),
	project_config,
	
	'app.vala',
	
	'ui/windows/MainWindow.vala',
	
	'ui/views/BaseView.vala',
	
	'ui/views/connect/ConnectView.vala',
	'ui/views/connect/DeviceRow.vala',
	
	'utils/Settings.vala',
	'utils/Converter.vala',
	
	'bluetooth/Bluez.vala',
	
	'devices/Devices.vala',
	'devices/abstract/BTKettle.vala',
	'devices/kettle/redmond/RK_G2XX.vala',

	'lib/ivy/Extractor.vala',
	'lib/ivy/Frame.vala',
	'lib/ivy/Printer.vala',
	'lib/ivy/Stacktrace.vala',

	icons_gresource,
	css_gresource,

	dependencies: deps,
	install: true
)
