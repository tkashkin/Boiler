daemon_deps = []
daemon_args = []

executable(meson.project_name() + '.daemon',
	[
		'Daemon.vala',

		'DBusServer.vala',
		'DBusData.vala'
	],

	dependencies: [
		libboiler_deps,
		daemon_deps
	],
	link_with: libboiler,
	include_directories: libboiler_include,
	install: true,
	vala_args: daemon_args
)

if get_option('daemon_systemd_service')
	systemd = dependency('systemd', required: false)
	if systemd.found()
		subdir('systemd')
	else
		warning('Systemd integration was enabled, but systemd is not available')
	endif
endif
