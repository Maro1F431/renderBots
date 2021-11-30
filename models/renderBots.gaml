/**
* Name: renderBots
* Based on the internal empty template. 
* Author: marow
* Tags: 
*/


model renderBots

/* Insert your model definition here */

global
{
	int image_width <- 416;
	int image_height <- 416;
	matrix input_image_matrix <- image_file("../includes/data/render_test.png") as_matrix {image_width, image_height};
	matrix input_edge_matrix <- image_file("../includes/data/render_test_edges.png") as_matrix {image_width, image_height};
	matrix temp_buffer_matrix <- matrix_with ({image_width, image_height}, 0);
	list<input_edge> black_points <- input_edge where (each.color != #white);

	int number_render_edge <- 0;
	int number_render_hatching <- 0;
	int number_render_stippling <- 100;
	
	init
	{
		//create renderBotEdge number: number_render_edge;
		create renderBotStippling number: number_render_stippling;
		//create renderBotHatching number: number_render_hatching;
	}
}

species renderBot skills: [moving]
{
	rgb color;
	float size <- 0.35;
	
	init
	{
		location <- one_of(input_image).location;
	}
	aspect base
	{
		draw circle(size) color: color;
	}
	
	
	reflex simulate
	{
		
	}
	reflex move
	{
		
	}
	reflex paint
	{
		
	}
}

species renderBotEdge parent: renderBot
{
	rgb color <- #blue;
	bool on_edge <- false;
	int nb_cycle_not_on_edge <- 0;
	float help_heading;
	bool help_needed <- false;
	
	reflex move
	{
		geometry closest_black_point <- input_edge at_distance 3
		where (input_edge(each.location).color = #black and temp_buffer(each.location).edge_marker = false)
		closest_to (self);
		
		if (input_edge(location).color = #black)
		{
			on_edge <- true;
			nb_cycle_not_on_edge <- 0;
		}
		else
		{
			nb_cycle_not_on_edge <- nb_cycle_not_on_edge + 1;
		}
		
		if (closest_black_point != nil)
		{
			do goto target: closest_black_point;
		}
		else
		{
			if (nb_cycle_not_on_edge > 0) and (nb_cycle_not_on_edge mod 50 = 0)
			{
				renderBotEdge closest_bot_found_edge <- renderBotEdge at_distance 50 where (each.on_edge = true) closest_to (self);
				if (closest_bot_found_edge != nil and help_needed = false)
				{
					help_heading <- location towards closest_bot_found_edge;
					help_needed <- true;
				}
				else
				{
					help_needed <- false;
					do wander;
				}
			}
			else
			{
				if (help_needed = true)
				{
					heading <- help_heading;
					do move;
				}
				else
				{
					do wander;
					
				}
			}
			
		}
	}
	
	reflex paint when: input_edge(location).color = #black
	{
		output_image(location).color <- rgb(#black);
		temp_buffer(location).edge_marker <- true;
	}	
}






species renderBotStippling skills: [moving]
{
	rgb color <- #black;
	float size <- 0.35;
	list<renderBotStippling> bot_in_radius;
	
	init
	{
		location <- one_of(input_image).location;
	}
	aspect base
	{
		draw circle(size) color: color;
	}
	
	float softmax(int x)
	{
		return x = 0 ? 0 : 1/(1 + exp(-x));
	}
	
	float compute_intens
	{
		float neighborhood_intensity_input <- 0.0;
		list<input_image> neighbors_input <- input_image at_distance size;
		loop i from: 0 to: length(neighbors_input) - 1 
		{
			input_image n_input <- neighbors_input[i];
			neighborhood_intensity_input <- neighborhood_intensity_input + (n_input.color.red * 0.299 + n_input.color.green * 0.587 + n_input.color.blue * 0.114);
		}
		neighborhood_intensity_input <- neighborhood_intensity_input / length(neighbors_input);		
		return neighborhood_intensity_input;
	}
	
	reflex simulate
	{ 
		float search_radius <- ( (compute_intens()/255) * 100)* (size/100) * 100;
		write(search_radius); 
		bot_in_radius <- renderBotStippling at_distance search_radius;
		loop bot over: bot_in_radius
		{
			heading <- heading + ((self towards bot) - 180);
		}
	}
	reflex move
	{
		speed <- softmax(length(bot_in_radius));
		do move;	
	}
}











species renderBotHatching parent: renderBot
{
	rgb color <- #red;
	float size <- 1.0;
	path last_path <- nil;
	float intens_diff <- 0.0 update: every(1#cycle) ? compute_intens_diff() : intens_diff;
	bool alternate <- false;
	int nb_cycle_is_drawing update: intens_diff > 0 ? nb_cycle_is_drawing + 1 : 0;
	float main_heading <- 0.0;
	
	init
	{
		location <- one_of (input_image where (each.grid_x = 0)).location; 
		
	}
	
	float compute_intens_diff
	{
		float neighborhood_intensity_input <- 0.0;
		float neighborhood_intensity_output <- 0.0;
		list<input_image> neighbors_input <- input_image at_distance 5 using topology(input_image);
		list<output_image> neighbors_output <- output_image at_distance 5 using topology(output_image);
		loop i from: 0 to: length(neighbors_input) - 1
		{
			input_image n_input <- neighbors_input[i];
			output_image n_output <-neighbors_output[i];
			neighborhood_intensity_input <- neighborhood_intensity_input + (n_input.color.red * 0.299 + n_input.color.green * 0.587 + n_input.color.blue * 0.114);
			neighborhood_intensity_output <- neighborhood_intensity_output + (n_output.color.red * 0.299 + n_output.color.green * 0.587 + n_output.color.blue * 0.114);
		}
		neighborhood_intensity_input <- neighborhood_intensity_input / length(neighbors_input);
		neighborhood_intensity_output <- neighborhood_intensity_output / length(neighbors_output);
		
		return neighborhood_intensity_output - neighborhood_intensity_input;
	}
	
	reflex simulate
	{
		main_heading <- destination = nil ? main_heading + 180 mod 360 : main_heading;
		heading <- main_heading;
		list<renderBotHatching> neighbors_hatch_bot <- renderBotHatching at_distance 5;
		list<temp_buffer> marked_hatch <- temp_buffer at_distance 1 where (each.hatch_marker = true and (location towards each <= 90 or location towards each >= 270));
		loop n over: neighbors_hatch_bot
		{
			float angle <- location towards n.location;
			angle <- angle > 180 ? -(360 - angle) : angle;
			float correction <- -(0.1) * angle;
			heading <- heading + correction;
		}
			
		loop n over: marked_hatch
		{
			float angle <- location towards n.location;
			angle <- angle > 180 ? -(360 - angle) : angle;
			float correction <- -(0.1) * angle;
			heading <- main_heading = 0 ? heading + correction : heading - correction;
		}
		if nb_cycle_is_drawing mod 2 = 0
		{
			alternate <- !alternate;
		}
		
		if (intens_diff > 20 and !alternate and length(renderBotHatching at_distance 5) < 3)
		{
			create species(self) number:1 { location <- myself.location; alternate <- false; intens_diff <- myself.intens_diff;}
		}
	}
	
	reflex move
	{
		int nb_left_neighbors <- 0;
		int nb_right_neighbors <- 0;
		if(destination != nil)
		{
			last_path <- topology(input_image) path_between [input_image(location), input_image(destination)];
			do move;
				
		}
	}
	
	reflex paint when: last_path != nil and destination != nil and (intens_diff > 0 and !alternate)
	{
		loop v over: last_path.vertices
		{
			output_image(v).color <- rgb(#black);
			temp_buffer(v).hatch_marker <- true;
		}
	}	
	
}




































grid input_image width: image_width height: image_height neighbors: 8 {
	rgb color <- rgb (input_image_matrix at {grid_x,grid_y}) ;
	
}

grid input_edge width: image_width height: image_height neighbors: 8 {
	rgb color <- rgb (input_edge_matrix at {grid_x,grid_y}) ;
	
}

grid temp_buffer width: image_width height: image_height neighbors: 8 {
	rgb color <- rgb(temp_buffer_matrix at {grid_x, grid_y});
	bool edge_marker <- false;
	bool hatch_marker <- false;
	
}


grid output_image width: image_width height: image_height neighbors: 8 {
	rgb color <- rgb(#white);
}


experiment render type: gui
{
	parameter "Height of the input image: " var: image_height category:"Image";
	parameter "Width of the input image: " var: image_width category:"Image";
	parameter "Number of edge bot renderer" var: number_render_edge category:"Renderer";
	parameter "Number of hatching bot renderer" var: number_render_hatching category:"Renderer";
	parameter "Number of stippling bot renderer" var: number_render_stippling category:"Renderer";
	output
	{
		display input_image_display 
		{
	        grid input_image;
	        species renderBotEdge aspect: base;
	        species renderBotHatching aspect:base;
	        species renderBotStippling aspect:base;
    	}
    	display input_edge_display 
		{
	        grid input_edge;
	        species renderBotEdge aspect: base;
    	}

    	display output_image_display
    	{
    		grid output_image;
    		species renderBotStippling aspect: base;
    	}
    	
	}
}