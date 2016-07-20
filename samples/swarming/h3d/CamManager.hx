package h3d;

import Types;
import mt.gx.Dice;

using mt.gx.Ex;

class CameraBase extends h3d.Camera {
	var ring(get, never): Ring; inline function get_ring() return Ring.me;
	public var pause    : Bool;
	
	public function new() {
		super();
		loadFrom( ring.root.camera );
	}
	
	public function dispose() {
		
	}
	
	public function updateTmod(tm:Float) {
		update();
	}
	
	public function loadFrom(base:h3d.Camera) {
		pos = base.pos.clone();
		target = base.target.clone();
		zNear = base.zNear;
		zFar = base.zFar;
		fovY = base.fovY;
		screenRatio = base.screenRatio;
	}
	
	public function onActivate(old:h3d.Camera) { }
}

class FixedCam extends CameraBase {
	
	var ratio = 0.5;
	public function new(pos:h3d.Vector, hiFov ) {
		super();
		this.pos.load(pos);
		if ( hiFov ) 
			fovY *= 1.5;
	}
	
	override public function updateTmod(tm:Float) 
	{
		var pa = ring.wrestlers[0].getGfxPos();
		var pb = ring.wrestlers[1].getGfxPos();
		var dp = pb.sub(pa);
		var dd = dp.length();
		
		var newTarget = new h3d.Vector();
		dp.scale3(0.5);
		newTarget.load(pa);
		newTarget.incr(dp);
		newTarget.z += 1;
		
		if ( Ui.me.curBoost != null) 
			newTarget.z -= 0.33;
		
		target.lerp(target, newTarget, 0.1);
		
		super.updateTmod(tm);
	}
	
	override public function onActivate(old)
	{
		super.onActivate(old);
		ratio = [0.0, 1.0].random(Tools.getActionRand());
	}
}

class TrackingCam extends CameraBase {
	
	public function new() {
		super();
	}
	
	public override function updateTmod(tm:Float) {
		if ( !pause ) {
			var offPos = ring.off.getGfxPos();
			var defPos = ring.def.getGfxPos();
			var dpos   = offPos.distance( defPos );
			
			var midPos = offPos.clone();
			midPos.incr( defPos );
			midPos.scale3(0.5);
			
			//todo find a way to tmod this
			var objPos : h3d.Vector = midPos;
			
			var targetPos = objPos.clone();
			targetPos.z *= 0.1;
			targetPos.z += 1.0;
			if ( ring.uiRoot.curBoost != null ) {
				targetPos.z -= 0.2;
			}
			
			targetPos.lerp( target, targetPos, 0.3 );
			target.load( targetPos );
			
			if ( pos.distance( objPos ) > 9.0 ) {
				var d = objPos.sub( pos );
				d.normalize();
				d.scale3( tm * 0.1 );
				pos.incr( d );
			}
			
			if ( pos.distance( objPos ) < 6.0 ) {
				var d = pos.sub( objPos );
				d.normalize();
				d.scale3( tm * 0.1 );
				pos.incr( d );
			}
		}
		super.updateTmod(tm);
	}
	
	override public function onActivate(old) {
		if ( old == null )
			old = ring.root.camera.clone();
		loadFrom(old);
	}
}

class SideFullCam extends SideCam {
	var paFactor = 0.5;
	
	
	public function new(angle,fa) {
		super(angle);
		paFactor = fa;
	}
	
	override function getTarget() {
		var dp = pb.sub(pa);
		var newTarget = new h3d.Vector();
		// target the point between the vikings
		dp.scale3(paFactor);
		newTarget.load(pa);
		newTarget.incr(dp);
		newTarget.z += 1;
		return newTarget;
	}
}

class SideCam extends CameraBase {
	public var frontHeight = 1.0;
	public var backHeight  = 1.6;
	public var minDist     = 8.0;
	public var maxDist     = 11.0;
	public var angle       = Math.PI / 4;
	
	public var skipLerp = false;
	
	var pa : h3d.Vector;
	var pb : h3d.Vector;
	
	public var isHigh = false;
		
	public function new(angle:Float) {
		this.angle = angle;
		super();
	}
	
