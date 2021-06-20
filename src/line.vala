/* line.vala
 *
 * Copyright 2020 John Toohey
 *
 * This file is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 3 of the
 * License, or (at your option) any later version.
 *
 * This file is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: LGPL-3.0-or-later
 */

using Gtk, Cairo, Gee, Gdk, Math;
namespace Giraffe {
    /**
     * A class for storing a list of line points.
     */
    public struct Line {
        public ArrayList<GraphPoint ? > points;
        public string ? title;
        public RGBA color;
    }
    /**
     * A widget for displaying lines graph without the axis.
     */
    public class LineViewer : GraphViewer {
        /**
         * A list of lines.
         */
        public ArrayList<Line ? > lines;

        /**
         * Signal for modifying the popover
         */
        public signal void popover_setter(GraphPoint point, Line line, Label title, Label name, Label val);

        construct
        {
            lines = new ArrayList<Line ? >();
            hexpand = true;
            vexpand = true;
            gen ();
            set_draw_func (draw);
        }
        protected void draw(DrawingArea da, Context cr, int width, int height) {
            generate_max_mins ();
            foreach ( Line line in lines ) {
                if ( line.points.size >= 1 ) {
                    cr.set_source_rgb (line.color.red,
                                       line.color.blue,
                                       line.color.green
                                       );
                    cr.set_line_width (10.0);
                    cr.set_line_join (Cairo.LineJoin.ROUND);
                    cr.move_to (map_range (line.points[0].x, min_val_x, max_val_x, 0, width), map_range_flip (line.points[0].y, min_val, max_val, 0, height));
                    foreach ( GraphPoint point in line.points ) {
                        cr.line_to (map_range (point.x, min_val_x, max_val_x, 0, width),
                                    map_range_flip (point.y, min_val, max_val, 0, height));
                    }
                    cr.stroke ();
                }
            }
        }

        public override void generate_max_mins() {
            min_val_x = double.INFINITY;
            max_val_x = -double.INFINITY;
            min_val = double.INFINITY;
            max_val = -double.INFINITY;
            foreach ( Line line in lines ) {
                foreach ( GraphPoint point in line.points ) {
                    min_val_x = double.min (point.x, min_val_x);
                    min_val = double.min (point.y, min_val);
                    max_val_x = double.max (point.x, max_val_x);
                    max_val = double.max (point.y, max_val);
                }
            }
            if ( override_min_val != null ) min_val = override_min_val;
            if ( override_min_val_x != null ) min_val_x = override_min_val_x;
            if ( override_max_val != null ) max_val = override_max_val;
            if ( override_max_val_x != null ) max_val_x = override_max_val_x;
        }

        protected override void motion(double x, double y) {
            double width = get_allocated_width ();
            double height = get_allocated_height ();
            generate_max_mins ();
            bool popup = false;
            if ( use_popover ) {
                foreach ( Line line in lines ) {
                    foreach ( GraphPoint point in line.points ) {
                        double lx = map_range (point.x, min_val_x, max_val_x, 0, width);
                        double ly = map_range_flip (point.y, min_val, max_val, 0, height);
                        double distance = pow ((pow (x - lx, 2) + pow (y - ly, 2)), 0.5); // Gets the distance away from the center of the pie
                        if ( fabs (distance) < 32 && y > point.y ) {
                            popover_setter (point, line, popover_title, popover_name, popover_value_label);
                            Gdk.Rectangle rect = Gdk.Rectangle ();
                            rect.x = (int) lx;
                            rect.y = (int) ly;
                            rect.width = 1;
                            rect.height = 1;
                            popover.pointing_to = rect;
                            popup = true;
                            break;
                        }
                    }
                }
            }

            if ( popup ) popover.popup ();
            else popover.popdown ();
        }

