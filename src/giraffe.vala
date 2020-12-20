/*
 * giraffe.vala
 * 
 * Copyright 2020 John Toohey <john_t@mailo.com>
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
 * This file contains some functions that do not need be in Giraffe but are used by multiple components
 */
using Gdk, Cairo, Gtk;

/**
 * Giraffe is a simple Libary for creating graphs and charts in Gtk
 */
namespace Giraffe
	{
	const short[,] gnome_palette = 
	{
	{153, 193, 241},
	{ 98, 160, 234},
	{ 53, 132, 228},
	{ 28, 113, 216},
	{ 26,  95, 180},
	{143, 240, 164},
	{ 87, 227, 137},
	{ 51, 209, 122},
	{ 46, 194, 126},
	{ 38, 162, 105},
	{249, 240, 107},
	{248, 228,  92},
	{246, 211,  45},
	{245, 194,  17},
	{229, 165,  10},
	{255, 190, 111},
	{255, 163,  72},
	{255, 120,   0},
	{230,  97,   0},
	{198,  70,   0},
	{246,  97,  81},
	{237,  51,  59},
	{224,  27,  36},
	{192,  28,  40},
	{165,  29,  45},
	{220, 138, 221},
	{192,  97, 203},
	{145,  65, 172},
	{129,  61, 156},
	{ 97,  53, 131},
	{205, 171, 143},
	{181, 131,  90},
	{152, 106,  68},
	{134,  94,  60},
	{ 99,  69,  44}
	};
	RGBA[] get_colours_from_number(int n)
		{
		int s = (n%6)*5;
		RGBA[] rgba = {RGBA(),RGBA(),RGBA()};
		rgba[0].red = 		gnome_palette[s,0]/255f;
		rgba[0].blue = 		gnome_palette[s,1]/255f;
		rgba[0].green = 	gnome_palette[s,2]/255f;
		
		rgba[1].red = 		gnome_palette[s+1,0]/255f;
		rgba[1].blue = 		gnome_palette[s+1,1]/255f;
		rgba[1].green = 	gnome_palette[s+1,2]/255f;
		
		rgba[2].red = 		gnome_palette[s+2,0]/255f;
		rgba[2].blue = 		gnome_palette[s+2,1]/255f;
		rgba[2].green = 	gnome_palette[s+2,2]/255f;
		
		return rgba;
		}
	internal double map_range(double n, double start_min, double start_max, double end_min, double end_max)
		{
		return end_min + ((end_max - end_min) / (start_max - start_min)) * (n - start_min);
		}
	internal double map_range_flip(double n, double start_min, double start_max, double end_min, double end_max)
		{
		double normalised = map_range(n,start_min,start_max,0f,1f);
		return map_range(1-normalised,0f,1f,end_min,end_max);
		}
	internal string nice_double(double d) // Prints doubles to hide roundoff errors
		{
		string s = "%.15f".printf(d);
		int n = 0;
		for (int i = s.length-1; i > 0; i--)
			{
			if (s[i]=='0')
				{
				n++;
				}
			else break;
			}
		string f = s[0:s.length-n];
		if (f[f.length-1]=='.') f = f[0:f.length-1];
		return f;
		}
	}