	function getTarget() {
		var dp = pb.sub(pa);
		var newTarget = new h3d.Vector();
		// target the point between the vikings
		dp.scale3(0.5);
		newTarget.load(pa);
		newTarget.incr(dp);
		newTarget.z += 1;
		return newTarget;
	}
	
	override function updateTmod(tm:Float) {
		var swapping = ring.off.fl.has( Rotating) || ring.def.fl.has( Rotating);
		if ( swapping ) {
			skipLerp = true;
			return;
		}
		
		if ( pause )
			return;
		
		if (swapping) {
			pa = ring.wrestlers[0].getBipPos();
			pb = ring.wrestlers[1].getBipPos();
		} else {
			pa = ring.wrestlers[0].getGfxPos();
			pb = ring.wrestlers[1].getGfxPos();
			pa.add(ring.wrestlers[0].getBipPos(), pa).scale3(0.5);
			pb.add(ring.wrestlers[1].getBipPos(), pb).scale3(0.5);
		}
		pa.z = pb.z = 0;
		
		var dp = pb.sub(pa);
		var dd = dp.length();
		
		var newPos    = new h3d.Vector();
		var newTarget = getTarget();
		
		if ( Ui.me.curBoost != null) {
			newTarget.z -= 0.33;
		}
		
		{	// get the perpendicular vector 
			dp = dp.cross(up);
			dp.normalize();
		}
		
		{	// slighly rotate it in the focused viking back
			var p  = new h2d.col.Point(dp.x, dp.y);
			p.rotate(angle);
			dp.x = p.x;
			dp.y = p.y;
		}
		
		{	// place the camera on the perpendicular vector
			newPos.load(target);
			dp.scale3(minDist + (maxDist - minDist) * dd /maxDist);
			newPos.incr(dp);
		}
		
		{	// set the camera height regarding its position around the ring
			newPos.z = 1;
			var a = Math.acos(new h3d.Vector(0, 1, 0).dot3(newPos.getNormalized()));
			var qa = Math.abs(a) / Math.PI;
			var qd = newPos.length() / maxDist;
			qa *= qd > 1 ? 1 : qd;
			qa--;
			newPos.z = -backHeight * (qa * qa * qa * qa - 1) + frontHeight;
			
			if ( isHigh ) 
				newPos.z += 1;
		}
		
		if (!skipLerp) {
			var damping = swapping ? 0.5 : 0.05;
			pos.lerp(pos, newPos, damping);
			target.lerp(target, newTarget, damping);
		} else {
			pos.load(newPos);
			target.load(newTarget);
			skipLerp = false;
		}

		
		//#if false
		//trace('pos:$pos');
		//trace('pa:$pa');
		//trace('pbs:$pb');
		//trace('target:$target');
		//trace('skipLerp:$skipLerp');
		//trace('fovY:$fovY');
		//#end
		
		super.updateTmod(tm);
	}
	
	override public function onActivate(old:h3d.Camera){
		super.onActivate(old);
		skipLerp = true;
	}
}

class CircleCam extends CameraBase {
	inline static var startAngle = 3.14/2;
	inline static var dist  = 6.0;
	inline static var speed = 6.26 / 2; // rads per sec
	inline static var dz    = 2;
	
	public var loop = false;
	
	var angle  : Float;
	var entity : ent.Entity;

	public function new(e:ent.Entity) {
		super();
		entity = e;
	}
	
	override public function updateTmod(tm:Float) 
	{
		if (!loop && angle - startAngle > 6.28) {
			target.load(entity.getGfxPos());
			return;
		}
		
		angle += speed * tm / ComConst.FPS;
		
		var dp = new h3d.Vector(Math.cos(angle), Math.sin(angle), 0);
		dp.scale3(dist);

		var org = entity.getGfxPos();
		pos.load(org);
		pos.add(dp, pos);
		pos.z += 1;
		
		target.load(org);
		target.z += 1;
		super.updateTmod(tm);
		
		pos.z += dz * (Math.cos(angle + entity.perso.obj.getRotation().z) + 1) / 2;
		if ( pos.z <= 0.1) 
			pos.z = 0.1;
	}
	
	override public function onActivate(old) {
		angle = startAngle;
	}
}

