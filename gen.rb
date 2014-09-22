require 'json'

def populate_color( node )
	node["color"] = rand( 20 )
	if ( node.has_key? "children" )
		node["children"].each { |cnode|
			populate_color( cnode )
		}
	end
end

data = nil
File.open( 'app/flare.json' ) { |fh|
	data = JSON.parse( fh.read )
}

Kernel.srand(Time.now.usec)

populate_color( data )

File.open( 'app/flare_with_color.json', 'w' ) { |fh|
	fh.write( JSON.pretty_generate( data ) )
}
