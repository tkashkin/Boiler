project('com.github.tkashkin.boiler', 'vala', 'c', version: '0.1.1')

i18n = import('i18n')
gnome = import('gnome')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language: 'c')

if get_option('flatpak')
	add_global_arguments('-D', 'FLATPAK', language: 'vala')
elif get_option('snap')
	add_global_arguments('-D', 'SNAP', language: 'vala')
endif

subdir('data')
subdir('src')
subdir('po')

meson.add_install_script('meson/post_install.py')