class EmbeddedCam extends CameraBase {
	var entity : ent.Entity;
	var lnkPos : mt.heaps.bhv.Link;
	var lnkUp  : mt.heaps.bhv.Link;
	var offset : h3d.Vector;
	var bone   : String;
	
	public function new(e:ent.Entity, bone:String, offset:h3d.Vector) {
		super();
		if ( bone == null) throw "achert";
		
		entity = e;
		var srcObj	= entity.perso.obj;
		var posObj	= new h3d.scene.Object();
		var upObj	= new h3d.scene.Object();
		this.bone	= bone;
		
		offset.scale3( 1.5);
		//offset.z += 3; // .X? wtf?
		lnkPos		= new mt.heaps.bhv.Link(posObj, srcObj, bone, offset); 
		
		offset.x += 1; // .X? wtf?
		lnkUp		= new mt.heaps.bhv.Link(upObj,  srcObj, bone, offset);
		
		if ( lnkPos.obj == null) throw "achert";
		
		ring.root.addChild ( posObj );
		ring.root.addChild ( upObj  );
		
		fovY *= 1.15;
	}
	
	override public function updateTmod(tm:Float) 
	{
		var newPos = new h3d.Vector();
		var newUp  = new h3d.Vector();
		
		if ( lnkPos.obj == null ) return;
		if ( lnkUp.obj == null ) return;
		
		newPos.transform(lnkPos.obj.defaultTransform);
		newUp.transform (lnkUp.obj.defaultTransform);
		newUp.sub(newPos, newUp);
		newUp.normalize();
		//newUp.scale3( 3.0 );
		
		var damping = 0.08;
		if (newPos.z <= 0.1) newPos.z = 0.1;
		
		pos.lerp(pos, newPos, damping);
		up.lerp (up,  newUp,  damping);
		target.lerp(target, entity.getBonePos( bone ), damping);
		
		super.updateTmod(tm);
	}
}

class AnimCam extends CameraBase {
	var track	: CamTrack;
	var loop	: Bool;
	var offset  : ent.Entity;
	var speed   : Float;
	
	var framePosA : h3d.Vector;
	var framePosB : h3d.Vector;
	var framePosV : h3d.Vector;
	
	var frameTgtA : h3d.Vector;
	var frameTgtB : h3d.Vector;
	var frameTgtV : h3d.Vector;
	
	var time : Float;
	var flushTime : Float;
	var frameIndex : Int;
	
	var fps(get, null):Float; inline function get_fps() return flash.Lib.current.stage.frameRate;
	
	public function new() {
		super();
		framePosA = new h3d.Vector();
		framePosB = new h3d.Vector();
		framePosV = new h3d.Vector();
		
		frameTgtA = new h3d.Vector();
		frameTgtB = new h3d.Vector();
		frameTgtV = new h3d.Vector();
	}
	
	public function play(trackName:String , ?offset:ent.Entity, speed = 1.0, loop = false) {
		track = Rsc.camTracks.get(trackName);
		if ( track == null ) throw "track assertion";
		this.offset	= offset;
		this.loop	= loop;
		this.speed	= speed;
		flushTime = (track.fps / fps) / fps;
		time = 0.0;
		frameIndex = 1;
		
		loadPosFrame(0, framePosA);
		loadTgtFrame(0, frameTgtA);
		loadPosFrame(1, framePosB);
		loadTgtFrame(1, frameTgtB);
	}
	
	inline function loadPosFrame(i:Int, out:h3d.Vector) {
		out.x = track.pos.data[i * 3];
		out.y = track.pos.data[i * 3 + 1];
		out.z = track.pos.data[i * 3 + 2];
	}
	
	inline function loadTgtFrame(i:Int, out:h3d.Vector) {
		track.target.data[i].pos(out);
	}
	