        /**
         * The default way of setting popover values, good for some cases
         */
        public virtual void update_popover(GraphPoint point, Line line, Label title, Label name, Label val) {
            if ( line.title != null ) {
                title.show ();
                title.set_markup ("<b>%s</b>".printf (line.title));
            } else title.hide ();
            if ( point.name != null ) {
                name.show ();
                name.set_markup ("<b>%s</b>".printf (point.name));
            } else name.hide ();
            val.label = "%s\n%s".printf (nice_double (point.x), nice_double (point.y));
        }

    }
    /**
     * A widget for displaying line graphs. They can have multiple line groups (each of a different colour.)
     */
    public class LineGraph : Chart {
        public LineViewer line_viewer;

        protected Label min_label_x;
        protected Label max_label_x;

        /**
         * The unit on the Y axis
         */
        public string unit_y { get; set; }
        /**
         * The unit on the X axis
         */
        public string unit_x { get; set; }

        public LineGraph (string title, string x_axis_title, string y_axis_title) {
            base (title, x_axis_title, y_axis_title);
        }

        construct
        {
            line_viewer = new LineViewer ();
            min_label_x = new Label (null);
            max_label_x = new Label (null);

            x_box.prepend (min_label_x);
            min_label_x.halign = START;
            min_label_x.hexpand = false;
            min_label_x.vexpand = false;
            x_box.append (max_label_x);
            max_label_x.halign = END;
            max_label_x.hexpand = false;
            max_label_x.vexpand = false;

            frame.set_child (line_viewer);

            line_viewer.popover_setter.disconnect (line_viewer.update_popover);
            line_viewer.popover_setter.connect (update_popover);
        }
        /**
         * Adds a line to the line graph
         */
        public Line add_line(string title) {
            Line line = Line ();
            line.points = new ArrayList<GraphPoint>();
            line.color = RGBA ();
            line.title = title;
            line.color.red = gnome_palette[colourn, 0] / 255f;
            line.color.blue = gnome_palette[colourn, 1] / 255f;
            line.color.green = gnome_palette[colourn, 2] / 255f;
            line.color.alpha = 1;
            line_viewer.lines.add (line);
            colourn++;
            return (line);
        }

        /**
         * Adds a point to the desired line.
         *
         * Returns null if the specified line does not exist.
         */
        public GraphPoint ? add_point (int line_n, string ? name, double x, double y)
        {
            if ( line_n < line_viewer.lines.size ) {
                Line line = line_viewer.lines[line_n];
                GraphPoint point = GraphPoint ();
                point.name = name;
                point.x = x;
                point.y = y;
                if ( line.points.size == 0 ) {
                    line.points.add (point);
                    return point;
                } else {
                    for ( int i = 0; i < line.points.size; i++ ) {
                        if ( line.points[i].x > x ) {
                            line.points.insert (i, point);
                            line_viewer.redraw_canvas ();
                            update_labels ();
                            return point;
                        }
                    }
                    line.points.add (point);
                    line_viewer.redraw_canvas ();
                    update_labels ();
                    return point;
                }
            }
            update_labels ();
            return null;
        }
        protected virtual void update_labels() {
            if ( unit_y == null ) {
                min_label.label = nice_double (get_min_value ());
                max_label.label = nice_double (get_max_value ());
            } else {
                min_label.label = "%s (%s)".printf (nice_double (get_min_value ()), unit_y);
                max_label.label = "%s (%s)".printf (nice_double (get_max_value ()), unit_y);
            }
            if ( unit_x == null ) {
                min_label_x.label = nice_double (get_min_value_x ());
                max_label_x.label = nice_double (get_max_value_x ());
            } else {
                min_label.label = "%s (%s)".printf (nice_double (get_min_value_x ()), unit_x);
                max_label.label = "%s (%s)".printf (nice_double (get_max_value_x ()), unit_x);
            }
        }

        public double get_max_value() {
            line_viewer.generate_max_mins ();
            return line_viewer.max_val;
        }

