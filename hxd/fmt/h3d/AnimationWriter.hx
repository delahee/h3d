package hxd.fmt.h3d;

import hxd.fmt.h3d.Data;
import h3d.anim.Animation;
import haxe.crypto.Crc32;

class AnimationWriter{
	var output : haxe.io.Output;
	static var MAGIC = "H3D.ANIM";
	static var VERSION = 1;
	
	public function new(o : haxe.io.Output) {
		output = o;
	}
	
	public static function make( anm : h3d.anim.Animation) : hxd.fmt.h3d.Animation {
		return anm.toData();
	}
	
	public function write(anm : h3d.anim.Animation){
		writeData( make( anm ));
	}
	
	public function writeData( anm : hxd.fmt.h3d.Data.Animation ) {
		output.bigEndian = false;
		output.writeString( MAGIC );
		output.writeInt32(VERSION);
		
		var nameLen = anm.name.length;
		output.writeInt32( nameLen );
		output.writeString( anm.name );
		
		output.writeInt32( Type.enumIndex(anm.type) );
		output.writeInt32( anm.frameStart );
		output.writeInt32( anm.frameEnd );
		output.writeInt32( anm.frameCount );
		
		output.writeFloat( anm.speed );
		output.writeFloat( anm.sampling );
		
		output.writeInt32( anm.objects.length );
		for ( o in anm.objects ) {
			
			output.writeInt32( o.targetObject.length );
			output.writeString( o.targetObject );
			
			output.writeInt32(  Type.enumIndex(o.format) );
			
			output.writeInt32( o.data.length );
			output.writeBytes( o.data,0,o.data.length );
		}
	}
	
}