	override public function updateTmod(tm:Float) 
	{
		if ( track == null ) return;
		if (frameIndex >= track.pos.keys.length - 1) return;
		
		time += Ring.me.tmod / fps * speed;
		while (time >= flushTime) {
			if (frameIndex >= track.pos.keys.length - 1) return;
			
			++frameIndex;
			framePosA.load(framePosB);
			loadPosFrame(frameIndex, framePosB);
			
			frameTgtA.load(frameTgtB);
			loadTgtFrame(frameIndex, frameTgtB);
			
			time -= flushTime;
		}
		
		framePosV.lerp(framePosA, framePosB, time / flushTime);
		frameTgtV.lerp(frameTgtA, frameTgtB, time / flushTime);
			
		if (offset == null) {
			pos.load(framePosV);
			target.load(frameTgtV);
		} else {
			var offPos = offset.getGfxPos(); offPos.z = 0;
			var p = new h2d.col.Point(framePosV.x, framePosV.y);
			p.rotate(offset.perso.obj.getRotation().z);
			framePosV.set(p.x, p.y, framePosV.z);
			framePosV.add(offPos, pos);
			frameTgtV.add(offPos, target);
		}
		
		super.updateTmod(tm);
	}
}

class KeyboardCamera extends CameraBase {
	
	var globalMoveSpeed = 1.0;
	var noZ = true;
	
	public function new () {
		super();
		
		zNear	= 0.1;
		zFar	= 800;
		
		pos.x = 0;
		pos.y = 5;
		pos.z = 0;
		
		target.x = 0;
		target.y = 0;
		target.z = 0;
		
		up.x = 0;
		up.y = 0;
		up.z = 1;
	}
	
	public override function updateTmod(tm:Float) {
		
		var vec = pos.clone();
		
		var dirX = right(); dirX.scale3(0.1*globalMoveSpeed);
		var dirY = target.sub(pos); dirY.scale3(0.15 * globalMoveSpeed);
		var dirZ = up.clone(); dirZ.scale3(0.1 * globalMoveSpeed);
		
		if ( noZ ) {
			dirX.z = 0;
			dirX.normalize();
			
			dirY.z = 0;
			dirY.normalize();
		}
		
		if ( hxd.Key.isDown(hxd.Key.LEFT)||	 hxd.Key.isDown(hxd.Key.Q))
			pos.incr(dirX);
		if ( hxd.Key.isDown(hxd.Key.RIGHT) || hxd.Key.isDown(hxd.Key.D))
			pos.decr(dirX);
		
		if ( hxd.Key.isDown(hxd.Key.UP) || hxd.Key.isDown(hxd.Key.Z)) 
			pos.incr(dirY);
		if ( hxd.Key.isDown(hxd.Key.DOWN) || hxd.Key.isDown(hxd.Key.S))	
			pos.decr(dirY);
			
		if (  hxd.Key.isDown(hxd.Key.SPACE) || hxd.Key.isDown(hxd.Key.NUMPAD_ADD) ) 
			pos.incr(dirZ);
		if ( hxd.Key.isDown(hxd.Key.SHIFT) || hxd.Key.isDown(hxd.Key.NUMPAD_SUB))	
			pos.decr(dirZ);
			
		var diff = pos.sub( vec );
		target = target.add( diff );
		var dir = target.sub( pos );
		target = pos.add( dir.getNormalized() );
		
		super.updateTmod(tm);
	}
}

class FreemoveCamera extends KeyboardCamera {
	public inline function getStage() return flash.Lib.current.stage;
	public var isClicked = false;
	public var oldMouseX 	= 0.0;
	public var oldMouseY	= 0.0;
	
	function onMouseUp(_) 	isClicked = false;
	function onMouseDown(_) isClicked = true;
	
	public var verticalFPSSensibility = 3.0;
	public var horizontalFPSSensibility = 1.0;
	
	public function new () {
		super();
		noZ = false;
		var stage = getStage();
		stage.addEventListener( flash.events.MouseEvent.MOUSE_DOWN,onMouseDown );
		stage.addEventListener( flash.events.MouseEvent.MOUSE_UP, onMouseUp );
		stage.addEventListener( flash.events.MouseEvent.MOUSE_WHEEL, onMouseWheel );
	}
	
	public override function dispose() {
		super.dispose();
		
		var stage = getStage();
		stage.removeEventListener( flash.events.MouseEvent.MOUSE_DOWN,onMouseDown );
		stage.removeEventListener( flash.events.MouseEvent.MOUSE_UP, onMouseUp );
		stage.removeEventListener( flash.events.MouseEvent.MOUSE_WHEEL, onMouseWheel );
	}
	
