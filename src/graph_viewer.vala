/*
 * graph_viewer.vala
 * 
 * Copyright 2020 John Toohey <john_t@mailo.com>
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

namespace Giraffe
	{
	public abstract class GraphViewer : DrawingArea
		{

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
		public double? override_min_val;
		/**
		 * Will override max_val unconditionally.
		 */
		public double? override_max_val;
		/**
		 * Will override min_val_x unconditionally.
		 */
		public double? override_min_val_x;
		/**
		 * Will override max_val_x unconditionally.
		 */
		public double? override_max_val_x;
		
		/**
		 * Should we use a popover?
		 */
		public bool use_popover;
		
		protected EventControllerMotion motion_controller;
		construct
			{
			use_popover=true;
			
			popover = new Popover(this);
			popover.modal = false;
			popover_box= new Box(VERTICAL,3);
			popover_title = new Label(null);
			popover_name = new Label(null);
			popover_value_label = new Label(null);
			popover.add(popover_box);
			popover_box.pack_start(popover_title,false,false,0);
			popover_box.pack_start(popover_name,false,false,1);
			popover_box.pack_start(popover_value_label,false,false,2);
			popover_box.show_all();
			popover.border_width=6;
			
			this.motion_controller = new EventControllerMotion(this);
			}
		protected void gen()
			{
			this.add_events(Gdk.EventMask.ALL_EVENTS_MASK);
			this.motion_controller.motion.connect(motion);
			this.motion_controller.leave.connect((a)=>{popover.popdown();});
			this.leave_notify_event.connect((a)=> {popover.popdown(); return true;} );
			}
		/**
		 * Redraws the canvas. Run this after adding a point manually (not if using a {@link LineGraph}.)
		 */
		public void redraw_canvas ()
			{
			queue_draw_area(0,0,get_allocated_width(),get_allocated_height());
			}
		public abstract void generate_max_mins();
		protected abstract void motion(double x, double y);
		}
	
	}
