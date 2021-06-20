/*
 * bar.vala
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
using Gtk, Cairo, Gdk, Gee, Math;


namespace Giraffe {
    /**
     * A single Bar
     *
     * Used primarily in Bar charts to display a value.
     *
     */
    [Description (nick = "A Single Bar", blurb = "Give it a double 0-1 and it will display it!")]
    public class Bar : DrawingArea {
        /**
         * The colour of the bar chart.
         *
         * Bars have theme-independent colours, so that they look good in charts.
         */
        public RGBA colour { get; set construct; }
        /**
         * The value the bar charts displays.
         *
         * If you imagine the bar chart as a fraction then this is the numerator.
         */
        public double val { get; set construct; }
        /**
         * The value of which "val" is out of.
         *
         * If you imagine the bar chart as a fraction then this is the denominator.
         */
        public double max_val { get; set construct; }
        /**
         * The smallest value the bar can display
         */
        public double min_val { get; set; default = 0; }
        /**
         * The title of the bar chart.
         *
         * It is displayed on the popover.
         */
        public string title { get; set construct; }
        /**
         * The unit of the bar (i.e. °C)
         */
        public string unit { get; set; }
        private Gdk.Rectangle rect;

        private Popover popover;
        private Box popover_box;
        private Label popover_title;
        private Label popover_value;

        private EventControllerMotion motion_controller;
        public Bar (RGBA colour, string title, double val, double max_val) {
            Object (colour: colour, title: title, val: val, max_val: max_val);
        }

        construct
        {
            rect = Gdk.Rectangle ();

            {
                this.set_hexpand (true);
                this.set_vexpand (true);
                this.set_valign (FILL);
                this.set_halign (FILL);
                // this.draw.connect(draw_func);

            }
            {
                popover = new Popover (); // Creates a popover
                popover.set_parent (this);
                popover.autohide = false; // Prevents it from blocking out other input

                popover_title = new Label (title); // Creates some Labels
                popover_value = new Label (null);

                popover_box = new Box (VERTICAL, 6); // Adds some things to a box
                popover_box.append (popover_value);
                popover_box.append (popover_title);
                popover_box.margin_bottom = 10;
                popover_box.margin_top = 10;
                popover_box.margin_end = 10;
                popover_box.margin_start = 10;

                popover.set_child (popover_box);
            }

            {
                motion_controller = new EventControllerMotion ();
                this.add_controller (motion_controller);
                this.motion_controller.motion.connect (motion_notify_events);
                this.motion_controller.leave.connect ((a) => { popover.popdown (); });
                this.set_draw_func (draw);
            }
            this.notify.connect (reload);
        }
        private void reload(ParamSpec ? ps) {
            if ( ps.name == "val" || ps.name == "max-val" || ps.name == "colour" ) {
                hide ();
                show ();
            }
        }

        protected void draw(DrawingArea da, Context cr, int width, int height) {
            cr.set_source_rgba // Sets the colours
            (
                colour.red,
                colour.blue,
                colour.green,
                colour.alpha
            );

            update_rect ();
            cr.rectangle (rect.x, rect.y, rect.width, rect.height);

            cr.fill ();

            popover.pointing_to = rect;
        }

        public void update_rect() {
            Gdk.Rectangle rect = Gdk.Rectangle ();
            int width = get_allocated_width (); // Gets our allocation
            int height = get_allocated_height ();
            double y;
            double dheight;
            if ( val < 0 ) {
                y = 0;
                dheight = val;
            } else {
                y = val;
                dheight = 0;
            }

            rect.x = 0;
            rect.y = (int) map_range (y, min_val, max_val, height, 0);
            rect.width = width;
            rect.height = (int) map_range (dheight, min_val, max_val, height, 0) - rect.y;
            this.rect = rect;
        }

        private void motion_notify_events(double x, double y) {

            if ( rect.x < x && x < rect.width + rect.x && rect.y < y && y < rect.height + rect.y ) { // Maths! Checks if the mouse is in the bar
                popover.popup (); // Update the popover
                popover.measure (VERTICAL, 100, null, null, null, null);

                popover_title.label = title;
                if ( unit != null )
                    popover_value.label = "%s (%s)".printf (val.to_string (), unit);
                else
                    popover_value.label = val.to_string ();
            } else
                popover.popdown (); // Closes the popover
        }

    }

    [Description (nick = "A Bar Chart", blurb = "Contains many bars, with axis; titles; and all!")]
    public class BarChart : Chart {
        public string unit { get; set; }
        public ArrayList<Bar> bars; // All the bars in the chart

        public Box bar_box;

        public BarChart (string title, string x_axis_name, string y_axis_name) {
            base (title, x_axis_name, y_axis_name);
        }

        construct
        {
            bar_box = new Box (HORIZONTAL, 6);
            frame.set_child (bar_box);
            bars = new ArrayList<Bar>();
            this.notify.connect (notify_actions);
        }
        public void add_bar(Bar bar) {
            bars.add (bar);
            bar_box.append (bar);
            Label lab = new Label (bar.title);
            x_box.append (lab);
            foreach ( Bar b in bars ) b.max_val = get_max_value ();

            run_bar_checks ();
        }

        public void add_bar_from_information(string title, double val) {
            RGBA colour = RGBA ();
            colour.red = gnome_palette[colourn, 0] / 255f;
            colour.blue = gnome_palette[colourn, 1] / 255f;
            colour.green = gnome_palette[colourn, 2] / 255f;
            colour.alpha = 1;

            colourn += 13;
            colourn = colourn % 35;
            Bar bar = new Bar (colour, title, val, get_max_value ());
            bar.val = val;
            bar.title = title;
            add_bar (bar);
        }

        public void run_bar_checks() {
            foreach ( Bar b in bars ) b.max_val = get_max_value ();
            foreach ( Bar b in bars ) b.min_val = get_min_value ();
            foreach ( Bar b in bars ) b.unit = unit;
        }

        public double get_max_value() { // Gets the max value
            double max_val = 0;
            foreach ( Bar bar in bars ) {
                if ( bar.val > max_val ) max_val = bar.val;
            }
            max_val *= 1.1;

            if ( unit != null ) max_label.label = "%s (%s)".printf (nice_double (max_val), unit);
            else max_label.label = nice_double (max_val);
            return max_val;
        }

        public double get_min_value() { // Gets the max value
            double min_val = 0;
            foreach ( Bar bar in bars ) {
                min_val = double.min (min_val, bar.val);
            }
            min_val *= 1.1;

            if ( unit != null ) min_label.label = "%s (%s)".printf (nice_double (min_val), unit);
            else min_label.label = nice_double (min_val);
            return min_val;
        }

        protected void notify_actions(ParamSpec ? ps) {
            if ( ps.name == "unit" )
                run_bar_checks ();
        }
    }
}