	function onMouseWheel(e) {
		globalMoveSpeed += 0.125 * (e.delta / 10.0);
	}
	
	public override function updateTmod(tm:Float) {
		super.updateTmod(tm);
		
		if ( isClicked ) {
			var kx = 0.01;
			var stage = getStage();
			var dmx = stage.mouseX - oldMouseX;
			var dmy = stage.mouseY - oldMouseY;
			
			var sdmx = dmx / mt.Metrics.w() * 0.5;
			var sdmy = dmy / mt.Metrics.h() * 0.5;
			
			var camDir = target.sub( pos ).getNormalized();
			var k = 2.0;
			
			sdmx *= k;
			sdmx *= k;
			
			sdmx *= horizontalFPSSensibility;
			sdmy *= verticalFPSSensibility * ( mt.Metrics.w() / mt.Metrics.h() );
			var p = unproject(sdmx,-sdmy, 0.0).sub(pos);
			
			camDir.x = p.x;
			camDir.y = p.y;
			camDir.z = p.z;
			
			target.load( pos.add( camDir ) );
		}
		
		oldMouseX = getStage().mouseX;
		oldMouseY = getStage().mouseY;
		
		
	}
}

class VikingCamera extends KeyboardCamera {
	
	public function new() {
		super();
		
		zNear	= 0.1;
		zFar	= 800;
		
		pos.x 	= 0;
		pos.y 	= 2;
		pos.z 	= 1.5;
		
		fovY = 0.5 * 54.4;
		zoom = 0.6;
		
		pos.set(2,3.4,1.1);
		target.set(0, 0, 0.8);
		
		var rot = new h3d.Matrix();
		rot.initRotateAxis( new h3d.Vector(0,0,1), 0.6108);
		pos.transform( rot );
		
		tgtDiff = target.sub( pos );
		
		trace(this);
	}
	
	public var tgtDiff = new h3d.Vector();
	
	public override function updateTmod(tm:Float) {
		super.updateTmod(tm);
		
		var tgt = pos.clone();
		tgt.incr( tgtDiff );
		target.load(tgt);
		
		if ( hxd.Key.isDown(hxd.Key.PGUP) ){
			tgtDiff.rotateQuat( h3d.Quat.fromAxis(0, 0, 1, 0.1) );
		}
			
		if ( hxd.Key.isDown(hxd.Key.PGDOWN)  ){
			tgtDiff.rotateQuat( h3d.Quat.fromAxis(0, 0, 1, -0.1) );
		}
		
	}
	
}

class CamManager {
	var active : Null<CameraBase>;
	public var activeKey(default,null) : CamType;
	var p1 : ent.Entity;
	var p2 : ent.Entity;
	var clampBox : h3d.Vector;
	
	public var forceCamera : CamType = null;
	public var all : Map<CamType,CameraBase>;
	
	var ring(get, never): Ring; inline function get_ring() return Ring.me;
	
