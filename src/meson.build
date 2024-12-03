gnome = import('gnome')

glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')
gtk_dep = dependency('gtk4')
cairo_dep = dependency('cairo')
gee_dep = dependency('gee-0.8')

deps = [glib_dep,gobject_dep,gtk_dep,cairo_dep,gee_dep,meson.get_compiler('c').find_library('m', required: false),
]

src = ['giraffe.vala','chart.vala','pie.vala','bar.vala','line.vala','scatter.vala','graph_viewer.vala']
giraffe_lib = library('giraffe4',
					src,
					install: true,
					install_dir: [true, true, true, true],
					vala_gir: 'giraffe-4.gir',
					dependencies:deps)
giraffe_dep = declare_dependency(link_with: giraffe_lib, include_directories: include_directories('.'))

example = executable('example',
	['examples/example/example.vala', 'giraffe.vala'],
	install: false,
	dependencies: deps + giraffe_dep
)

pkg = import('pkgconfig')

pkg.generate (
	description: 'A library to display charts and graphs in Gtk 3',
	libraries: giraffe_lib,
	name: 'giraffe4',
	filebase: 'giraffe4',
	version: meson.project_version(),
	subdirs: 'giraffe4',
	requires: ['glib-2.0','gobject-2.0','gtk4','cairo','gee-0.8'],
	install_dir: join_paths(get_option('libdir'),'pkgconfig')
	)

# g_ir_compiler = find_program('g-ir-compiler')	# Create a .typelib from the .gir so that we can be used from Python.
# custom_target('giraffe4 typelib', command: [g_ir_compiler, '-l', 'libgiraffe4.so', '--output', '@OUTPUT@', '@INPUT@'],
# 			input: meson.current_build_dir() / 'giraffe-4.gir',
# 			output: 'giraffe-4.typelib',
# 			depends: giraffe_lib,
# 			install: true,
# 			install_dir: get_option('libdir') / 'girepository-1.0')
