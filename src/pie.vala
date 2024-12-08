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
    public class ListModelNotifyListener: Object  // Esssentially `GLib.ListModel.items_changed` but for properties within the items as well.
    {
        GLib.ListModel lm;
        string property;

        Array<Gtk.ExpressionWatch> watches = new Array<Gtk.ExpressionWatch>();  // The objects in this array keep alive callbacks listening to updates on the object at the equivalent position in this.lm
        
        public signal void need_update();

        public ListModelNotifyListener(GLib.ListModel lm, string property)
        {
            this.lm = lm;
            this.property = property;
            
            this.on_items_changed(0, 0, lm.get_n_items());

            lm.items_changed.connect(this.on_items_changed);
            lm.items_changed.connect(() => this.need_update());
        }

        private void on_items_changed(uint pos, uint removed, uint added)
        {
            for (uint i = 0; i < removed; i++)
                this.watches.remove_index(pos).unwatch();
            for (uint i = 0; i < added; i++)
            {
                var exp = new Gtk.PropertyExpression(this.lm.get_item_type(), null, this.property);
                this.watches.insert_val(
                    pos+i,
                    exp.watch(
                        this.lm.get_item(pos+i),
                        () => {
                            this.need_update();
                        }
                    )
                );
            }
        }
    }

    /**
     * A simple class to store information about a pie segment
     *
     * Note does not provide a widget on its own: but provides data for the {@link Pie} and {@link AbsolutePie}.
     */
    [CCode (cname = "GirrafePieSegment")]
    public interface PieSegment : Object {
        /**
         * The value of the segment. Either a percentage when using {@link Pie}
         * or a absolute (when using {@link AbsolutePie})
         */
        public abstract double segmt_val { get; set construct; }    // TODO: Make it respond to changes
        public abstract int segmt_color_n { get; set; }

        public virtual RGBA get_segmt_color(RGBA suggested_color, int index_within_gradient)   // A rudimentary way to be able to set your own colours, that supports gradients too.
        {
            return suggested_color;
        }
    }

    public class NamedPieSegment : PieSegment, Object
    {
        public override double segmt_val { get; set construct; default = 0; }
        public override int segmt_color_n { get; set; }

        /** The title of the segment. */
        public string title { get; set construct; default = null; }

        public NamedPieSegment(string name, double val)
        {
            Object(title: name, segmt_val: val);
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
        public ListModel segments { get; construct; }   // Must not be null
        internal ListModelNotifyListener nl;
        public bool use_gradient { get; set; default = true; }
    
        public EventControllerMotion motion_controller;
        protected Gtk.DrawingArea da;
        
        public signal Gtk.Widget need_popover_contents(PieSegment segmt);
        
        public bool frame_instead_of_popover { get; set; default = false; }
        public Frame frame;
        public Popover popover;

        public PieSegment? popover_segmt { get; private set; default = null; }

        public Pie(ListModel segments)
        {
            Object(segments: segments);
        }
    
        construct
        {
            /* Box stuff */
            orientation = Gtk.Orientation.HORIZONTAL;
            spacing = 8;
            vexpand = true;
            
            /* Us stuff */
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
            
            this.segments.items_changed.connect((pos, removed, added) => {  // FIXME: If `this.segments` gets swapped out, the old listener will still exist afaik.
                this.colorn -= (int) removed;
                for (int i = 0; i < added; i++)     // Remember, more segments may have been added at once.
                    get_segment(pos + i).segmt_color_n = this.colorn++;

                    this.redraw_canvas();
                });
                
                this.popover = new Popover () {
                    autohide = false
            };
            // Listen for changes to the data within the segments
            this.nl = new ListModelNotifyListener(this.segments, "segmt-val");
            this.nl.need_update.connect_after(this.redraw_canvas);  // Decendants with their own max_val need to compute it first. connect_after: https://stackoverflow.com/a/45900559/6130358
            
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
                    if (this.popover_segmt == null)
                    this.popover.hide ();
                    else {
                        // Position
                        var rect = Gdk.Rectangle () {
                            width = 1,
                            height = 1
                        };
                        
                        // Calculate x and y
                        for (double i = 0, running_total = 0; i < this.segments.get_n_items(); i++)
                        {
                            var segmt = get_segment((uint) i);
                            
                            if (segmt == this.popover_segmt)
                            {
                                rect.x = (int) (cos ((((running_total + running_total + segmt.segmt_val) / 2) / max_val) * PI * 2) * (radius * 0.67)) + (da.get_allocated_width() / 2);
                                rect.y = (int) (sin ((((running_total + running_total + segmt.segmt_val) / 2) / max_val) * PI * 2) * (radius * 0.67)) + (da.get_allocated_height() / 2);
                                
                                break;
                            }
                            
                            running_total += segmt.segmt_val;
                        }
        
                        this.popover.pointing_to = rect;
                        
                        // Contents
                        this.popover.child = this.need_popover_contents(this.popover_segmt);
                        
                        this.popover.popup();
                    }
                }
                else
                {
                    if (this.popover_segmt != null)
                    this.frame.child = this.need_popover_contents(this.popover_segmt);
                    this.frame.child.halign = Gtk.Align.CENTER;
                    this.frame.child.valign = Gtk.Align.CENTER;
                }
            });
            
            // Default popover contents
            this.need_popover_contents.connect((segmt) => {
                var g = new Gtk.Grid();
                
                var l1 = new Gtk.Label((segmt as NamedPieSegment)?.title);
                g.attach(l1, 0, 0);
                
                var l2 = new Gtk.Label(@"$(segmt.segmt_val)%");
                g.attach(l2, 0, 1);
                
                return g;
            });
        }
        protected void part_description_area_draw_func(DrawingArea da, Context cr, int width, int height) {
            cr.rectangle ((width / 2) - 8, 0, 16, 16); // Creates a rectangle
            if ( segment_hovered != null ) { // Checks if a segment is actually installed
                PieSegment ps = get_segment(segment_hovered);

                if (!use_gradient) {
                    var ps_color = ps.get_segmt_color(get_colours_from_number(ps.segmt_color_n)[0], 0);
                    cr.set_source_rgb (
                        ps_color.red,
                        ps_color.blue,
                        ps_color.green
                    );
                } else {
                    Pattern pattern = new Pattern.linear (0, (height / 2) - radius, 0, (height / 2) + radius);
    
                    RGBA[] gradient_colors = get_colours_from_number (ps.segmt_color_n);
                    RGBA current;

                    current = ps.get_segmt_color(gradient_colors[0], 0);
                    pattern.add_color_stop_rgb (0, current.red, current.blue, current.green);

                    current = ps.get_segmt_color(gradient_colors[1], 1);
                    pattern.add_color_stop_rgb (0.5, current.red, current.blue, current.green);

                    current = ps.get_segmt_color(gradient_colors[2], 2);
                    pattern.add_color_stop_rgb (1, current.red, current.blue, current.green);

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
            
            for (uint i = 0; i < this.segments.get_n_items(); i++) {
                var ps = get_segment(i);

                // print ("Colour:\t%f\t%f\t%f\t%f\n",ps.color.red,ps.color.blue,ps.color.green,ps.color.alpha);
                // Sets the color for the pie-segment
                if ( use_gradient ) {
                    Pattern pattern = new Pattern.linear (0, (height / 2) - radius, 0, height / 2);
    
                    RGBA[] gradient_colors = get_colours_from_number (ps.segmt_color_n);
                    RGBA current;

                    current = ps.get_segmt_color(gradient_colors[0], 0);
                    pattern.add_color_stop_rgb (0, current.red, current.blue, current.green);

                    current = ps.get_segmt_color(gradient_colors[1], 1);
                    pattern.add_color_stop_rgb (0.5, current.red, current.blue, current.green);

                    current = ps.get_segmt_color(gradient_colors[2], 2);
                    pattern.add_color_stop_rgb (1, current.red, current.blue, current.green);
                    
                    cr.set_source (pattern);
                } else {
                    var ps_color = ps.get_segmt_color(get_colours_from_number(ps.segmt_color_n)[0], 0);
                    cr.set_source_rgba (
                        ps_color.red,
                        ps_color.blue,
                        ps_color.green,
                        ps_color.alpha
                    );
                }

                // Creates the pie-segment
                cr.arc (start_x, start_y,
                    radius,
                    (running_total / max_val) * Math.PI * 2,
                    ((ps.segmt_val + running_total) / max_val) * Math.PI * 2
                );

                cr.line_to (start_x, start_y); // Goes to the center of the arc
                cr.fill (); // Fills the arc
    
                running_total += ps.segmt_val; // Increases the running total
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
                for (uint i = 0; i < this.segments.get_n_items(); i++) {
                    var ps = get_segment(i);
    
                    if ( rot > running_total && rot < running_total + ps.segmt_val ) {
                        if (this.popover_segmt != ps)
                            this.popover_segmt = ps;
                    }
                    running_total += ps.segmt_val;
                    n++;
                }
            } else {
                if (this.popover_segmt != null)
                    this.popover_segmt = null;
            }
        }
        
        public PieSegment? get_segment (uint n) // Used to get a segment
        {
            return this.segments.get_item(n) as PieSegment;
        }
                
        public NamedPieSegment? get_segment_from_title (string title) // Used to get a segment from a title
        {
            for (uint i = 0; i < this.segments.get_n_items(); i++) {
                var nps = get_segment(i) as NamedPieSegment;
                if (nps != null)
                    if ( nps.title == name )
                        return (nps);
            }
            return null;
        }
                
        protected void redraw_canvas() {
            da.hide();
            da.show();
        }
        
        public void force_update()
        {
            this.nl.need_update();
        }
    }
    
    [Description (nick = "A Pie using absolute values", blurb = "Use this pie chart if you want the values to constantly change, rather than using percentages")]
    [CCode (cname = "GiraffeAbsolutePie")]
    public class AbsolutePie : Pie {
        public AbsolutePie(ListModel segments)
        {
            Object(segments: segments);
        }

        construct {
            this.max_val = 0;

            this.nl.need_update.connect(() => {     // When one of the items' values changes
                this.max_val = 0;
                for (int i = 0; i < this.segments.get_n_items(); i++)
                    this.max_val += get_segment(i).segmt_val;
            });

            this.need_popover_contents.connect((segmt) => {
                var g = new Gtk.Grid();
    
                var l1 = new Gtk.Label((segmt as NamedPieSegment)?.title);
                g.attach(l1, 0, 0);
    
                var l2 = new Gtk.Label(@"$(segmt.segmt_val)");
                g.attach(l2, 0, 1);

                var l3 = new Gtk.Label("(%.2f%%)".printf((segmt.segmt_val / max_val) * 100));
                g.attach(l3, 0, 2);

                return g;
            });
        }
    }
}
