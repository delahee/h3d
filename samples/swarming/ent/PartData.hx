package ent;
import h3d.Vector;
import hxd.Math;

@:publicFields
class PartData {
	var x 				: hxd.Float32;
	var y 				: hxd.Float32;
	var z 				: hxd.Float32;
				
	var dx 				: hxd.Float32;
	var dy 				: hxd.Float32;
	var dz 				: hxd.Float32;
				
	var gx 				: hxd.Float32;
	var gy 				: hxd.Float32;
	var gz 				: hxd.Float32;
			
	var frictx 			: hxd.Float32;
	var fricty 			: hxd.Float32;
	var frictz 			: hxd.Float32;
			
	var sizex 			: hxd.Float32;
	var sizey 			: hxd.Float32;
	
	var rotation 		: hxd.Float32;
	var drotation 		: hxd.Float32;
	var frictrotation 	: hxd.Float32;
	
	var scale 			: hxd.Float32;
	var frictscale 		: hxd.Float32;
		
	var life 			: hxd.Float32;
	var maxlife 		: hxd.Float32;
			
	var cr 				: hxd.Float32;
	var cg 				: hxd.Float32;
	var cb 				: hxd.Float32;
	var ca 				: hxd.Float32;
			
	var fricta  		: hxd.Float32;
	var time 			: hxd.Float32;
	var rtime 			: Int;
	var tile			: Null<h2d.Tile>;
	var delay			: hxd.Float32;
	
	var dataFloat		: hxd.Float32;
	var threshold		: hxd.Float32;
	
	var kill = false;
	var ready = false;
	var data : Dynamic;
	var update : PartData -> Void;
	var onDeath : PartData -> Void;
	
	var pos(get, set) : h3d.Vector;
	var dir(null, set) : h3d.Vector;
	var color(get, set) : Int;
	
	public function new() {
		reset();
	}
	
	public inline function setSize(w,h) {
		sizex = w;
		sizey = h;
	}
	
	inline function 		get_pos() 				return new h3d.Vector(x, y, z, 1);
	inline function 		set_pos(v:h3d.Vector)	{ x = v.x; y = v.y; z = v.z; return v; };
	
	inline function 		set_dir(v:h3d.Vector)	{ dx = v.x; dy = v.y; dz = v.z; return v; };
	
	inline function 		get_color():Int {
		return 
			Math.f2b(ca) << 24
		|	Math.f2b(cr) << 16
		|	Math.f2b(cg) << 8
		|	Math.f2b(cb);
	}
	
	inline function 		set_color(c:Int)	{ 
		cr = Math.b2f(c >> 16	);
		cg = Math.b2f(c >> 8	); 
		cb = Math.b2f(c			); 
		ca = Math.b2f(c >> 24	); 
		return c; 
	};
	
	public inline function reset() {
		x = y = z 		= 0.0;
		dx = dy = dz 	= 0.0;
		gx = gy = gz 	= 0.0;
		
		sizex = sizey 	= 1.0;
		rotation 		= 0.0;
		scale 			= 1.0;
		drotation 		= 0.0;
		threshold = 0;
		life 	= 256.0;
		maxlife = 0.0; // will be set by particule engine
		
		frictx = fricty = frictz = frictscale = fricta = frictrotation = 1.0;
		cr = cg = cb = ca = 1.0;
		
		update = null;
		tile = null;
		time = 0; 
		rtime = 0;
		delay = 0;
		kill = false;
		ready = false;
		data = null;
		onDeath = null;
	}
	
	public inline function randDir(s=0.0) {
		var z = Math.random() * 2.0 - 1.0;
		var a = Math.random() * 2.0 * Math.PI;
		var r = Math.sqrt( 1.0 - z * z );
		var x = r * Math.cos(a);
		var y = r * Math.sin(a);
		dx = x*s;
		dy = y*s;
		dz = z*s;
	}
	
	public inline function clone() {
		var p 			= new PartData();
		p.x				= this.x			;
		p.y				= this.y			;
		p.z				= this.z			;
		p.dx 			= this.dx 		    ;
		p.dy 			= this.dy 		    ;
		p.dz 			= this.dz 		    ;
		p.gx 			= this.gx 		    ;
		p.gy 			= this.gy 		    ;
		p.gz 			= this.gz 		    ;
		p.frictx 		= this.frictx 	    ;
		p.fricty 		= this.fricty 	    ;
		p.frictz 		= this.frictz 	    ;
		p.sizex 		= this.sizex 	    ;
		p.sizey 		= this.sizey 	    ;
		p.rotation 		= this.rotation 	;
		p.drotation 	= this.drotation    ;
		p.scale 		= this.scale 	    ;
		p.frictscale 	= this.frictscale	;
		p.life 			= this.life 		;
		p.cr 			= this.cr 		    ;
		p.cg 			= this.cg 		    ;
		p.cb 			= this.cb 		    ;
		p.ca 			= this.ca 		    ;
		p.kill 			= this.kill 		;
		p.fricta		= this.fricta		;
		p.tile			= this.tile			;
		p.time 			= 0					;
		p.delay			= this.delay		;
		p.onDeath		= this.onDeath		;
		p.threshold		= this.threshold	;
		return p;
	}
	
	public function delayedOne(f:PartData->Void,fr) :PartData->Void{
		return function(p) {
			if ( p.time > fr )
				f(p);
			p.update = null;
		}
	}
}