package h2d;

class FPSMeter extends h2d.Sprite{
	var sb 		: h2d.SpriteBatch;
	var num 	: h2d.NumberOpt;
	var label 	: h2d.Text;
	
	var maxSamples 	= 90;
	var sampleWidth = 1;
	var samples 	= new hxd.FloatStack(); 
	var spool 		= new hxd.Stack<h2d.SpriteBatch.BatchElement>();
	var baseline 	= 45;
	var samplingEnabled = true;
	var tile : h2d.Tile;
	
	var font : h2d.Font;
	
	public static inline var UI_RED 				= 0xffe54c53;
	public static inline var UI_GREEN 				= 0xff42ff80; 
	public static inline var UI_BLACK 				= 0xff000000; 
	
	
	public function new( p ) 	{
		super(p);
		
		var f: h2d.Font = font = hxd.res.FontBuilder.getFont("arial", 16);
		x = 10;
		y = 10;
		
		sb = new h2d.SpriteBatch( h2d.Tools.getWhiteTile(), this );
		sb.filter = true;
		
		num = new h2d.NumberOpt( f, this );
		label = new h2d.Text( f, this );
		label.x = 4;
		label.textColor = UI_RED;
		label.text = "FPS:";
		label.dropShadow = { dx:1, dy:1, color: UI_BLACK, alpha:1.0};
		
		num.x = label.x + label.textWidth + 2;
		num.color = h3d.Vector.fromColor(UI_RED);
		num.val = 60;
		num.y = label.y = baseline - 12 - 20;
		samples.reserve(maxSamples);
		tile = h2d.Tools.getWhiteTile().clone();
		tile.setCenterRatio(0, 0);
	}
	
	@:noDebug
	function updateBars(){
		var avg  = 0.0;
		for ( s in samples)
			avg += s;
		if( samples.length > 0.0 )
			avg /= samples.length;
		num.nb = Math.round(1.0 / avg);
		
		for ( e in sb.getElements()) spool.push(e);
		sb.removeAllElements();
		
		var stride = 1;
		var e = null;
		if ( spool.length == 0 ) 	e = sb.alloc(sb.tile);
		else 						{ e = spool.pop(); sb.add( e ); }
		
		e.tile 		= tile;
		e.x 		= 0;
		e.y 		= 0;
		e.height 	= baseline;
		e.width 	= maxSamples * (sampleWidth + stride);
		
		e.setColor( 0xff000000 );
		
		var cx = 0;
		var delta = 1.0 / 60.0;
		for ( s in samples ){
			var e = null;
			if ( spool.length == 0 ) 	e = sb.alloc(sb.tile);
			else 						{ e = spool.pop(); sb.add( e ); }
			
			var nbr 	= s / delta;
			var max 	= 3;
			if ( nbr > max ) nbr = max;
			
			var isBadFrame = nbr > 1.2;
			
			e.tile 		= tile;
			e.x 		= cx;
			var size 	= baseline / max * nbr;	
			e.y 		= baseline - size;
			e.height 	= size;
			
			e.width 	= sampleWidth;
			e.setColor( isBadFrame ? UI_RED : UI_GREEN );
			cx 			+= sampleWidth + stride;
		}
		
	}
	
	//var timer = 30.0;
	
	inline 
	function sample(val:Float){
		if ( !samplingEnabled ){
			samples.removeOrderedAt(0);
			return;
		}
		
		samples.push(val);
		while( samples.length > maxSamples )
			samples.removeOrderedAt(0);
	}
	
	public override function sync(c){
		sample( hxd.Timer.rdeltaT );
		super.sync(c);
		if ( visible ){
			updateBars();
		}
	}
	
}