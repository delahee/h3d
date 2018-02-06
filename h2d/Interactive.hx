package h2d;

class Interactive extends Drawable {

	/**
	Setting to null will disable cursor management
	*/
	public var cursor(default,set) : Null<hxd.System.Cursor>;
	public var isEllipse : Bool;
	public var blockEvents : Bool = true;
	public var propagateEvents : Bool = false;
	public var backgroundColor : Null<Int>;
	public var backgroundBlocks = true;
	public var enableRightButton : Bool;
	var scene : Scene;
	var isMouseDown : Int = -1;
	var isMouseDownDuration : Int = -1;
	
	public function new(width, height, ?parent:h2d.Sprite) {
		super(parent);
		this.width = width;
		this.height = height;
		cursor = Button;
	}
	
	public override function set_width(w) 	return this.width=w;
	public override function set_height(h) 	return this.height=h;
	public override function get_width() 	return this.width;
	public override function get_height() 	return this.height;

	override function onAlloc() {
		this.scene = getScene();
		if( scene != null ) scene.addEventTarget(this);
		super.onAlloc();
	}

	override function draw( ctx : RenderContext ) {
		if ( backgroundColor != null && (backgroundColor>>>24) > 0 ) { //don't use for prod content please, cuz may have a weird alloc policy if width and height changes a lot
			ctx.flush();
			drawTile(ctx,h2d.Tile.fromColor(backgroundColor,Std.int(width),Std.int(height)));
		}
	}

	override function getBoundsRec( relativeTo, out,forSize ) {
		super.getBoundsRec(relativeTo, out,forSize);
		if( backgroundColor!=null&&backgroundBlocks) addBounds(relativeTo, out, 0, 0, Std.int(width), Std.int(height));
	}
	
	override function onParentChanged() {
		if( scene != null ) {
			scene.removeEventTarget(this);
			scene.addEventTarget(this);
		}
	}
	
	override function calcAbsPos() {
		super.calcAbsPos();
		// force a move event if we update the current over interactive
		if( scene != null && scene.currentOver == this ) {
			var stage = hxd.Stage.getInstance();
			var e = new hxd.Event(EMove, stage.mouseX, stage.mouseY);
			@:privateAccess scene.onEvent(e);
		}
	}
	
	override function onDelete() {
		if( scene != null ) {
			scene.removeEventTarget(this);
			if( scene.currentOver == this ) {
				scene.currentOver = null;
				if( cursor!=null)
					hxd.System.setCursor(Default);
			}
			if( scene.currentFocus == this )
				scene.currentFocus = null;
		}
		super.onDelete();
	}

	function checkBounds( e : hxd.Event ) {
		return switch( e.kind ) {
		case EOut, ERelease, EFocus, EFocusLost: false;
		default: true;
		}
	}
	
	@:allow(h2d.Scene)
	function handleEvent( e : hxd.Event ) {
		if ( width < 0 || height < 0 ){
			e.cancel = true;
			return;
		}
		if( isEllipse && checkBounds(e) ) {
			var cx = width * 0.5, cy = height * 0.5;
			var dx = (e.relX - cx) / cx;
			var dy = (e.relY - cy) / cy;
			if( dx * dx + dy * dy > 1 ) {
				e.cancel = true;
				return;
			}
		}
		if( propagateEvents ) e.propagate = true;
		if( !blockEvents ) e.cancel = true;
		switch( e.kind ) {
		case ESimulated://not this func concerns
		case EMove:
			onMove(e);
		case EPush:
			if( enableRightButton || e.button == 0 ) {
				isMouseDown = e.button;
				isMouseDownDuration = 0;
				e.duration = isMouseDownDuration;
				onPush(e);
			}
		case ERelease:
			e.duration = isMouseDownDuration;
			if( enableRightButton || e.button == 0 ) {
				onRelease(e);
				if( !e.cancel && isMouseDown == e.button )
					onClick(e);
			}
			isMouseDown = -1;
			isMouseDownDuration = -1;
		case EOver:
			if( cursor!=null)
				hxd.System.setCursor(cursor);
			onOver(e);
		case EOut:
			isMouseDown = -1;
			isMouseDownDuration = -1;
			if( cursor!=null)
				hxd.System.setCursor(Default);
			onOut(e);
		case EWheel:
			onWheel(e);
		case EFocusLost:
			onFocusLost(e);
			if( !e.cancel && scene != null && scene.currentFocus == this ) scene.currentFocus = null;
		case EFocus:
			onFocus(e);
			if( !e.cancel && scene != null ) scene.currentFocus = this;
		case EKeyUp:
			onKeyUp(e);
		case EKeyDown:
			onKeyDown(e);
		}
	}
	
