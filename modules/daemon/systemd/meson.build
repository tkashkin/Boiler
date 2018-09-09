systemd_user_services_dir = systemd.get_pkgconfig_variable('systemduserunitdir')

systemd_config = configuration_data()
systemd_config.set('DAEMON_BINARY', join_paths(get_option('prefix'), get_option('bindir'), meson.project_name() + '.daemon'))

configure_file(
	input : meson.project_name() + '.daemon.service.in',
	output : meson.project_name() + '.daemon.service',
	configuration : systemd_config,
	install_dir : systemd_user_services_dir
)
