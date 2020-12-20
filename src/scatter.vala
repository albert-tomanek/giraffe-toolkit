/*
 * scatter.vala
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

using Gtk, Gdk, Cairo, Gee, Math;

namespace Giraffe
	{
	public class ScatterViewer : GraphViewer
		{
		/**
		 * The array of points the scatter plot uses
		 */
		public ArrayList<GraphPoint?> points;
		
		private RGBA label_color;
		
		/**
		 * Signal for modifying the popover
		 */
		public signal void popover_setter(GraphPoint point, Label title, Label name, Label val);
		
		construct
			{
			points = new ArrayList<GraphPoint?>();
			// Gets the colour of a label so that this looks good no matter what theme you use
			StyleContext style_context = popover_title.get_style_context();
			label_color = style_context.get_color();
			
			set_draw_func(draw);
			
			popover_setter.connect(default_popover_setter);
			gen();
			}
		protected void draw(DrawingArea? da, Context cr, int width, int height)
			{
			generate_max_mins();
			
			foreach (GraphPoint point in points)
				{
				double x = map_range(point.x,min_val_x,max_val_x,0,width);
				double y = map_range_flip(point.y,min_val,max_val,0,height);
				
				cr.set_source_rgb(label_color.red,label_color.green,label_color.blue);
				cr.rectangle(x-2,y-2,4,4);
				cr.fill();
				}
			}
		protected override void motion(double x, double y)
			{
			double width = get_allocated_width();
			double height = get_allocated_height();
			bool popup = false;
			foreach (GraphPoint point in points)
				{
				double lx = map_range(point.x,min_val_x,max_val_x,0,width);
				double ly = map_range_flip(point.y,min_val,max_val,0,height);
				double distance = pow((pow(x-lx,2)+pow(y-ly,2)),0.5); // Gets the distance away from the center of the pie
				if (distance<6 && y>point.y)
					{
					popover_setter(point,popover_title,popover_name,popover_value_label);
					Gdk.Rectangle rect = Gdk.Rectangle();
					rect.x=(int) lx;
					rect.y=(int) ly-6;
					rect.width=1;
					rect.height=1;
					popover.pointing_to = rect;
					popup=true;
					break;
					}
				}
			if (popup) popover.popup();
			else popover.popdown();
			}
		/**
		 * Generates the minimum and maximum values correctly
		 */
		public override void generate_max_mins()
			{
			min_val_x = 	 double.INFINITY;
			max_val_x =		-double.INFINITY;
			min_val = 		 double.INFINITY;
			max_val = 		-double.INFINITY;
			foreach (GraphPoint point in points)
				{
				min_val_x = double.min(point.x,min_val_x);
				min_val = 	double.min(point.y,min_val);
				max_val_x = double.max(point.x,max_val_x);
				max_val = double.max(point.y,max_val);
				}
			if (override_min_val!=null) min_val=override_min_val;
			if (override_min_val_x!=null) min_val_x=override_min_val_x;
			if (override_max_val!=null) max_val=override_max_val;
			if (override_max_val_x!=null) max_val_x=override_max_val_x;
			}
		/**
		 * The default popover setter
		 */
		public void default_popover_setter(GraphPoint point, Label title, Label name, Label val)
			{
			title.hide();
			if (point.name!=null)
				{
				name.show();
				name.set_markup("<b>%s</b>".printf(point.name));
				}
			else name.hide();
			val.label = "%s\t%s".printf(nice_double(point.x),nice_double(point.y));
			}
		}
	public class ScatterPlot : Chart
		{
		/**
		 * The unit on the Y axis.
		 */
		public string unit_y {get;set;}
		/**
		 * The unit on the X axis.
		 */
		public string unit_x {get;set;}
		/**
		 * The scatter viewer.
		 */
		public ScatterViewer scatter_viewer;
		
		private Label min_label_x;
		private Label max_label_x;
		public ScatterPlot(string title, string x_axis_name, string y_axis_name)
			{
			base(title,x_axis_name,y_axis_name);
			}
		construct
			{
			min_label_x = new Label(null);
			max_label_x = new Label(null);

			// Note in gtk4 they removed the angle property of labels. 
			
			x_box.prepend(min_label_x);
			x_box.append(max_label_x);
			
			min_label_x.hexpand=false;
			max_label_x.hexpand=false;
			min_label_x.vexpand=false;
			max_label_x.vexpand=false;
			
			min_label_x.halign=START;
			max_label_x.halign=END;
			
			scatter_viewer = new ScatterViewer();
			scatter_viewer.popover_setter.disconnect(scatter_viewer.default_popover_setter);
			scatter_viewer.popover_setter.connect(popover_setter);
			frame.set_child(scatter_viewer);
			notify.connect(update_labels);
			}
		public GraphPoint add_point(string title, int x, int y)
			{
			GraphPoint point = GraphPoint();
			point.x = x;
			point.y = y;
			point.name = title;
			scatter_viewer.points.add(point);
			return point;
			}
		protected virtual void popover_setter(GraphPoint point, Label title, Label name, Label val)
			{
			title.hide();
			if (point.name!=null)
				{
				name.show();
				name.set_markup("<b>%s</b>".printf(point.name));
				}
			else name.hide();
			string x_str;
			string y_str;
			if (unit_x==null) x_str = nice_double(point.x);
			else x_str = "%s (%s)".printf(nice_double(point.x),unit_x);
			
			if (unit_y==null) y_str = nice_double(point.y);
			else y_str = "%s (%s)".printf(nice_double(point.y),unit_y);
			
			val.label = "%s\t%s".printf(x_str,y_str);
			}
		protected virtual void update_labels()
			{
			if (unit_y==null)
				{
				min_label.label = nice_double(get_min_value());
				max_label.label = nice_double(get_max_value());
				}
			else
				{
				min_label.label = "%s (%s)".printf(nice_double(get_min_value()),unit_y);
				max_label.label = "%s (%s)".printf(nice_double(get_max_value()),unit_y);
				}
			if (unit_x==null)
				{
				min_label_x.label = nice_double(get_min_value_x());
				max_label_x.label = nice_double(get_max_value_x());
				}
			else
				{
				min_label.label = "%s (%s)".printf(nice_double(get_min_value_x()),unit_x);
				max_label.label = "%s (%s)".printf(nice_double(get_max_value_x()),unit_x);
				}
			}
		public double get_max_value()
			{
			scatter_viewer.generate_max_mins();
			return scatter_viewer.max_val;
			}
		public double get_min_value()
			{
			scatter_viewer.generate_max_mins();
			return scatter_viewer.min_val;
			}
		public double get_max_value_x()
			{
			scatter_viewer.generate_max_mins();
			return scatter_viewer.max_val_x;
			}
		public double get_min_value_x()
			{
			scatter_viewer.generate_max_mins();
			return scatter_viewer.min_val_x;
			}
		}
	}
