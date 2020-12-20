## Giraffe
Giraffe is a simple graphing libary written in Gtk+ 3 and vala to be helpful. 

The dependencies for this libary are:
	
	valac 		(or vala depending on your distro)
	gtk3
	meson
	valadoc 	(for documentation not mandatory)
On Debian derivatives you will also need:
	
	libgtk-3-dev

To get this libary and install it to your system use:

	git clone https://gitlab.com/john_t/giraffe.git
	cd giraffe
	mkdir build
	cd build
	meson .. --prefix=/usr
	ninja
	ninja install


Documentation (which at the momement is only in Vala) can be generated with:
    
    ninja doc
And accessed in doc/index.html. Note doc cannot be installed - system wide. It is also only half finished.

An example project can be generated with:
    
    cd src/examples/example
    mkdir build
    cd build
    meson ..
    ninja
Run with ./example
