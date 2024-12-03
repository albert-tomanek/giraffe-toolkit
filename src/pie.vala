/*
 * pie.vala
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

using Gtk, Cairo, Gee, Math, Gdk;

namespace Giraffe {
    /**
     * A simple class to store information about a pie segment
     *
     * Note does not provide a widget on its own: but provides data for the {@link Pie} and {@link AbsolutePie}.
     */
    [CCode (cname = "GirrafePieSegment")]
    public class PieSegment : Object {
        /** The title of the segment. */
        public string title { get; set construct; default = null; }
        /**
         * The value of the segment. Either a percentage when using {@link Pie}
         * or a absolute (when using {@link AbsolutePie})
         */
        public double val { get; set construct; default = 0; }
        /**
         * The colour the segment will appear.
         */
        public RGBA color;
        /**
         * Wether to use a default colour or not.
         */
        public bool use_palette_color { set; get; default = true; }
        /**
         * If {@link use_palette_color} then the number from the palette
         */
        public int palette_color;
        public PieSegment (string title, double val) {
            Object (title: title, val: val);
        }

        construct
        {
            color = RGBA ();
        }
    }

    /**
     * A Pie Chart Widget.
     */
    [Description (nick = "A Pie Chart", blurb = "A simple Pie chart which you give percentages!")]
    [CCode (cname = "GiraffePie")]
    public class Pie : Gtk.Box {

        public double max_val { get; protected set; }
        public int ? segment_hovered;
        protected int colorn;
        private int radius;
        public ArrayList<PieSegment> segments;
        public bool use_gradient { get; set; default = true; }
    
        public EventControllerMotion motion_controller;
        protected Gtk.DrawingArea da;
        
        public delegate Gtk.Widget CreatePopoverContents(PieSegment segmt);
        public CreatePopoverContents popover_contents_fn { get; set; default = null; }
        
        public bool frame_instead_of_popover { get; set; default = false; }
        protected Frame frame;
        protected Popover popover;

        protected int popover_segmt { get; set; default = -1; }
    
        construct
        {
            orientation = Gtk.Orientation.HORIZONTAL;
            spacing = 8;

            vexpand = true;
    
            this.max_val = 100;
    
            this.da = new Gtk.DrawingArea() {
                hexpand = true,
                vexpand = true,
                width_request = 160,
                height_request = 160
            };
            this.da.set_draw_func(draw);
            this.append(da);
    
            motion_controller = new EventControllerMotion ();
            this.motion_controller.motion.connect (draw_motion_notify_event);
            this.motion_controller.leave.connect (() => popover.popdown ());
            this.da.add_controller (motion_controller);
    
            this.segments = new ArrayList<PieSegment>();
    
            this.popover = new Popover () {
                autohide = false
            };
            this.popover.set_parent(this);

            this.frame = new Frame(null) {
                hexpand = false,
                vexpand = false,
                valign = Gtk.Align.CENTER,
                halign = Gtk.Align.END,
                width_request = 160
            };
            this.append(this.frame);
            this.bind_property("frame-instead-of-popover", frame, "visible", BindingFlags.SYNC_CREATE);
            this.bind_property("frame-instead-of-popover", this, "hexpand", BindingFlags.SYNC_CREATE);
    
            this.notify["popover-segmt"].connect(() => {
                if (!frame_instead_of_popover)
                {
                    if (this.popover_segmt == -1)
                        this.popover.hide ();
                    else {
                        // Position
                        var rect = Gdk.Rectangle () {
                            width = 1,
                            height = 1
                        };
        
                        // Calculate x and y
                        for (double i = 0, running_total = 0; i < this.segments.size; i++)
                        {
                            var segmt = this.segments[(int) i];
        
                            if (i == this.popover_segmt)
                            {
                                rect.x = (int) (cos ((((running_total + running_total + segmt.val) / 2) / max_val) * PI * 2) * (radius * 0.67)) + (da.get_allocated_width() / 2);
                                rect.y = (int) (sin ((((running_total + running_total + segmt.val) / 2) / max_val) * PI * 2) * (radius * 0.67)) + (da.get_allocated_height() / 2);
        
                                break;
                            }
        
                            running_total += segmt.val;
                        }
        
                        this.popover.pointing_to = rect;
        
                        // Contents
                        this.popover.child = this.popover_contents_fn(this.segments[this.popover_segmt]);
        
                        this.popover.popup();
                    }
                }
                else
                {
                    if (this.popover_segmt != -1)
                        this.frame.child = this.popover_contents_fn(this.segments[this.popover_segmt]);
                        this.frame.child.halign = Gtk.Align.CENTER;
                        this.frame.child.valign = Gtk.Align.CENTER;
                }
            });
    
            this.popover_contents_fn = (segmt) => {
                var g = new Gtk.Grid();
    
                var l1 = new Gtk.Label(segmt.title);
                g.attach(l1, 0, 0);
    
                var l2 = new Gtk.Label(@"$(segmt.val)%");
                g.attach(l2, 0, 1);
    
                return g;
            };
        }
        protected void part_description_area_draw_func(DrawingArea da, Context cr, int width, int height) {
            cr.rectangle ((width / 2) - 8, 0, 16, 16); // Creates a rectangle
            if ( segment_hovered != null ) { // Checks if a segment is actually installed
                PieSegment ps = segments[segment_hovered];
                if ( !(use_gradient && ps.use_palette_color)) {
                    // Sets the source color to the color of the hovered segment
                    cr.set_source_rgb (
                        ps.color.red,
                        ps.color.blue,
                        ps.color.green
                        );
                } else {
                    Pattern pattern = new Pattern.linear (0, (height / 2) - radius, 0, (height / 2) + radius);
    
                    RGBA[] colors = get_colours_from_number (ps.palette_color);
                    pattern.add_color_stop_rgb (0,
                                                colors[0].red,
                                                colors[0].blue,
                                                colors[0].green);
                    pattern.add_color_stop_rgb (0.5,
                                                colors[1].red,
                                                colors[1].blue,
                                                colors[1].green);
                    pattern.add_color_stop_rgb (1,
                                                colors[2].red,
                                                colors[2].blue,
                                                colors[2].green);
                    cr.set_source (pattern);
                }
            } else {
                cr.set_source_rgba (0, 0, 0, 0);
            }
            cr.fill (); // Fills the rectangles
    
        }
    
        protected void draw(DrawingArea da, Context cr, int width, int height) {
            // These variables
            double start_x;
            double start_y;
    
            radius = width / 2;
            if ( height / 2 < radius ) radius = height / 2;
    
            start_x = width / 2;
            start_y = height / 2;
    
            double running_total = 0;
    
            foreach ( PieSegment ps in segments ) {
                // print ("Colour:\t%f\t%f\t%f\t%f\n",ps.color.red,ps.color.blue,ps.color.green,ps.color.alpha);
                // Sets the color for the pie-segment
                if ( use_gradient ) {
                    Pattern pattern = new Pattern.linear (0, (height / 2) - radius, 0, height / 2);
    
                    RGBA[] colors = get_colours_from_number (ps.palette_color);
                    pattern.add_color_stop_rgb (0,
                                                colors[0].red,
                                                colors[0].blue,
                                                colors[0].green);
                    pattern.add_color_stop_rgb (0.5,
                                                colors[1].red,
                                                colors[1].blue,
                                                colors[1].green);
                    pattern.add_color_stop_rgb (1,
                                                colors[2].red,
                                                colors[2].blue,
                                                colors[2].green);
                    cr.set_source (pattern);
                } else {
                    cr.set_source_rgba (ps.color.red, ps.color.blue,
                                        ps.color.green,
                                        ps.color.alpha
                                        );
                }
                // Creates the pie-segment
                cr.arc (start_x, start_y,
                        radius,
                        (running_total / max_val) * Math.PI * 2,
                        ((ps.val + running_total) / max_val) * Math.PI * 2
    
                        );
    
                cr.line_to (start_x, start_y); // Goes to the center of the arc
                cr.fill (); // Fills the arc
    
                running_total += ps.val; // Increases the running total
            }
        }
    
        private void draw_motion_notify_event(Gtk.EventControllerMotion ecm, double rx, double ry) {
    
            double x = rx; // Gets the mouse position X
            double y = ry; // Gets the mouse position Y
    
            x -= this.da.get_allocated_width () / 2;
            y -= this.da.get_allocated_height () / 2;
    
            double distance = pow ((pow (x, 2) + pow (y, 2)), 0.5); // Gets the distance away from the center of the pie
            double rot = fmod (((atan2 (y, x) / PI) + 2) * (max_val / 2), max_val); // Gets the rotation (out of the maximum value)
            double running_total = 0; // Running total of the pie
            if ( distance < radius ) {
                int n = 0; // Which pie segment we are on
                foreach ( PieSegment ps in segments ) {
                    if ( rot > running_total && rot < running_total + ps.val ) {
                        if (this.popover_segmt != n)
                            this.popover_segmt = n;
                    }
                    running_total += ps.val;
                    n++;
                }
            } else {
                if (this.popover_segmt != -1)
                    this.popover_segmt = -1;
            }
        }
        
        public PieSegment ? get_segment (int n) // Used to get a segment
        {
            return (segments[n]);
        }
    
        
        public void remove_segment(int n) { // Used to remove a segment
            segments.remove_at (n); redraw_canvas ();
        }
        
        public PieSegment ? get_segment_from_title (string title) // Used to get a segment from a title
        {
            foreach ( PieSegment ps in segments )
                if ( ps.title == name )
                    return (ps);
            return null;
        }
        
        public void add_segment(string title, float percentage) { // Used to add a segment
            PieSegment ps = new PieSegment (title, percentage); // Creates a new Pie Segment
    
            ps.use_palette_color = true;
            ps.palette_color = colorn;
            colorn++;
    
            ps.color.red = gnome_palette[colorn, 0] / 255f; // Sets the color
            ps.color.blue = gnome_palette[colorn, 1] / 255f;
            ps.color.green = gnome_palette[colorn, 2] / 255f;
            ps.color.alpha = 1;
            segments.add (ps); ps.ref();
            redraw_canvas ();
        }
    
        
        protected void redraw_canvas() {
            // Redraw the Cairo canvas completely by exposing it
            this.hide ();
            this.show ();
        }
    
    }
    
    [Description (nick = "A Pie using absolute values", blurb = "Use this pie chart if you want the values to constantly change, rather than using percentages")]
    [CCode (cname = "GiraffeAbsolutePie")]
    public class AbsolutePie : Pie {
        construct {
            max_val = 0;

            this.popover_contents_fn = (segmt) => {
                var g = new Gtk.Grid();
    
                var l1 = new Gtk.Label(segmt.title);
                g.attach(l1, 0, 0);
    
                var l2 = new Gtk.Label(@"$(segmt.val)");
                g.attach(l2, 0, 1);

                var l3 = new Gtk.Label("(%.2f%%)".printf((segmt.val / max_val) * 100));
                g.attach(l3, 0, 2);

                return g;
            };
        }

        /**
         * Adds a segment from a title and a value
         */
        [CCode (cname = "giraffe_absolute_pie_add_segment")]
        public new void add_segment(string title, float pie_value) {
            PieSegment ps = new PieSegment (title, pie_value);
            this.hexpand = true;
            this.vexpand = true;
            ps.color = RGBA ();
            ps.color.red = gnome_palette[colorn, 0] / 255f;
            ps.color.blue = gnome_palette[colorn, 1] / 255f;
            ps.color.green = gnome_palette[colorn, 2] / 255f;
            ps.color.alpha = 1;
            segments.add (ps);
            ps.use_palette_color = true;
            ps.palette_color = colorn;
            max_val += pie_value;
            redraw_canvas ();
            colorn += 1;
        }

        /**
         * Gets the sum total of all the bar charts
         */
        [CCode (cname = "giraffe_absolute_pie_get_max_val")]
        protected double get_max_val() {
            return max_val;
        }

    }
}
