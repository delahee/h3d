import h3d.scene.Lines3d;
import bm.Dice;

class SwarmingPart extends ent.PartData {
	
	//non normalized speed vector
	public var speed 		: h3d.Vector = new h3d.Vector(0, 0, 0);
	
	public var align	 	: h3d.Vector = new h3d.Vector(0, 0, 0);
	public var cohesion 	: h3d.Vector = new h3d.Vector(0, 0, 0);
	public var separation 	: h3d.Vector = new h3d.Vector(0, 0, 0);
	public var decisionVector : h3d.Vector = new h3d.Vector(0, 0, 0);
	
	public var gs = 0.1;
	
	public static var GLOBAL_SPEED = 1.0;
	
	public function new() {
		super();
		speed = h3d.Vector.random().mulScalar3(gs* Dice.rollF(0.04,0.05) * GLOBAL_SPEED);
	}
	
	public function updateSwarm(tmod=1.0) {
		//find some neighbours
		//wander farther
		
		updateCohesion();
		updateSeparation();
		updateAlign();
		
		/*
		updateAlignFull();
		updateCohesionFull();
		updateSeparationFull();
		*/
		decisionVector.zero();
		
		var tracking = Demo.me.trackingPos.sub(pos).getNormalized();
		decisionVector.incr( tracking.mulScalar3(TRACKING_FACTOR) );
		
		var thirdPary = Demo.me.thirdPartyPos.sub(pos).getNormalized();
		decisionVector.incr( thirdPary.mulScalar3(THIRD_PARTY_FACTOR) );
		
		decisionVector.incr( align.mulScalar3(ALIGNMENT_FACTOR) ); 
		decisionVector.incr( cohesion.mulScalar3(COHESION_FACTOR) ); 
		decisionVector.incr( separation.mulScalar3(SEPARATION_FACTOR) ); 
		decisionVector.normalize();
		
		//decisionVector.mulScalar3( gs * 0.005 );
		//decisionVector.zero();
		//speed.lerp( speed.clone(), decisionVector, 0.5 );
		speed.incr( decisionVector );
		speed.normalize();
		speed.scale3( gs * Dice.rollF(0.009,0.01) * GLOBAL_SPEED);
		
		x += speed.x * tmod;
		y += speed.y * tmod;
		z += speed.z * tmod;
	}
	
	public static var TRACKING_FACTOR = 0.05;
	public static var COHESION_FACTOR = 0.2;
	public static var ALIGNMENT_FACTOR = 0.2;
	public static var SEPARATION_FACTOR = 0.5;
	
	public static var THIRD_PARTY_FACTOR = 0.0;
	public static inline var SAMPLE_FACTOR = 0.2;
	
	public function updateAlign() {
		var ags : hxd.Stack<SwarmingPart> = agents();
		var nb = 0;
		align.zero();
		var start = bm.Dice.roll(0, Math.floor(ags.length * (1.0-SAMPLE_FACTOR)) );
		var end = start + Math.floor(ags.length * SAMPLE_FACTOR);
		for ( i in start...end ) {
			var a = ags.unsafeGet(i);
			if( a.pos.dist2(pos) < IS_CLOSE*IS_CLOSE){
				align.incr( a.speed );
				nb++;
			}
		}
		if( nb > 0 ){
			align.scale3(1.0 / nb);
			align.normalize();
		}
	}
	
	public function updateAlignFull() {
		var ags : hxd.Stack<SwarmingPart> = agents();
		var nb = 0;
		align.zero();
		var start = 0;
		var end = ags.length;
		for ( i in start...end ) {
			var a = ags.unsafeGet(i);
			if( a!=this && a.pos.dist2(pos) < IS_CLOSE*IS_CLOSE){
				align.incr( a.speed );
				nb++;
			}
		}
		if( nb > 0 ){
			align.scale3(1.0 / nb);
			align.normalize();
		}
	}
	
	public function updateCohesionFull() {
		var ags = agents();
		var nb = 0;
		cohesion.zero();
		
		var start = 0;
		var end = ags.length;
		for ( i in start...end ) {
			var a = ags.unsafeGet(i);
			if( a!=this && a.pos.dist2(pos) < IS_CLOSE*IS_CLOSE){
				cohesion.incr( a.pos );
				nb++;
			}
		}
		if( nb > 0 ){
			cohesion.scale3(1.0/nb);
			cohesion.decr( pos );
			cohesion.normalize();
		}
	}
	