	public function new() {
		p1 = ring.wrestlers[0];
		p2 = ring.wrestlers[1];
		
		clampBox = new h3d.Vector(7, 7, 5);
		clampBox.scale3(0.5);
		
		//var cs = new h3d.Vector(7, 7, 5);
		//var clampBoxTest = ring.newBox(0xFF000000, cs);
		//cs.scale3(-0.5);
		//clampBoxTest.setPos(cs.x, cs.y, cs.z);
		//ring.root.addChild(clampBoxTest);
		
		all = new Map();
		all.set(StandardTracking, new TrackingCam());
		
		all.set(Side1,		new SideCam(-Math.PI / 4));
		all.set(Side2,		new SideCam(Math.PI / 4));
		
		all.set(SideFull1,	new SideFullCam(-Math.PI / 4, 0.0));
		all.set(SideFull2,	new SideFullCam(Math.PI / 4, 1.0));
		
		
		var c = null;
		all.set(SideFullLoose1,	c = new SideFullCam( -Math.PI / 6, 0.0));
		
		c.minDist *= 1.33;
		c.maxDist *= 1.33;
		
		all.set(SideFullLoose2,	c = new SideFullCam(Math.PI / 6, 1.0));
		
		c.minDist *= 1.33;
		c.maxDist *= 1.33;
		
		all.set(SideFullCoarse1,	new SideFullCam(-Math.PI / 3, 0.0));
		all.set(SideFullCoarse2,	new SideFullCam(Math.PI / 3, 1.0));
		
		all.set(SideFullClose1,	c = new SideFullCam( -Math.PI / 3, 0.0));
		//c.isHigh = true;
		all.set(SideFullClose2,	c = new SideFullCam(Math.PI / 3, 1.0));
		//c.isHigh = true;
		
		all.set(Head1,		new EmbeddedCam(p1, Cst.BONE_HEAD, new h3d.Vector(1, 3, -2)));
		all.set(Head2,		new EmbeddedCam(p2, Cst.BONE_HEAD, new h3d.Vector(1, 3, 2)));
		all.set(Animated,	new AnimCam());
		
		all.set(FixedFront,	new FixedCam(new h3d.Vector(  0,  7,  2),false));
		all.set(FixedBack,	new FixedCam(new h3d.Vector(  0, -7,  2),false));
		all.set(FixedRight,	new FixedCam(new h3d.Vector( -7,  0,  2),false));
		all.set(FixedLeft,	new FixedCam(new h3d.Vector(  7,  0,  2),false));
		
		all.set(FixedFrontGround,	new FixedCam(new h3d.Vector(   0,  3.5, 0.1), true));
		all.set(FixedBackGround,	new FixedCam(new h3d.Vector(   0, -3.5, 0.1), true));
		all.set(FixedRightGround,	new FixedCam(new h3d.Vector(-3.5,    0, 0.1), true));
		all.set(FixedLeftGround,	new FixedCam(new h3d.Vector( 3.5,	 0, 0.1), true));
		
		all.set(Circle1,	new CircleCam(p1));
		all.set(Circle2,	new CircleCam(p2));
		
		all.set(InputKeyboard,		new KeyboardCamera());
		all.set(InputKeyboardMouse,	new FreemoveCamera());
		all.set(InputViking,		new VikingCamera());
	}
	
	public function dispose() {
		for (a in all)
			a.dispose();
		all = null;
		
		active = null;
	}
	
	public inline function getActive() return active;
	
	public function getTracking(cp) {
		return Std.instance(all.get(cp), TrackingCam);
	}
	
	public function activate(cp) : CameraBase {
		if ( forceCamera != null )
			cp = forceCamera;
			
		if (activeKey == cp)
			return active;
			
		activeKey = cp;
		var old = active;
		active = all.get( cp );
		active.onActivate(old);
		return active;
	}
	
	public function playAnim(track:String, offset:ent.Entity = null, speed = 1.0) {
		activate(Animated);
		var a = Std.instance(active, AnimCam);
		if( a!=null)
			a.play(track, offset, speed);
	}

	public function update(tmod:Float) {
		if ( active == null ) 
			return;
			
		var off = ring.off;
		var def = ring.def;
		ring.root.camera = active;
		
		for (c in all)
			c.updateTmod(tmod);
		
		if (active.pos.z <= clampBox.z) {
			// some cam may be into the ring barriers
			
			var doClamp = false;
			switch( activeKey ){
				default:
				case Head1 | Head2:doClamp = true;
				
				case SideFullLoose1|SideFullLoose2:
				case Side1|Side2|SideFull1|SideFull2|SideFullCoarse1|SideFullCoarse2: 
					
					var b = off.hasDefBoost()?off.getDefBoost():null;
					if( b== null) b = def.hasDefBoost()?def.getDefBoost():null;
					if( b!=null && (b.elem == Fire || b.elem == Ice || b.elem == Nature)){
						doClamp = true;
					}
					
				case SideFullClose1, SideFullClose2:
					var b = off.hasDefBoost()?off.getDefBoost():null;
					if ( b == null) b = def.hasDefBoost()?def.getDefBoost():null;
					if ( b != null) {
						var c = Std.instance( active, SideFullCam);
						if ( c != null) {
							c.isHigh = true;
						}
					}
			}
			
			if (doClamp) {
				// put the cam inside the ring
				var x = Math.abs(active.pos.x);
				var y = Math.abs(active.pos.y);
				if (x > clampBox.x)
					active.pos.x = active.pos.x > 0 ? clampBox.x : -clampBox.x;
				if (y > clampBox.y)
					active.pos.y = active.pos.y > 0 ? clampBox.y : -clampBox.y;
			}
		}
	}
	
