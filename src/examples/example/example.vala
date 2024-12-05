/*
 * example.vala
 *
 * Copyright 2020 John Toohey
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

using Giraffe, Cairo, Gee, Gtk, Gdk, Math;

public static int main(string[] args) {
    var app = new Gtk.Application ("org.giraffe.example", GLib.ApplicationFlags.FLAGS_NONE);

    app.activate.connect (() =>
    {
        ApplicationWindow win = new ApplicationWindow (app);
        Grid grid = new Grid ();

        var abs_segments = new GLib.ListStore(typeof(NamedPieSegment));
        AbsolutePie absolute_pie = new AbsolutePie(abs_segments);
        abs_segments.append(new NamedPieSegment("Tory", 365));  // Notice that we change the list itself, not the class that's displaying it. The Pie widget listens for changes on this list and updates accordingly.
        abs_segments.append(new NamedPieSegment("Labour", 203));
        abs_segments.append(new NamedPieSegment("Scottish National Party", 48));
        abs_segments.append(new NamedPieSegment("LibDems", 11));
        abs_segments.append(new NamedPieSegment("DUP", 8));
        abs_segments.append(new NamedPieSegment("Other", 15));

        var pie_segments = new GLib.ListStore(typeof(NamedPieSegment));
        Pie pie = new Pie(pie_segments) { frame_instead_of_popover = true };
        pie_segments.append(new NamedPieSegment("Tory", 56.153846154f));
        pie_segments.append(new NamedPieSegment("Labour", 31.230769231f));
        pie_segments.append(new NamedPieSegment("Scottish National Party", 7.384615385f));
        pie_segments.append(new NamedPieSegment("Lib Dem", 1.692307692f));
        pie_segments.append(new NamedPieSegment("DUP", 1.230769231f));
        pie_segments.append(new NamedPieSegment("Other", 2.307692308f));


        BarChart barchart = new BarChart ("Boiling Points Of the Halogens", "Element", "Boiling Point (°C)");
        barchart.vexpand = true;
        barchart.hexpand = true;
        barchart.add_bar_from_information ("Flourine", -188);
        barchart.add_bar_from_information ("Chlorine", -35);
        barchart.add_bar_from_information ("Bromine", 58.8);
        barchart.add_bar_from_information ("Iodine", 184);
        barchart.add_bar_from_information ("Astatine", 337);
        barchart.unit = "°C";

        LineGraph linegraph = new LineGraph ("Happiness to Pizza eaten", "Pizza", "Happiness");
        linegraph.hexpand = true;
        linegraph.vexpand = true;
        linegraph.add_line ("System Resources");
        linegraph.add_point (0, null, 0, 0);
        linegraph.add_point (0, null, 2, 0.5);
        linegraph.add_point (0, null, 3, 2);
        linegraph.add_point (0, null, 1, 1);

        linegraph.add_line ("");

        ScatterPlot scatter_plot = new ScatterPlot ("History Grades To Geography Grades", "History", "Geography");
        scatter_plot.hexpand = true;
        scatter_plot.vexpand = true;
        for ( int i = 0; i < 100; i++ ) {
            scatter_plot.add_point ("Jane", i + (int) (20 * Random.next_double ()), i + (int) (20 * Random.next_double ()));
        }

        grid.attach (absolute_pie, 0, 0, 1, 1);
        grid.attach (pie, 0, 1, 1, 1);
        grid.attach (barchart, 1, 0, 1, 2);
        grid.attach (linegraph, 2, 0, 1, 1);
        grid.attach (scatter_plot, 2, 1, 1, 1);

        win.set_child (grid);
        win.set_child (grid);
        win.show ();
    });
    return app.run (args);
}