	public function updateSeparationFull() {
		var ags : hxd.Stack<SwarmingPart> = agents();
		var nb = 0;
		separation.zero();
		var start = 0;
		var end = ags.length;
		for ( i in start...end ) {
			var a = ags.unsafeGet(i);
			if( a !=  this && a.pos.dist2(pos) < IS_CLOSE*IS_CLOSE){
				separation.incr( a.pos.sub(pos) );
				nb++;
			}
		}
		if( nb > 0 ){
			separation.scale3( - 1.0 / nb);
			separation.normalize();
		}
	}
	
	public function updateCohesion() {
		var ags : hxd.Stack<SwarmingPart> = agents();
		var nb = 0;
		cohesion.zero();
		var start = bm.Dice.roll(0, Math.floor(ags.length * (1.0-SAMPLE_FACTOR)) );
		var end = start + Math.floor(ags.length * SAMPLE_FACTOR);
		for ( i in start...end ) {
			var a = ags.unsafeGet(i);
			if( a!=this && a.pos.dist2(pos) < IS_CLOSE*IS_CLOSE){
				cohesion.incr( a.pos );
				nb++;
			}
		}
		if( nb > 0 ){
			cohesion.scale3(1.0/nb);
			cohesion.decr( pos );
			cohesion.normalize();
		}
	}
	
	public function updateSeparation() {
		var ags = agents();
		var nb = 0;
		separation.zero();
		var start = bm.Dice.roll(0, Math.floor(ags.length * (1.0-SAMPLE_FACTOR)) );
		var end = start + Math.floor(ags.length * SAMPLE_FACTOR);
		for ( i in start...end ) {
			var a = ags.random();
			if( a.pos.dist2(pos) < IS_CLOSE*IS_CLOSE){
				separation.incr( a.pos.sub(pos) );
				nb++;
			}
		}
		if( nb > 0 ){
			separation.scale3( - 1.0 / nb);
			separation.normalize();
		}
	}
	
	public static function staticUpdate() {
		if ( bm.Dice.percent( 5 )) 
			GLOBAL_SPEED += 0.05 * bm.Dice.sign();
			
		//if ( bm.Dice.percentF( 0.33 )) 
		//	TRACKING_FACTOR = - TRACKING_FACTOR;
			
		if ( bm.Dice.percentF( 0.25
		)) {
			Demo.me.thirdPartyPos.setRandom();
			THIRD_PARTY_FACTOR = 0.9;
		}
			
		THIRD_PARTY_FACTOR *= 0.96;
	}
	
	public static var tempVec = new h3d.Vector();
	public static var IS_CLOSE = 0.2;
	public inline function agents() : hxd.Stack<SwarmingPart> return Demo.me.parts;
}

class Demo extends flash.display.Sprite{
	var engine : h3d.Engine;
	var scene : h2d.Scene;
	var scene3d : h3d.scene.Scene;
	var partMan : ent.Part;
	public var parts : hxd.Stack<SwarmingPart> = new hxd.Stack<SwarmingPart>();
	var tile : h2d.Tile;
	var lib : mt.deepnight.slb.BLib;
	
	public var trackingPos : h3d.Vector = new h3d.Vector(0, 0, 0);
	var trackingPoint : mt.heaps.Api3D.Point;
	
	public var thirdPartyPos : h3d.Vector = new h3d.Vector(0, 0, 0);
	var thirdPartyPoint : mt.heaps.Api3D.Point;
	
	var lines : h3d.scene.Lines3d;
	var lineDataV : h3d.scene.Lines3d.Line3dData;
	var lineDataH : h3d.scene.Lines3d.Line3dData;
	
	
	var whiteTile : h2d.Tile;
	var k : bm.Keys;
	
	public static var me:Demo;
	
	function new() {
		super();
		me = this;
		engine = new h3d.Engine();
		engine.onReady = init;
		engine.backgroundColor = 0xFFCCCCCC;
		h2d.Drawable.DEFAULT_FILTER = true;
		engine.init();
	}
	