	var numBlank = 0;
	var justSwitched = true;
	
	inline function onSwitch() {
		numBlank = 0;
		justSwitched = true;
	}
		
	public function onStartAction(e:Protocol.DefCombat) {
		if (justSwitched) {
			justSwitched = false;
			return;
		}
		
		/*
		if (e.cost_rage > 0 || e.coup == HIT_WITH) {
			var p = 50;
			if ( ring.realGetTension() >= 1 )
				p += 20;
			if ( ring.realGetTension() >= 2 )
				p += 20;
				
			if( Dice.percent( p ))
				activate(e.def == p1.stats ? [SideFull1, SideFullCoarse1].random() : [SideFull2, SideFullCoarse2].random() );
			else {
				if ( Dice.percent(50)) {
					activate(getFarFixedCam()); 
				}
			}
			numBlank = 0;
			justSwitched = true;
		} else if (mt.gx.Dice.roll(0, ++numBlank) > 0) {
			activate(getFixedCam());
			numBlank = 0;
			justSwitched = true;
		}
		*/
		
		//onSwitch();
	}
	
	public function onHitImpact(ac : Actions) {
		//onSwitch();
		/*
		var base = Protocol.tech.get(ac.tech).base.id;
		if (base == PUNCH && ac.tech != HAMMER) {
		
			var p = 0;
			if ( ring.realGetTension() >= 1.0)
				p += 30;
				
			if( Dice.percent( p ) )
				activate(ring.def == p1 ? Head1 : Head2);
		}
		*/
	}
	
	public function onBlockImpact(ac : Actions) 
	{
	}
	
	public function getFarFixedCam() 
	{
		var pa = ring.wrestlers[0].getGfxPos();
		var pb = ring.wrestlers[1].getGfxPos();
		var dp = pa.sub(pb);
		dp.normalize();
		
		var a = Math.atan2(dp.y, dp.x) + Math.PI*2 - Math.PI/4;
		a = hxd.Math.fumod(a, Math.PI * 2);
		
		if (a < Math.PI / 2)
			return FixedRight ;
		else if (a < Math.PI)
			return FixedBack ;
		else if (a < Math.PI + Math.PI / 2)
			return  FixedLeft ;
		return FixedFront ;
	}
	
	public function getFixedCam() 
	{
		var pa = ring.wrestlers[0].getGfxPos();
		var pb = ring.wrestlers[1].getGfxPos();
		var dp = pa.sub(pb);
		dp.normalize();
		
		var a = Math.atan2(dp.y, dp.x) + Math.PI*2 - Math.PI/4;
		a = hxd.Math.fumod(a, Math.PI * 2);
		
		if (a < Math.PI / 2)
			return mt.gx.Dice.roll(0, 1) > 0 ? FixedRight : FixedRightGround;
		else if (a < Math.PI)
			return mt.gx.Dice.roll(0, 1) > 0 ? FixedBack : FixedBackGround;
		else if (a < Math.PI + Math.PI / 2)
			return mt.gx.Dice.roll(0, 1) > 0 ? FixedLeft : FixedLeftGround;
			
		return mt.gx.Dice.roll(0, 1) > 0 ? FixedFront : FixedFrontGround;
	}
	
	inline function isFixedCam() {
		return activeKey == FixedBack
			|| activeKey == FixedFront
			|| activeKey == FixedLeft
			|| activeKey == FixedRight
			|| activeKey == FixedBackGround
			|| activeKey == FixedFrontGround
			|| activeKey == FixedLeftGround
			|| activeKey == FixedRightGround
			;
	}
	
	public function changeCam() {
		if (justSwitched) {
			justSwitched = false;
			return;
		}
		onSwitch();
	}
}