package h2d;
import h3d.Vector;
import hxd.Math;

/**
 * In order to inject this in a 3d context, use h3d.scene.addPass and alikes
 */
class Scene extends Layers implements h3d.IDrawable {

	var fixedSize : Bool;
	var interactive : Array<Interactive>;
	var pendingEvents : Array<hxd.Event>;
	var ctx : RenderContext;
	
	@:allow(h2d.Interactive)
	var currentOver : Interactive;
	@:allow(h2d.Interactive)
	var currentFocus : Interactive;
		
	var pushList : Array<Interactive>;
	var currentDrag : { f : hxd.Event -> Void, onCancel : Void -> Void, ref : Null<Int> };
	var eventListeners : Array< hxd.Event -> Void >;
	
	var prePasses : Array<h3d.IDrawable>;
	var extraPasses : Array<h3d.IDrawable>;
	
	public function new() {
		super(null);
		var e = h3d.Engine.getCurrent();
		ctx = new RenderContext();
		width = e.width;
		height = e.height;
		interactive = new Array();
		pushList = new Array();
		eventListeners = new Array();
		
		extraPasses = [];
		prePasses = [];
		
		posChanged = true;
	}
	
	public function setFixedSize( w, h ) {
		width = w;
		height = h;
		fixedSize = true;
		posChanged = true;
	}

	override function onAlloc() {
		stage.addEventTarget(onEvent);
		super.onAlloc();
	}
	
	override function onDelete() {
		stage.removeEventTarget(onEvent);
		super.onDelete();
	}
	
	function onEvent( e : hxd.Event ) {
		if( pendingEvents != null ) {
			e.relX = screenXToLocal(e.relX);
			e.relY = screenYToLocal(e.relY);
			pendingEvents.push(e);
		}
	}
	
	function screenXToLocal(mx:Float) {
		return (mx - x) * width / (stage.width * scaleX);
	}

	function screenYToLocal(my:Float) {
		return (my - y) * height / (stage.height * scaleY);
	}
	
	override function get_mouseX() {
		return screenXToLocal(stage.mouseX);
	}

	override function get_mouseY() {
		return screenYToLocal(stage.mouseY);
	}
	
	public override function set_width(w) 	return this.width=w;
	public override function set_height(h) 	return this.height=h;
	public override function get_width() 	return width;
	public override function get_height() 	return height;
	
	function dispatchListeners( event : hxd.Event ) {
		event.propagate = true;
		event.cancel = false;
		for( l in eventListeners ) {
			l(event);
			if( !event.propagate ) break;
		}
	}

	function emitEvent( event : hxd.Event ) {
		var x = event.relX, y = event.relY;
		var rx = x * matA + y * matB + absX;
		var ry = x * matC + y * matD + absY;
		var r = height / width;
		var handled = false;
		var checkOver = false, checkPush = false, cancelFocus = false;
		switch( event.kind ) {
		case EMove: checkOver = true;
		case EPush: cancelFocus = true; checkPush = true;
		case ERelease: checkPush = true;
		case EKeyUp, EKeyDown, EWheel:
			if( currentFocus != null )
				currentFocus.handleEvent(event);
			else {
				if( currentOver != null ) {
					event.propagate = true;
					currentOver.handleEvent(event);
					if( !event.propagate ) return;
				}
				dispatchListeners(event);
			}
			return;
		default:
		}
		for( i in interactive ) {
			

			// TODO : we are not sure that the positions are correctly updated !
			
			// this is a bit tricky since we are not in the not-euclide viewport space
			// (r = ratio correction)
			var dx = rx - i.absX;
			var dy = ry - i.absY;
			
			var w1 = i.width * i.matA * r;
			var h1 = i.width * i.matC;
			var ky = h1 * dx - w1 * dy;
			// up line
			if( ky < 0 )
				continue;
				
			var w2 = i.height * i.matB * r;
			var h2 = i.height * i.matD;
			var kx = w2 * dy - h2 * dx;
				
			// left line
			if( kx < 0 )
				continue;
			
			var max = h1 * w2 - w1 * h2;
			// bottom/right
			if( ky >= max || kx * r >= max )
				continue;

			// check visibility
			var visible = true;
			var p : Sprite = i;
			while( p != null ) {
				if( !p.visible ) {
					visible = false;
					break;
				}
				p = p.parent;
			}
			if( !visible ) continue;
			
			event.relX = (kx * r / max) * i.width;
			event.relY = (ky / max) * i.height;
			
			i.handleEvent(event);
			
			if( event.cancel )
				event.cancel = false;
			else if( checkOver ) {
				if( currentOver != i ) {
					var old = event.propagate;
					if( currentOver != null ) {
						event.kind = EOut;
						// relX/relY is not correct here
						currentOver.handleEvent(event);
					}
					event.kind = EOver;
					event.cancel = false;
					i.handleEvent(event);
					if( event.cancel )
						currentOver = null;
					else {
						currentOver = i;
						checkOver = false;
					}
					event.kind = EMove;
					event.cancel = false;
					event.propagate = old;
				} else
					checkOver = false;
			} else {
				if( checkPush ) {
					if( event.kind == EPush )
						pushList.push(i);
					else
						pushList.remove(i);
				}
				if( cancelFocus && i == currentFocus )
					cancelFocus = false;
			}
				
			if( event.propagate ) {
				event.propagate = false;
				continue;
			}
			
			handled = true;
			break;
		}
		if( cancelFocus && currentFocus != null ) {
			event.kind = EFocusLost;
			currentFocus.handleEvent(event);
			event.kind = EPush;
		}
		if( checkOver && currentOver != null ) {
			event.kind = EOut;
			currentOver.handleEvent(event);
			event.kind = EMove;
			currentOver = null;
		}
		if( !handled ) {
			if( event.kind == EPush )
				pushList.push(null);
			dispatchListeners(event);
		}
	}
	