	function init() {
		lib = mt.deepnight.slb.assets.TexturePacker.importXml("assets/FX.xml",true); 
		scene = new h2d.Scene();
		scene3d = new h3d.scene.Scene();
		scene3d.addPass( scene );
		mt.heaps.Api3D.scene = scene3d;
		whiteTile = h2d.Tile.fromColor( 0xffffffff, 4, 4);
		
		partMan = new ent.Part( lib.getTile("snow",0.5,0.5), scene3d);
		partMan.zsort = true;
		//partMan.material.setFastFog( new h3d.Vector(1, 0, 1, 1), new h3d.Vector(0.1,0.8,) );
		mt.heaps.Api3D.setFastFog( partMan, 0xcdcdcd, 0.05, 2.0, 0.1, 0.01);
		
		//scene3d.camera.pos
		for( p in 0...256){
			var p : SwarmingPart = cast partMan.alloc( new SwarmingPart() );
			
			p.x = Math.random() * 2.0 - 1.0;
			p.y = Math.random() * 2.0 - 1.0;
			p.z = Math.random() * 2.0 - 1.0;
			
			p.tile = tile;
			p.life = 1024 * 1024 * 1024;
			p.color = 0xff0800ff;
			
			var s = bm.Dice.rollF( 0.05, 0.1);
			p.setSize(s,s);
			parts.push( p );
		}
		
		
		
		trackingPoint = mt.heaps.Api3D.point(trackingPos, 0xffff0000);
		thirdPartyPoint = mt.heaps.Api3D.point(thirdPartyPos, 0xffff0000);
		k = new bm.Keys();
		hxd.System.setLoop(update);
		k.init();
		
		/**
		 * public static var TRACKING_FACTOR = 0.05;
	public static var COHESION_FACTOR = 0.2;
	public static var ALIGNMENT_FACTOR = 0.2;
	public static var SEPARATION_FACTOR = 0.5;
		 */
		var font = openfl.Assets.getFont("assets/Penelope Anne.ttf" );
		var fnt = hxd.res.FontBuilder.getFont( font.fontName, 16 );
		
		var flow = new h2d.Flow(scene);
		flow.isVertical = true;
		
		var v = new h2d.ValueBarRange( "Tracking", fnt,[-1,1],SwarmingPart.TRACKING_FACTOR,120, flow );
		v.onValueChanged = function(f) SwarmingPart.TRACKING_FACTOR = f;
		
		var v = new h2d.ValueBar( "Cohesion", fnt,  flow );
		v.setValueF( SwarmingPart.COHESION_FACTOR );
		v.onValueChanged = function(f) SwarmingPart.COHESION_FACTOR = f;
		
		var v = new h2d.ValueBar( "Separation", fnt,  flow );
		v.setValueF( SwarmingPart.SEPARATION_FACTOR );
		v.onValueChanged = function(f) SwarmingPart.SEPARATION_FACTOR = f;
		
		var v = new h2d.ValueBar( "Alignment", fnt,  flow );
		v.setValueF( SwarmingPart.ALIGNMENT_FACTOR );
		v.onValueChanged = function(f) SwarmingPart.ALIGNMENT_FACTOR = f;
		
		var v = new h2d.ValueBarRange( "IsClose", fnt, [0,2], SwarmingPart.IS_CLOSE, 120, flow );
		v.onValueChanged = function(f) SwarmingPart.IS_CLOSE = f;
	}
	
	function update() 	{
		k.update();
		scene.checkEvents();
		hxd.Timer.update();
		
		var tm = hxd.Timer.tmod;
		
		if ( k.isDown( bm.Keys.UP )) 			{ 	trackingPos.z += 0.05 * tm; trace(trackingPos); }
		if ( k.isDown( bm.Keys.DOWN )) 			{ 	trackingPos.z -= 0.05 * tm; trace(trackingPos); }
		if ( k.isDown( bm.Keys.LEFT )) 			{ 	trackingPos.x -= 0.05 * tm; trace(trackingPos); }
		if ( k.isDown( bm.Keys.RIGHT ))			{  	trackingPos.x += 0.05 * tm; trace(trackingPos); }
		if ( k.isDown( bm.Keys.NUMPAD_ADD )) 	{ 	trackingPos.y += 0.05 * tm; trace(trackingPos); }
		if ( k.isDown( bm.Keys.NUMPAD_SUB )) 	{	trackingPos.y -= 0.05 * tm; trace(trackingPos); }
		
		trackingPoint.pos.load(trackingPos);
		thirdPartyPoint.pos.load(thirdPartyPos);
		
		for ( p in parts ) 
			p.updateSwarm(hxd.Timer.tmod);
		partMan.update(hxd.Timer.tmod);
		
		engine.render(scene3d);
		engine.restoreOpenfl();
		
		k.update();
		SwarmingPart.staticUpdate();
	}
	
	static function main() {
		new Demo();
	}
}
