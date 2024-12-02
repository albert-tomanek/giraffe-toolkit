project('giraffe','c','vala')

subdir('src')

if get_option('build-docs')
	valadoc = find_program('valadoc',required:false)
	docsrc = ['src/giraffe.vala','src/chart.vala','src/line.vala','src/bar.vala','src/pie.vala','src/scatter.vala','src/graph_viewer.vala',]

	doc = custom_target('documentation',
		output: 'doc',
		input : docsrc,
		command: [valadoc,
		'-o @OUTPUT@',
		'--force',
		'--package-version=0.1',
		'--verbose',
		'--pkg=cairo',
		'--pkg=gee-0.8',
		'--pkg=gtk4',
		'-b docsrc',
		src]
	)
endif