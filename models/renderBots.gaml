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
	matrix input_image_matrix <- image_file("../includes/data/render_test.jpg") as_matrix {image_width, image_height};
	matrix input_edge_matrix <- image_file("../includes/data/render_test_edges.png") as_matrix {image_width, image_height};
	matrix temp_buffer_matrix <- matrix_with ({image_width, image_height}, 0);
	list<input_edge> black_points <- input_edge where (each.color != #white);

	int number_render_edge <- 10;
	
	init
	{
		create renderBotEdge number: number_render_edge;
	}
}

species renderBot skills: [moving]
{
	rgb color;
	float size <- 0.1;
	input_image my_cell <- one_of (input_image) update: input_image(location);
	
	init
	{
		location <- my_cell.location;
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
	
	reflex move
	{
		geometry closest_black_point <- black_points 
		where (temp_buffer(each.location).edge_marker = false) 
		closest_to(self) using topology(grid);
		
		do goto target: closest_black_point using topology(grid);
	}
	
	reflex paint when: input_edge(location).color = #black
	{
		output_image(location).color <- rgb(#black);
		temp_buffer(location).edge_marker <- true;
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
	
}


grid output_image width: image_width height: image_height neighbors: 8 {
	rgb color <- rgb (255,255,255) ;
}


experiment render type: gui
{
	parameter "Height of the input image: " var: image_height category:"Image";
	parameter "Width of the input image: " var: image_width category:"Image";
	parameter "Number of edge bot renderer" var: number_render_edge category:"Renderer";
	output
	{
		display input_image_display 
		{
	        grid input_image;
	        species renderBotEdge aspect: base;
    	}
    	display input_edge_display 
		{
	        grid input_edge;
	        species renderBotEdge aspect: base;
    	}

    	display output_image_display
    	{
    		grid output_image;
    	}
    	
	}
}