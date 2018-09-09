project('com.github.tkashkin.boiler', 'vala', 'c', version: '0.2.0')

i18n = import('i18n')
gnome = import('gnome')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language: 'c')

if get_option('flatpak')
	add_global_arguments('-D', 'FLATPAK', language: 'vala')
elif get_option('snap')
	add_global_arguments('-D', 'SNAP', language: 'vala')
endif

subdir('modules/library')

if get_option('with_app')
	subdir('modules/application')
endif

if get_option('with_daemon')
	subdir('modules/daemon')
endif

if get_option('with_plugins')
	subdir('modules/plugins')
endif

subdir('po')

meson.add_install_script('meson/post_install.py')
