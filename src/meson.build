glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')
gtk_dep = dependency('gtk+-3.0')
cairo_dep = dependency('cairo')
gee_dep = dependency('gee-0.8')

deps = [glib_dep,gobject_dep,gtk_dep,cairo_dep,gee_dep,meson.get_compiler('c').find_library('m', required: false),
]

src = ['giraffe.vala','chart.vala','line.vala','bar.vala','pie.vala','scatter.vala','graph_viewer.vala']
giraffe_lib = library('giraffe',
					src,
					install: true,
					install_dir: ['lib', 'include', 'share/vala/vapi'],
					dependencies:deps)
giraffe_dep = declare_dependency(link_with: giraffe_lib, include_directories: include_directories('.'))

pkg = import('pkgconfig')

pkg.generate (
	description: 'A library to display charts and graphs in Gtk 3',
	libraries: giraffe_lib,
	name: 'giraffe',
	filebase: 'giraffe',
	version: meson.project_version(),
	subdirs: 'giraffe',
	requires: ['glib-2.0','gobject-2.0','gtk+-3.0','cairo','gee-0.8'],
	install_dir: join_paths(get_option('libdir'),'pkgconfig')
	)
