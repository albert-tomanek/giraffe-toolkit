# Giraffe

Note this branch is for GTK4. See the GTK3 branch for the previous version.
Giraffe is a simple graphing libary written in Gtk4 and vala to be helpful. 

## Dependencies

The dependencies for this libary are:

```
valac       (or vala depending on your distro)
gtk4
meson
valadoc     (for documentation not mandatory)
```

On Debian derivatives you will also need:

```
libgtk-4-dev (I think)
```

## Install

To get this libary and install it to your system use:

```git clone https://gitlab.com/john_t/giraffe.git
cd giraffe
mkdir build
cd build
meson .. --prefix=/usr
ninja
ninja install
```

## Documentation

Documentation (which at the momement is only in Vala) can be generated with:

```
ninja doc
```

And accessed in doc/index.html. Note doc cannot be installed - system wide. It is also only half finished.

## Example

An example project can be generated with:

```
cd src/examples/example
mkdir build
cd build
meson ..
ninja
```

Run with ./example

To include with your program (using pkg-config or --pkg for vala) use the package `giraffe4`