	function hasEvents() {
		return interactive.length > 0 || eventListeners.length > 0;
	}
	
	public function checkEvents() {
		if( pendingEvents == null ) {
			if( !hasEvents() )
				return;
			pendingEvents = new Array();
		}
		var old = pendingEvents;
		if( old.length == 0 )
			return;
		pendingEvents = null;
		var ox = 0., oy = 0.;
		for( e in old ) {
			var hasPos = switch( e.kind ) {
			case EKeyUp, EKeyDown: false;
			default: true;
			}
			
			if( hasPos ) {
				ox = e.relX;
				oy = e.relY;
			}
			
			if( currentDrag != null && (currentDrag.ref == null || currentDrag.ref == e.touchId) ) {
				currentDrag.f(e);
				if( e.cancel )
					continue;
			}
			emitEvent(e);
			if ( e.kind == ERelease && pushList.length > 0 ) {
				for( i in pushList ) {
					// relX/relY is not correct here
					if( i != null )
						i.handleEvent(e);
				}
				pushList = new Array();
			}
		}
		if( hasEvents() )
			pendingEvents = new Array();
	}
	
	public function addEventListener( f : hxd.Event -> Void ) {
		eventListeners.push(f);
	}

	public function removeEventListener( f : hxd.Event -> Void ) {
		return eventListeners.remove(f);
	}
	
	public function startDrag( f : hxd.Event -> Void, ?onCancel : Void -> Void, ?refEvent : hxd.Event ) {
		if( currentDrag != null && currentDrag.onCancel != null )
			currentDrag.onCancel();
		currentDrag = { f : f, ref : refEvent == null ? null : refEvent.touchId, onCancel : onCancel };
	}
	
	public function stopDrag() {
		currentDrag = null;
	}
	
	public function getFocus() {
		return currentFocus;
	}
	
	@:allow(h2d)
	function addEventTarget(i:Interactive) {
		// sort by which is over the other in the scene hierarchy
		inline function getLevel(i:Sprite) {
			var lv = 0;
			while( i != null ) {
				i = i.parent;
				lv++;
			}
			return lv;
		}
		inline function indexOf(p:Sprite, i:Sprite) {
			var id = -1;
			for( k in 0...p.childs.length )
				if( p.childs[k] == i ) {
					id = k;
					break;
				}
			return id;
		}
		var level = getLevel(i);
		for( index in 0...interactive.length ) {
			var i1 : Sprite = i;
			var i2 : Sprite = interactive[index];
			var lv1 = level;
			var lv2 = getLevel(i2);
			var p1 : Sprite = i1;
			var p2 : Sprite = i2;
			while( lv1 > lv2 ) {
				i1 = p1;
				p1 = p1.parent;
				lv1--;
			}
			while( lv2 > lv1 ) {
				i2 = p2;
				p2 = p2.parent;
				lv2--;
			}
			while( p1 != p2 ) {
				i1 = p1;
				p1 = p1.parent;
				i2 = p2;
				p2 = p2.parent;
			}
			if( indexOf(p1,i1) > indexOf(p2,i2) ) {
				interactive.insert(index, i);
				return;
			}
		}
		interactive.push(i);
	}
	
