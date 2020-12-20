/*
 * chart.vala
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
using Gtk, Cairo, Math, Gee;
namespace Giraffe
	{
	/**
	 * A point on a graph
	 */
	public struct GraphPoint
		{
		public double x;
		public double y;
		public string? name;
		}
	[Description (nick="A Bar Chart", blurb="Contains many bars, with axis titles and all!")]
	public abstract class Chart : Grid
		{
		/**
		 * The label of the chart.
		 */
		public Label title_label;
		/**
		 * The label of the X axis of the bar chart.
		 */
		public Label x_axis_label;
		/**
		 * The label of the Y axis of the bar chart.
		 */
		public Label y_axis_label;
		
		/**
		 * The name of the X axis.
		 */
		public string x_axis_name {
			set {x_axis_label.label = value;}
			get {return x_axis_label.label;}
		}
		
		/**
		 * The name of the Y axis.
		 */	
		public string y_axis_name {
			set {y_axis_label.label = value;}
			get {return y_axis_label.label;}
		}
		
		/**
		 * The Title of the chart.
		 */
		public string title {
			set {title_label.label = value;}
			get {return title_label.label;}
		}
		
		/**
		 * Bit confusing: Just increment it by onw=e everytime you add something and use it to sample the colour
		 */
		protected int colourn=0;
		
		protected Frame frame;
		protected Box x_box;
		protected Box y_box;
		
		protected Label max_label = new Label(null);
		protected Label min_label = new Label("0");
		
		protected Allocation alloc;
		protected Chart(string title, string x_axis_name, string y_axis_name)
			{
			Object();
			this.title_label.set_markup("<big><b>%s</b></big>".printf(title));
			this.x_axis_label.set_markup("<b>%s</b>".printf(x_axis_name));
			this.y_axis_label.set_markup("<b>%s</b>".printf(y_axis_name));
			}
		construct
			{
			this.title_label = new Label(null);
			base.row_spacing=4;
			base.column_spacing=4;
			
			x_axis_label = new Label(null);
			y_axis_label = new Label(null);
			y_axis_label.angle=90;
			this.show.connect((a)=>{this.show_all();});
			
			x_box = new Box(HORIZONTAL,6);
			x_box.homogeneous = true;
			
			y_box = new Box(VERTICAL,6);
			y_box.pack_start(max_label,false,false,0);
			y_box.pack_end(min_label,false,false,0);
			
			frame = new Frame(null);
			base.attach(y_box,			1,1,1,1);
			base.attach(y_axis_label,	0,1,1,1);
			
			base.attach(x_box,			2,2,1,1);
			base.attach(x_axis_label,	2,3,1,1);
			
			base.attach(frame,2,1,1,1);
			base.attach(title_label,	0,0,3,1);
			
			size_allocate.connect(size_alloc);
			frame.shadow_type = ETCHED_OUT;
			frame.expand=true;
			}
		public void size_alloc(Allocation alloc)
			{
			this.set_allocation(alloc);
			this.alloc = alloc;
			}
		}
	}
