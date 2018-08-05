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

unity = dependency('unity', required: false)
if unity.found()
	add_global_arguments('-D', 'WITH_UNITY_API', language: 'vala')
	deps += unity
endif

shared_sources = [
	project_config,

	icons_gresource,
	css_gresource,
	
	'utils/Utils.vala',
	'utils/Settings.vala',
	'utils/Converter.vala',

	'bluetooth/Bluez.vala',

	'devices/Devices.vala',
	'devices/abstract/BTKettle.vala',
	'devices/kettle/redmond/RK_G2XX.vala'
]

wingpanel = dependency('wingpanel-2.0', required: false)
if get_option('wingpanel_indicator') and wingpanel.found()
	shared_module(
		meson.project_name(),
		'ui/indicators/wingpanel/BoilerIndicator.vala',
		'ui/indicators/wingpanel/widgets/DisplayWidget.vala',
		shared_sources,
		dependencies: [
			dependency('glib-2.0'),
			dependency('granite'),
			dependency('gtk+-3.0'),
			wingpanel
		],
		install: true,
		install_dir : wingpanel.get_pkgconfig_variable('indicatorsdir')
	)
endif

executable(
	meson.project_name(),

	'Application.vala',
	
	'ui/windows/MainWindow.vala',
	
	'ui/views/BaseView.vala',
	
	'ui/views/connect/ConnectView.vala',
	'ui/views/connect/DeviceRow.vala',
	
	'ui/views/kettle/KettleView.vala',

	'lib/ivy/Extractor.vala',
	'lib/ivy/Frame.vala',
	'lib/ivy/Printer.vala',
	'lib/ivy/Stacktrace.vala',

	shared_sources,

	dependencies: deps,
	install: true
)