        public double get_min_value() {
            line_viewer.generate_max_mins ();
            return line_viewer.min_val;
        }

        public double get_max_value_x() {
            line_viewer.generate_max_mins ();
            return line_viewer.max_val_x;
        }

        public double get_min_value_x() {
            line_viewer.generate_max_mins ();
            return line_viewer.min_val_x;
        }

        /**
         * A method for setting the popover.
         */
        public virtual void update_popover(GraphPoint point, Line line, Label title, Label name, Label val) {
            if ( line.title != null ) {
                title.show ();
                title.set_markup ("<b>%s</b>".printf (line.title));
            } else title.hide ();
            if ( point.name != null ) {
                name.show ();
                name.set_markup ("<b>%s</b>".printf (point.name));
            } else name.hide ();
            string x_str = null;
            string y_str = null;
            if ( unit_y == null )
                y_str = nice_double (point.y);
            else
                y_str = "%s (%s)".printf (nice_double (point.y), unit_y);
            if ( unit_x == null )
                x_str = nice_double (point.x);
            else
                x_str = "%s (%s)".printf (nice_double (point.x), unit_y);
            val.label = "%s\n%s".printf (x_str, y_str);
        }

    }
    /**
     * A line graph widget which is especially good at displaying times.
     */
    public class LineGraphTime : LineGraph {
        /**
         * How far back from the most recent point should it show?
         */
        public TimeSpan ? timespan_shown;

        public LineGraphTime (string title, string x_axis_title, string y_axis_title) {
            base (title, x_axis_title, y_axis_title);
        }

        construct
        {
            timespan_shown = null;
        }
        public new GraphPoint ? add_point (int line_n, string ? name, DateTime x, double y)
        {
            GraphPoint p = base.add_point (line_n, name, x.to_unix (), y);
            line_viewer.override_min_val_x = get_max_value_x () - timespan_shown / 1000000;
            return p;
        }

        public override void update_labels() {
            if ( unit_y == null ) {
                min_label.label = nice_double (get_min_value ());
                max_label.label = nice_double (get_max_value ());
            } else {
                min_label.label = "%s (%s)".printf (nice_double (get_min_value ()), unit_y);
                max_label.label = "%s (%s)".printf (nice_double (get_max_value ()), unit_y);
            }

            DateTime max_time = new DateTime.from_unix_utc ((int64) (get_max_value_x ()));
            DateTime min_time = new DateTime.from_unix_utc ((int64) (get_min_value_x ()));

            if ( max_time.get_year () == min_time.get_year ()) { // Are they in the same year
                if ( max_time.get_day_of_year () == max_time.get_day_of_year ()) { // Are they the same day?
                    min_label_x.label = min_time.format ("%T");
                    max_label_x.label = max_time.format ("%T");
                } else {
                    min_label_x.label = min_time.format ("%a %b %e %T");
                    max_label_x.label = max_time.format ("%a %b %e %T");
                }
            } else {
                min_label_x.label = min_time.format ("%e %b %Y  %T");
                max_label_x.label = max_time.format ("%e %b %Y  %T");
            }
        }

        /**
         * A function for setting the text of a popover.
         */
        public override void update_popover(GraphPoint point, Line line, Label title, Label name, Label val) {
            if ( line.title != null ) {
                title.show ();
                title.set_markup ("<b>%s</b>".printf (line.title));
            } else title.hide ();
            if ( point.name != null ) {
                name.show ();
                name.set_markup ("<b>%s</b>".printf (point.name));
            } else name.hide ();
            string x_str = null;
            string y_str = null;
            if ( unit_y == null )
                y_str = nice_double (point.y);
            else
                y_str = "%s (%s)".printf (nice_double (point.y), unit_y);

            // Now for the time
            DateTime time = new DateTime.from_unix_utc ((int64) point.x);

            x_str = time.format ("%A %e %b %Y %T");
            val.label = "%s\n%s".printf (x_str, y_str);
        }

    }
}
