subdir('data')

shared_library('rk_g2xx',
	[
		'Plugin.vala',
		'Device.vala',
		'Settings.vala'
	],

	rk_g2xx_icons,

	dependencies: [
		libboiler_deps
	],
	link_with: libboiler,
	include_directories: libboiler_include,
	install: true,
	install_dir: plugdir + '/devices/kettle/redmond',
	name_prefix: ''
)