	function set_cursor(c) {
		this.cursor = c;
		if( scene != null && scene.currentOver == this )
			if( cursor!=null)
				hxd.System.setCursor(cursor);
		return c;
	}
	
	function eventToLocal( e : hxd.Event ) {
		// convert global event to our local space
		var x = e.relX, y = e.relY;
		var rx = x * scene.matA + y * scene.matB + scene.absX;
		var ry = x * scene.matC + y * scene.matD + scene.absY;
		var r = scene.height / scene.width;
		
		var i = this;
		
		var dx = rx - i.absX;
		var dy = ry - i.absY;
		
		var w1 = i.width * i.matA * r;
		var h1 = i.width * i.matC;
		var ky = h1 * dx - w1 * dy;
		
		var w2 = i.height * i.matB * r;
		var h2 = i.height * i.matD;
		var kx = w2 * dy - h2 * dx;
		
		var max = h1 * w2 - w1 * h2;
		
		e.relX = (kx * r / max) * i.width;
		e.relY = (ky / max) * i.height;
	}
	
	public function startDrag(callb,?onCancel) {
		scene.startDrag(function(event) {
			var x = event.relX, y = event.relY;
			eventToLocal(event);
			callb(event);
			event.relX = x;
			event.relY = y;
		},onCancel);
	}
	
	public function stopDrag() {
		scene.stopDrag();
	}
	
	public function focus() {
		if( scene == null )
			return;
		var ev = new hxd.Event(null);
		if( scene.currentFocus != null ) {
			if( scene.currentFocus == this )
				return;
			ev.kind = EFocusLost;
			scene.currentFocus.handleEvent(ev);
			if( ev.cancel ) return;
		}
		ev.kind = EFocus;
		handleEvent(ev);
	}
	
	public function blur() {
		if( scene == null )
			return;
		if( scene.currentFocus == this ) {
			var ev = new hxd.Event(null);
			ev.kind = EFocusLost;
			scene.currentFocus.handleEvent(ev);
		}
	}
	
	public override function sync(ctx) {
		if ( isMouseDown >= 0) isMouseDownDuration++;
		super.sync(ctx);
		onSync();
	}
	
	public function hasFocus() {
		return scene != null && scene.currentFocus == this;
	}
	
	public dynamic function onOver( e : hxd.Event ) : Void {
	}

	public dynamic function onOut( e : hxd.Event ) : Void {
	}
	
	public dynamic function onPush( e : hxd.Event ) : Void {
	}

	public dynamic function onRelease( e : hxd.Event ) : Void {
	}

	public dynamic function onClick( e : hxd.Event ) : Void {
	}
	
	public dynamic function onMove( e : hxd.Event ) : Void {
	}

	public dynamic function onWheel( e : hxd.Event ) : Void {
	}

	public dynamic function onFocus( e : hxd.Event ) : Void {
	}
	
	public dynamic function onFocusLost( e : hxd.Event ) : Void {
	}

	public dynamic function onKeyUp( e : hxd.Event ) : Void {
	}

	public dynamic function onKeyDown( e : hxd.Event ) : Void {
	}
	
	public dynamic function onSync(  ) : Void {
		
	}
	
}