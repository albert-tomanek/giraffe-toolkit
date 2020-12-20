/*
 * example.vala
 * 
 * Copyright 2020 John Toohey <johnhustontoohey@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 * 
 * 
 */

// Hello this is just a learning file, using results from the 2019 general elections 

using Giraffe, Gtk;
public static int main(string[] args)
	{
	Gtk.init(ref args);
	Window win = new Window();
	win.destroy.connect(Gtk.main_quit);
	Grid grid = new Grid();
	
	AbsolutePie absolute_pie = new AbsolutePie();
	absolute_pie.add_segment("Tory",365);
	absolute_pie.add_segment("Labour",203);
	absolute_pie.add_segment("Scottish National Party",48);
	absolute_pie.add_segment("LibDems",11);
	absolute_pie.add_segment("DUP",8);
	absolute_pie.add_segment("Other",15);
	
	
	Pie pie = new Pie (); 
	pie.add_segment("Tory",56.153846154f);
	pie.add_segment("Labour",31.230769231f);
	pie.add_segment("Scottish National Party",7.384615385f);
	pie.add_segment("Lib Dem",1.692307692f);
	pie.add_segment("DUP",1.230769231f);
	pie.add_segment("Other",2.307692308f);
	
	
	BarChart barchart = new BarChart("Boiling Points Of the Halogens", "Element", "Boiling Point (°C)");
	barchart.expand=true;
	barchart.add_bar_from_information("Flourine",-188);
	barchart.add_bar_from_information("Chlorine",-35);
	barchart.add_bar_from_information("Bromine",58.8);
	barchart.add_bar_from_information("Iodine",184);
	barchart.add_bar_from_information("Astatine",337);
	barchart.unit="°C";
	
	Gdk.RGBA colour = Gdk.RGBA();
	colour.red=255;
	colour.blue=0;
	colour.green=0;
	colour.alpha=255;
	
	grid.attach(absolute_pie,0,0,1,1);
	grid.attach(pie,0,1,1,1);
	grid.attach(barchart,1,0,1,2);
	
	win.add(grid);
	win.show_all();
	win.border_width=10;
	Gtk.main();
	return 0;
	}
