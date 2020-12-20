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

namespace Giraffe
	{
	/**
	 * A simple class to store information about a pie segment
	 * 
	 * Note does not provide a widget on its own: but provides data for the {@link Pie} and {@link AbsolutePie}.
	 */
	[CCode(cname = "GirrafePieSegment")]
	public class PieSegment : Object
		{
		/** The title of the segment. */
		public string title {get;set construct; default=null;}
		/** 
		 * The value of the segment. Either a percentage when using {@link Pie}
		 * or a absolute (when using {@link AbsolutePie}) 
		 */
		public double val {get;set construct; default=0;}
		/**
		 * The colour the segment will appear.
		 */
		public RGBA color;
		/** 
		 * Wether to use a default colour or not.
		 */
		public bool use_palette_color {set;get;default=true;}
		/**
		 * If {@link use_palette_color} then the number from the palette
		 */
		public int palette_color;
		public PieSegment(string title, double val)
			{
			Object(title:title,val:val);
			}
		construct 
			{
			color = RGBA();
			}
		}
	
	/**
	 * A Pie Chart Widget.
	 */
	[Description (nick="A Pie Chart", blurb="A simple Pie chart which you give percentages!")]
	[CCode(cname = "GiraffePie")]
	public class Pie : DrawingArea
		{
		
		private Gtk.Grid part_description; // Information about the selected segment
		/**
		 * The label is the description of the active pie segment.
		 */
		protected Label part_description_label;
		/**
		 * The label is the value/percentage of the active pie segment.
		 */
		protected Label part_description_value_label;
		/**
		 * A small drawing area to contain the colour of the active pie segment
		 */
		private DrawingArea part_description_area;
		
		/**
		 * This is the value which the pie chart is out of. This is always 100 in the base class.
		 */
		public double max_val {get; protected set;}
		/**
		 * The number of the segment hovered.
		 * 
		 * Mainly used for internal workings but i guess it could be helpful.
		 */
		public int? segment_hovered;
		/**
		 * A number to select a colour.
		 */
		protected int colorn;
		private int radius;
		/**
		 * An arraylist of all the segments.
		 */
		public ArrayList<PieSegment?> segments;
		/**
		 * Should the pie chart use a gradient
		 */
		public bool use_gradient {get;set;default=true;}
		
		public EventControllerMotion motion_controller;
		
		protected Popover popover;
		/**
		 * Creates a new Pie from no arguments
		 */ 
		public Pie()
			{
			Object();
			}
		construct 
			{
			this.max_val=100;
			motion_controller = new EventControllerMotion();
			this.add_controller(motion_controller);
			this.motion_controller.motion.connect(draw_motion_notify_event);
			this.motion_controller.leave.connect(()=>popover.popdown());
			this.width_request = 64;
			this.height_request = 64;
			
			this.segments = new ArrayList<PieSegment?>();
			
			{
				popover = new Popover();
				popover.set_parent(this);
				popover.autohide=false;
				
				part_description = new Grid(); // Creates a box to store information about the segment
				part_description.row_homogeneous=true;
				part_description.column_homogeneous=true;
				
				
				part_description_label = new Label(""); // Creates a label
				part_description_label.ellipsize = END;
				part_description_value_label = new Label("");
				part_description_label.justify = CENTER;
				
				part_description_area = new DrawingArea(); // Creates a Drawing Area
				part_description_area.set_draw_func(part_description_area_draw_func);
				part_description_area.show();
				
				part_description_value_label.hexpand=true;
				part_description_area.hexpand=true;
				
				part_description.attach(part_description_label,0,0,2,1); // Adds the widgets to the box
				part_description.attach(part_description_value_label,0,1,1,1);
				part_description.attach(part_description_area,1,1,1,1);
				popover.set_child(part_description);
			}
			hexpand=true;
			vexpand=true;
			this.set_draw_func(draw);
			}
		protected void part_description_area_draw_func(DrawingArea da, Context cr, int width, int height)
			{
			cr.rectangle((width/2)-8,0,16,16); // Creates a rectangle
			if (segment_hovered!=null) // Checks if a segment is actually installed
				{	
				PieSegment ps = segments[segment_hovered];
				if (!(use_gradient && ps.use_palette_color))
					{
					// Sets the source color to the color of the hovered segment
					cr.set_source_rgb(
						ps.color.red,
						ps.color.blue,
						ps.color.green
					);
					}
				else
					{
					Pattern pattern = new Pattern.linear(0,(height/2)-radius,0,(height/2)+radius);
					
					RGBA[] colors = get_colours_from_number(ps.palette_color);
					pattern.add_color_stop_rgb(0,
						colors[0].red,
						colors[0].blue,
						colors[0].green);
					pattern.add_color_stop_rgb(0.5,
						colors[1].red,
						colors[1].blue,
						colors[1].green);
					pattern.add_color_stop_rgb(1,
						colors[2].red,
						colors[2].blue,
						colors[2].green);
					cr.set_source(pattern);	
					}
				}
			else
				{
				cr.set_source_rgba(0,0,0,0);
				}
				cr.fill(); // Fills the rectangles
				
			}
		protected void draw(DrawingArea da, Context cr, int width, int height)
			{
			// These variables
			double start_x;
			double start_y;
			
			radius = width/2;
			if (height/2<radius) radius = height/2;
			
			start_x = width/2;
			start_y = height/2;
			
			double running_total = 0;
			
			foreach (PieSegment ps in segments)
				{
				//print ("Colour:\t%f\t%f\t%f\t%f\n",ps.color.red,ps.color.blue,ps.color.green,ps.color.alpha);
				// Sets the color for the pie-segment
				if (use_gradient)
					{
					Pattern pattern = new Pattern.linear(0,(height/2)-radius,0,height/2);
					
					RGBA[] colors = get_colours_from_number(ps.palette_color);
					pattern.add_color_stop_rgb(0,
						colors[0].red,
						colors[0].blue,
						colors[0].green);
					pattern.add_color_stop_rgb(0.5,
						colors[1].red,
						colors[1].blue,
						colors[1].green);
					pattern.add_color_stop_rgb(1,
						colors[2].red,
						colors[2].blue,
						colors[2].green);
					cr.set_source(pattern);
					}
				else
					{
					cr.set_source_rgba (ps.color.red,ps.color.blue,
						ps.color.green,
						ps.color.alpha
					);
					}
				// Creates the pie-segment
				cr.arc(start_x,start_y,
					radius,
					(running_total/max_val)*Math.PI*2,
					((ps.val+running_total)/max_val)*Math.PI*2
					
				);
				
				cr.line_to(start_x,start_y); // Goes to the center of the arc
				cr.fill(); // Fills the arc
				
				running_total+=ps.val; // Increases the running total
				}
			}
		private void draw_motion_notify_event (Gtk.EventControllerMotion ecm, double rx, double ry) 
			{
			
			double x = rx; // Gets the mouse position X
			double y = ry; // Gets the mouse position Y
			
			x -= this.get_allocated_width() /2;
			y -= this.get_allocated_height() /2;
			
			double distance = pow((pow(x,2)+pow(y,2)),0.5); // Gets the distance away from the center of the pie 
			double rot = fmod(((atan2(y,x)/PI)+2)*(max_val/2),max_val); // Gets the rotation (out of the maximum value)
			double running_total=0; // Running total of the pie
			if (distance<radius)
				{
				int n = 0; // Which pie segment we are on
				foreach (PieSegment ps in segments)
					{
					if (rot>running_total && rot<running_total+ps.val)
						{
						segment_hovered=n; // Sets the hovered segment (used for labels)
						part_description_area.hide(); // Hides and shows the chart to redraw 
						part_description_area.show(); /// Yes i know there is a better way to do this but :D
						part_description_label.set_text("%s".printf(ps.title));
						
						if (!popover.visible) popover.popup();
						Gdk.Rectangle pointing_to = Gdk.Rectangle(); // Creates a rectangle so we know where to point!
						pointing_to.width = 1;
						pointing_to.height = 1;
						int w = get_allocated_width();
						int h = get_allocated_height();
						pointing_to.x = (int) (cos((((running_total + running_total+ps.val)/2)/max_val)*PI*2)*(radius*0.67))+(w/2);
						pointing_to.y = (int) (sin((((running_total + running_total+ps.val)/2)/max_val)*PI*2)*(radius*0.67))+(h/2);
						
						popover.pointing_to = pointing_to;
						}
					running_total+=ps.val;
					n++;
					}
				}
			else
				{
				popover.hide();
				part_description_value_label.set_text("");
				segment_hovered=null;
				part_description_area.hide(); // Hides and shows the chart to redraw 
				part_description_area.show(); /// Yes i know there is a better way to do this but :D
				}
			set_part_description_value();
			}
		/**
		 * Used to set the value on the popover.
		 * 
		 * You will not need to access it unless you are inheriting.
		 */
		protected virtual void set_part_description_value()
			{
			if (segment_hovered==null) // If a segment is not hovered
				part_description_label.set_text(""); // The set the text to nothing
			else
				{
				PieSegment ps = segments[segment_hovered];
				part_description_value_label.set_text("%s%%".printf(ps.val.to_string()));
				}
			}
		/**
		 * Gets a segment from its place in the list. 
		 * 
		 * Can be used with {@link segment_hovered}.
		 */
		[CCode(cname = "giraffe_pie_get_segment")]
		public PieSegment? get_segment(int n) // Used to get a segment
			{return(segments[n]);}
			
		/**
		 * Removes a segment from its place in the list.
		 * 
		 * Can be used with {@link segment_hovered}.
		 */
		[CCode(cname = "giraffe_pie_remove_segment")]
		public void remove_segment(int n) // Used to remove a segment
			{segments.remove_at(n);redraw_canvas();}
		/**
		 * Gets a segment from it's title. Returns the first one it finds.
		 */
		[CCode(cname = "giraffe_pie_get_segment_from_title")]
		public PieSegment? get_segment_from_title(string title) // Used to get a segment from a title
			{
			foreach (PieSegment ps in segments)
					if (ps.title==name)
						return(ps);
			return null;
			}
		/**
		 * Adds a segment from a title and a percentage
		 */
		[CCode(cname = "giraffe_pie_add_segment")]
		public void add_segment(string title, float percentage) // Used to add a segment
			{
			PieSegment ps = new PieSegment(title,percentage); // Creates a new Pie Segment
			
			ps.use_palette_color=true;
			ps.palette_color=colorn;
			colorn++;
			
			ps.color.red	= gnome_palette[colorn,0]/255f; // Sets the color
			ps.color.blue	= gnome_palette[colorn,1]/255f;
			ps.color.green	= gnome_palette[colorn,2]/255f;
			ps.color.alpha	= 1;
			segments.add(ps);
			redraw_canvas();
			}
		/**
		 * Redraws the Pie Chart
		 */
		[CCode(cname = "giraffe_pie_redraw_canvas")]
		protected void redraw_canvas()
			{
			// Redraw the Cairo canvas completely by exposing it
			this.hide();
			this.show();
			}
		}
	[Description (nick="A Pie using absolute values", blurb="Use this pie chart if you want the values to constantly change, rather than using percentages")]
	[CCode(cname = "GiraffeAbsolutePie")]
	public class AbsolutePie : Pie
		{
		public AbsolutePie()
			{
			base();
			max_val=0;
			}
		protected override void set_part_description_value()
			{
			if (segment_hovered==null)
				this.part_description_label.set_text("");
			else
				{
				PieSegment ps = segments[segment_hovered];
				this.part_description_value_label.set_text("%s\t%.1f%%".printf(ps.val.to_string(),(100*ps.val/max_val)));
				}
			}
		/**
		 * Adds a segment from a title and a value
		 */
		[CCode(cname = "giraffe_absolute_pie_add_segment")]
		public new void add_segment(string title, float pie_value)
			{
			PieSegment ps = new PieSegment(title,pie_value);
			this.hexpand=true;
			this.vexpand=true;
			ps.color=RGBA();
			ps.color.red	= gnome_palette[colorn,0]/255f;
			ps.color.blue	= gnome_palette[colorn,1]/255f;
			ps.color.green	= gnome_palette[colorn,2]/255f;
			ps.color.alpha	= 1;
			segments.add(ps);
			ps.use_palette_color=true;
			ps.palette_color=colorn;
			max_val+=pie_value;
			redraw_canvas();
			colorn+=1;
			}
		/**
		 * Gets the sum total of all the bar charts
		 */
		[CCode(cname = "giraffe_absolute_pie_get_max_val")]
		protected double get_max_val() {return max_val;}
		}
	}