	@:allow(h2d)
	function removeEventTarget(i) {
		for( k in 0...interactive.length )
			if( interactive[k] == i ) {
				interactive.splice(k, 1);
				break;
			}
	}

	override function calcAbsPos() {
		// init matrix without rotation
		matA = scaleX;
		matB = 0;
		matC = 0;
		matD = scaleY;
		absX = x;
		absY = y;
		
		// adds a pixels-to-viewport transform
		var w = 2 / width;
		var h = -2 / height;
		absX = absX * w - 1;
		absY = absY * h + 1;
		matA *= w;
		matB *= h;
		matC *= w;
		matD *= h;
		
		// perform final rotation around center
		if( rotation != 0 ) {
			var cr = Math.cos(rotation);
			var sr = Math.sin(rotation);
			
			var tmpA = matA * cr + matB * sr;
			var tmpB = matA * -sr + matB * cr;
			var tmpC = matC * cr + matD * sr;
			var tmpD = matC * -sr + matD * cr;
			var tmpX = absX * cr + absY * sr;
			var tmpY = absX * -sr + absY * cr;
			matA = tmpA;
			matB = tmpB;
			matC = tmpC;
			matD = tmpD;
			absX = tmpX;
			absY = tmpY;
		}
	}
	
	public override function dispose() {
		super.dispose();
	}
	
	public function setElapsedTime( v : Float ) {
		ctx.elapsedTime = v;
	}
	
	public function render( engine : h3d.Engine ) {
		hxd.Profiler.begin("h2d.Scene:render");
		ctx.engine = engine;
		ctx.frame++;
		ctx.time += ctx.elapsedTime;
		ctx.currentPass = 0;
		
		for( p in prePasses ) 	p.render(engine);
			
		ctx.begin();
		
		hxd.Profiler.begin("h2d.Scene:render:sync");
		sync(ctx);
		hxd.Profiler.end("h2d.Scene:render:sync");
		
		hxd.Profiler.begin("h2d.Scene:render:drawRec");
		drawRec(ctx);
		hxd.Profiler.end("h2d.Scene:render:drawRec");
		ctx.end();
		
		for ( p in extraPasses ) p.render(engine);
		hxd.Profiler.end("h2d.Scene:render");
	}
	
	/**
	 allow to customize render passes (for example, branch sub scene or 2d context)
	 */
	public function addPass(p:h3d.IDrawable,before=false) {
		if( before )
			prePasses.push(p);
		else
			extraPasses.push(p);
	}
	
	public function removePass(p) {
		extraPasses.remove(p);
		prePasses.remove(p);
	}
	
	override function sync( ctx : RenderContext ) {
		if( !allocated )
			onAlloc();
		if( !fixedSize && (width != ctx.engine.width || height != ctx.engine.height) ) {
			width = ctx.engine.width;
			height = ctx.engine.height;
			posChanged = true;
		}
		Tools.checkCoreObjects();
		super.sync(ctx);
	}
	
	/**
	 * 
	 * @param	target
	 * optionnal parameter for later reuse
	 * @param	bindDepth=false
	 */
	public function captureBitmap( ?target : Tile, ?bindDepth=false , ?zone : h3d.Vector) {
		var engine = h3d.Engine.getCurrent();
		if( target == null ) {
			var tw = 1, th = 1;
			while( tw < width ) tw <<= 1;
			while( th < height ) th <<= 1;
			var tex = new h3d.mat.Texture(tw, th,false,true);
			target = new Tile(tex, 0, 0, Math.round(width), Math.round(height));
			#if cpp 
			target.flipY();
			#end
			target.getTexture().alpha_premultiplied = true;
		}
		var oc = engine.triggerClear;
		engine.triggerClear = true;
		engine.begin();
		
		if( zone == null)	engine.setRenderZone(target.x, target.y, target.width, target.height);
		else 				engine.setRenderZone(Math.round(zone.x), Math.round(zone.y), Math.round(zone.z), Math.round(zone.w));
		
		var tex = target.getTexture();
		engine.setTarget(tex,bindDepth);
		var ow = width, oh = height, of = fixedSize;
		setFixedSize(tex.width, tex.height);
		render(engine);
		width = ow;
		height = oh;
		fixedSize = of;
		posChanged = true;
		engine.setTarget(null,false,null);
		engine.setRenderZone();
		engine.end();
		
		return new Bitmap(target);
	}
	
	
	
}