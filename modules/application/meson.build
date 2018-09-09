subdir('data')

app_deps = [
	dependency('gdk-3.0')
]

app_args = []

gtk3_22_29 = dependency('gtk+-3.0', version: '>=3.22.29', required: false)
if gtk3_22_29.found()
	app_args += ['-D', 'GTK_3_22', '-D', 'GTK_3_22_29']
	app_deps += gtk3_22_29
else
	gtk3_22 = dependency('gtk+-3.0', version: '>=3.22', required: false)
	if gtk3_22.found()
		app_args += ['-D', 'GTK_3_22']
		app_deps += gtk3_22_29
	else
		app_deps += dependency('gtk+-3.0')
	endif
endif

unity = dependency('unity', required: false)
if unity.found()
	app_args += ['-D', 'WITH_UNITY_API']
	app_deps += unity
endif

executable(meson.project_name(),
	[
		'Application.vala',

		'DBusClient.vala',

		'ui/windows/MainWindow.vala',

		'ui/views/BaseView.vala',

		'ui/views/connect/ConnectView.vala',
		'ui/views/connect/KettleRow.vala',

		'ui/views/kettle/KettleView.vala'
	],

	icons_gresource,
	css_gresource,

	dependencies: [
		libboiler_deps,
		app_deps
	],
	link_with: libboiler,
	include_directories: libboiler_include,
	install: true,
	vala_args: app_args
)
