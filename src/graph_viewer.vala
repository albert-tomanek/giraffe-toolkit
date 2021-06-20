/*
 * graph_viewer.vala
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

using Gtk;

namespace Giraffe {
    public abstract class GraphViewer : DrawingArea {

        /**
         * A popover to display information about the hovered segment.
         */
        protected Popover popover;
        protected Box popover_box;
        /**
         * The title of the line.
         */
        protected Label popover_title;
        /**
         * The name of the segment.
         */
        protected Label popover_name;
        /**
         * The value of the segment.
         */
        protected Label popover_value_label;

        /**
         * The minimum value on the Y axis this graph will display.
         */
        public double min_val;
        /**
         * The maximum value on the Y axis this graph will display.
         */
        public double max_val;
        /**
         * The minimum value on the X axis this graph will display.
         */
        public double min_val_x;
        /**
         * The maximum value on the X axis this graph will display.
         */
        public double max_val_x;

        /**
         * Will override min_val unconditionally.
         */
        public double ? override_min_val;
        /**
         * Will override max_val unconditionally.
         */
        public double ? override_max_val;
        /**
         * Will override min_val_x unconditionally.
         */
        public double ? override_min_val_x;
        /**
         * Will override max_val_x unconditionally.
         */
        public double ? override_max_val_x;

        /**
         * Should we use a popover?
         */
        public bool use_popover;

        protected EventControllerMotion motion_controller;
        construct
        {
            use_popover = true;

            popover = new Popover ();
            popover.set_parent (this);
            popover.autohide = false;
            popover_box = new Box (VERTICAL, 3);
            popover_title = new Label (null);
            popover_name = new Label (null);
            popover_value_label = new Label (null);
            popover_box.prepend (popover_title);
            popover_box.prepend (popover_name);
            popover_box.prepend (popover_value_label);
            popover.set_child (popover_box);
            popover_box.show ();
            popover.set_position (TOP);

            this.motion_controller = new EventControllerMotion ();
            gen ();
            this.add_controller (motion_controller);
        }
        protected void gen() {
            this.motion_controller.motion.connect (motion);
            this.motion_controller.leave.connect ((a) => { popover.popdown (); });
        }

        /**
         * Redraws the canvas. Run this after adding a point manually (not if using a {@link LineGraph}.)
         */
        public void redraw_canvas() {
            resize (get_allocated_width (), get_allocated_height ());
        }

        public abstract void generate_max_mins();
        protected abstract void motion(double x, double y);

    }

}
