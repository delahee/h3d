package h3d;
import h3d.mat.Data;
import h3d.mat.Texture;
import hxd.Profiler;
import hxd.System;

class Engine {

	public var driver(get,null) : h3d.impl.Driver;
	public var mem(default,null) : h3d.impl.MemoryManager;

	public var hardware(default, null) : Bool;
	public var width(default, null) : Int;
	public var height(default, null) : Int;
	public var debug(default, set) : Bool;

	public var drawTriangles(default, null) : Int;
	public var drawCalls(default, null) : Int;
	public var shaderSwitches(default, null) : Int;
	public var textureSwitches : Int = 0;
	public var renderZoneSwitch = 0;
	public var renderTargetSwitch = 0;
	public var apiCalls = 0;

	public var backgroundColor : Int;
	public var autoResize : Bool;
	public var fullScreen(default, set) : Bool;
	
	public var triggerClear : Bool = true;
	
	public var fps(get, never) : Float;
	public var frameCount : Int = 0;
	
	public var forcedMatBits : Int = 0;
	public var forcedMatMask : Int = 0xFFFFFF;
	public var depthClear = 1.0;
	
	var realFps : Float;
	var lastTime : Float;
	var antiAlias : Int;
	
	var debugPoint : h3d.Drawable<h3d.impl.Shaders.PointShader>;
	var debugLine : h3d.Drawable<h3d.impl.Shaders.LineShader>;
	
	@:allow(h3d)
	var curProjMatrix : h3d.Matrix;
	
	//containes x,y,w,h
	var renderZone : h3d.Vector;
	var hasRenderZone : Bool;
	
	@:access(hxd.Stage)
	public function new( hardware = true, aa = 0 ) {
		Profiler.init();
		
		this.hardware = hardware;
		this.antiAlias = aa;
		this.autoResize = true;
		renderZone = new h3d.Vector();
		
		if ( System.debugLevel >= 2) trace("booting");
		
		#if (!flash && openfl)
			if( System.debugLevel>=2) trace("ofl boot");
			hxd.Stage.openFLBoot(start);
		#else
			if( System.debugLevel>=2) trace("flash boot");
			start();
		#end
		
		
	}
	
	inline function get_driver() return driver;
	
	
	public inline function getNativeDriver()
	#if flash
		return cast(driver, h3d.impl.Stage3dDriver);
	#else
		return cast(driver,  h3d.impl.GlDriver);
	#end
	
	function start() {
		#if debug 
		trace("engine started");
		#end
		
		fullScreen = !hxd.System.isWindowed;
		
		var stage = hxd.Stage.getInstance();
		realFps = stage.getFrameRate();
		lastTime = haxe.Timer.stamp();
		stage.addResizeEvent(onStageResize);
		
		#if ((flash) && (!js) && (!cpp))
		var s = new h3d.impl.Stage3dDriver();
		driver = s;
		s.antiAlias = antiAlias;
		#elseif (js || cpp)
		#if debug
		trace("creating gl driver !");
		#end
		System.trace1("creating gl driver !");
		driver = new h3d.impl.GlDriver();
		System.trace1("created gl driver !");
		#else
		throw "No driver";
		#end
		if( CURRENT == null )
			CURRENT = this;
	}
	
	static var CURRENT : Engine = null;
	
	
	public static inline function check() {
		#if debug
		if ( hxd.System.debugLevel >= 1 ) {
			if ( CURRENT == null ) 
				hxd.System.trace1("no current context, please do this operation after engine init/creation");
		}
		#end
	}
	
	public static inline function getCurrent() {
		check();
		return CURRENT;
	}
	
	public inline function setCurrent() {
		CURRENT = this;
	}

	public function init() {
		#if debug
		trace("engine init");
		trace("driver:" + (driver != null));
		#end
		
		driver.init(onCreate, !hardware);
	}

	public function driverName(details=false) {
		return driver.getDriverName(details);
	}

	public function selectShader( shader : h3d.impl.Shader ) {
		if( driver.selectShader(shader) )
			shaderSwitches++;
	}

	@:access(h3d.mat.Material.bits)
	public function selectMaterial( m : h3d.mat.Material ) {
		var mbits = (m.bits & forcedMatMask) | forcedMatBits;
		
		hxd.Profiler.begin("selectMaterial");
		driver.selectMaterial(mbits);
		hxd.Profiler.end("selectMaterial");
		
		hxd.Profiler.begin("selectShader");
		selectShader(m.shader);
		hxd.Profiler.end("selectShader");
	}

	inline function selectBuffer( buf : h3d.impl.MemoryManager.BigBuffer ) {
		if( buf.isDisposed() ) return false;
		driver.selectBuffer(buf.vbuf);
		return true;
	}

	public inline function renderTriBuffer( b : h3d.impl.Buffer, start = 0, max = -1 ) {
		var v =  renderBuffer(b, mem.indexes, 3, start, max);
		return v;
	}
	
	public 
	#if !debug 
	inline 
	#end
	function renderQuadBuffer( b : h3d.impl.Buffer, start = 0, max = -1 ) {
		var v = renderBuffer(b, mem.quadIndexes, 2, start, max);
		return v;
	}

	/** we use preallocated indexes so all the triangles are stored inside our buffers
	 * returns true if something was actually rendered
	 * */
	function renderBuffer( b : h3d.impl.Buffer, indexes : h3d.impl.Indexes, vertPerTri : Int, startTri = 0, drawTri = -1 ) : Bool {
		if ( indexes.isDisposed() ) 
			return false;
		do {
			var ntri = Std.int(b.nvert / vertPerTri);
			var pos = Std.int(b.pos / vertPerTri);
			if( startTri > 0 ) {
				if( startTri >= ntri ) {
					startTri -= ntri;
					b = b.next;
					continue;
				}
				pos += startTri;
				ntri -= startTri;
				startTri = 0;
			}
			if( drawTri >= 0 ) {
				if( drawTri == 0 ) return false;
				drawTri -= ntri;
				if( drawTri < 0 ) {
					ntri += drawTri;
					drawTri = 0;
				}
			}
			if ( ntri > 0 && selectBuffer(b.b) ) {
				// *3 because it's the position in indexes which are always by 3
				
				#if debug
				hxd.System.trace2("driver.draw");
				#end
				driver.draw(indexes.ibuf, pos * 3, ntri);
				drawTriangles += ntri;
				drawCalls++;
			}
			//else no tri or not selectable buff
			b = b.next;
		} while ( b != null );
		
		return true;
	}
	
	// we use custom indexes, so the number of triangles is the number of indexes/3
	public function renderIndexed( b : h3d.impl.Buffer, indexes : h3d.impl.Indexes, startTri = 0, drawTri = -1 ) {
		if( b.next != null )
			throw "Buffer is split";
		if( indexes.isDisposed() )
			return;
			
		var maxTri = Std.int(indexes.count / 3);
		if( drawTri < 0 ) drawTri = maxTri - startTri;
		if ( drawTri > 0 && selectBuffer(b.b) ) {
			#if debug
			hxd.System.trace2("renderIndexed");
			#end
			
			// *3 because it's the position in indexes which are always by 3
			driver.draw(indexes.ibuf, startTri * 3, drawTri);
			drawTriangles += drawTri;
			drawCalls++;
		}
		else {
			#if debug
			hxd.System.trace2("smt hpnd");
			#end
		}
	}
	
	public function renderMultiBuffers( buffers : Array<h3d.impl.Buffer.BufferOffset>, indexes : h3d.impl.Indexes, startTri = 0, drawTri = -1 ) {
		
		var maxTri = Std.int(indexes.count / 3);
		if ( maxTri <= 0 ) return;
		
		driver.selectMultiBuffers(buffers);
		if( indexes.isDisposed() )
			return;
		if( drawTri < 0 ) drawTri = maxTri - startTri;
		if( drawTri > 0 ) {
			// render
			driver.draw(indexes.ibuf, startTri * 3, drawTri);
			drawTriangles += drawTri;
			drawCalls++;
		}		
	}

	function set_debug(d) {
		debug = d;
		driver.setDebug(debug);
		return d;
	}

	function onCreate( disposed : Bool ) {
		#if debug 
		trace("onCreate");
		#end
		if ( System.debugLevel >= 1) trace('onCreate lost:'+Std.string(disposed));
		
		if( autoResize ) {
			width = hxd.System.width;
			height = hxd.System.height;
		}
		
		if( disposed )
			mem.onContextLost();
		else {
			if ( mem != null ) throw "mem creation assert";
			mem = new h3d.impl.MemoryManager(driver, 16*1024);
		}
			
		hardware = driver.isHardware();
		set_debug(debug);
		set_fullScreen(fullScreen);
		resize(width, height);
		
		
		
		if( disposed ){
			onContextLost();
			h2d.Tools.createCoreObjects();
		} else {
			h2d.Tools.createCoreObjects();
			onReady();//do not reenter
			onReady = function() { };
		}
	}
	
	public dynamic function onContextLost() {
		trace('onContextLost');
	}

	public dynamic function onReady() {
		trace('onReady');
	}
	
	function onStageResize() {
		if( autoResize && !driver.isDisposed() ) {
			var w = hxd.System.width, h = hxd.System.height;
			if( w != width || h != height )
				resize(w, h);
			onResized();
		}
	}
	
	public dynamic function onResized() {
		if ( System.debugLevel>=1) trace('onResized');
	}

	public function resize(width:Int, height:Int) {
		#if debug
		System.trace2('engine resize $width,$height');
		#end
		// minimum 32x32 size
		if( width < 32 ) width = 32;
		if( height < 32 ) height = 32;
		this.width = width;
		this.height = height;
		
		if ( !driver.isDisposed() ) driver.resize(width, height);
		
		var g = getRenderZone();
		if( g!=null)
			setRenderZone( Math.round(g.x), Math.round(g.y), Math.round(g.z), Math.round(g.w));
		else 
			setRenderZone();
			
		#if (profileGpu&&flash)
		flash.profiler.Telemetry.sendMetric( "resize", width+"x"+height );
		#end
	}
	
	function set_fullScreen(v) {
		fullScreen = v;
		if( mem != null && hxd.System.isWindowed )
			hxd.Stage.getInstance().setFullScreen(v);
		return v;
	}

	public function begin() {
		if ( driver.isDisposed() ){
			
			#if debug
			hxd.System.trace2("can't begin, no driver"); 
			#end
			
			return false;
		}
			
		if ( triggerClear ) {
			
			#if debug
			hxd.System.trace2("calling for clear"); 
			#end
			
			#if (profileGpu&&flash)		
			var m = flash.profiler.Telemetry.spanMarker;
			#end
			
			driver.clear( 	((backgroundColor >> 16) & 0xFF) / 255 ,
							((backgroundColor >> 8) & 0xFF) / 255,
							(backgroundColor & 0xFF) / 255, 
							((backgroundColor >>> 24) & 0xFF) / 255);
							
			#if (profileGpu&&flash)					
			flash.profiler.Telemetry.sendSpanMetric( "driver.clear" , m );
			#end
		}
		else {
			#if debug
			hxd.System.trace2("no clear requested"); 
			#end
		}
							
		driver.begin(frameCount);
		
		#if (profileGpu&&flash)
		var t = flash.profiler.Telemetry;
		t.sendMetric( "textureSwitches", textureSwitches );
		t.sendMetric( "shaderSwitches", shaderSwitches );
		t.sendMetric( "drawTriangles", drawTriangles );
		t.sendMetric( "drawCalls", drawCalls );
		t.sendMetric( "renderTargetSwitch", renderTargetSwitch );
		t.sendMetric( "renderZoneSwitch", renderZoneSwitch );
		t.sendMetric( "apiCalls", apiCalls );
		#end
		
		// init
		frameCount++;
		drawTriangles = 0;
		shaderSwitches = 0;
		drawCalls = 0;
		renderTargetSwitch = 0;
		renderZoneSwitch = 0;
		apiCalls = 0;
		curProjMatrix = null;
		driver.reset();
		return true;
	}

	function reset() {
		driver.reset();
		mem.reset();
	}

	public function end() {
		driver.present();
		reset();
		curProjMatrix = null;
	}

	
	var currentTarget : h3d.mat.Texture;
	
	public function getTarget() :Null<h3d.mat.Texture> {
		return currentTarget;
	}
	
	/**
	 * Setus a render target to do off screen rendering,
	 * Warning can cost an arm on lower end device, on mobile should be just used for composition
	 * Warning [Samsungs note] you should ALWAYS clear the target just after setup so that the target is bound into GPU RAM before drawing
	 * @param	tex
	 * @param	bindDepth = false decide whether the z buffer should have a valid writing stage
	 * @param	clearColor = 0
	 */
	public function setTarget( tex : h3d.mat.Texture, ?bindDepth = false, ?clearColor : Null<Int> = 0 ) : Void {
		if ( tex != null && tex.isDisposed() ) 		tex.realloc();
		if ( tex != null )							tex.flags.set(AlphaPremultiplied);
		
		driver.setRenderTarget(tex == null ? null : tex, bindDepth, clearColor);
		currentTarget = tex;
		
		renderTargetSwitch++;
	}

	
	public inline function getRenderZone(?v:h3d.Vector) : Null<h3d.Vector> {
		return (!hasRenderZone)?null:((v != null)? { v.load(renderZone); v; } : renderZone.clone());
	}
	
	/**
	 * Sets up a scissored zone to eliminate fragments.
	 */
	public function setRenderZone( x = 0, y = 0, ?width = -1, ?height = -1 ) : Void {
		driver.setRenderZone(x, y, width, height);
		if ( x == 0 && y == x && width == -1 && height == width ){
			hasRenderZone = false;
			renderZone.set(0,0,-1,-1);
		}
		else  {
			renderZone.x = x;
			renderZone.y = y;
			renderZone.z = width;
			renderZone.w = height;
			hasRenderZone = true;
		}
		
		renderZoneSwitch++;
	}

	public function render( obj : { function render( engine : Engine ) : Void; } ) {
		if ( !begin() ) {
			#if debug
			hxd.System.trace2("can't begin");
			#end
			return false;
		}
		
		#if (profileGpu&&flash)
		var m = flash.profiler.Telemetry.spanMarker;
		#end
		
		obj.render(this);
		end();
		
		var delta = haxe.Timer.stamp() - lastTime;
		lastTime += delta;
		if( delta > 0 ) {
			var curFps = 1. / delta;
			if( curFps > realFps * 2 ) curFps = realFps * 2 else if( curFps < realFps * 0.5 ) curFps = realFps * 0.5;
			var f = delta / .5;
			if( f > 0.3 ) f = 0.3;
			realFps = realFps * (1 - f) + curFps * f; // smooth a bit the fps
		}
		
		#if (profileGpu&&flash)
		flash.profiler.Telemetry.sendSpanMetric( "render", m );
		#end
		
		
		return true;
	}
	/*
	public inline function getShaderProjection()
	{
		return driver.selectShaderProjection(curProjMatrix, curTransposeProjMatrix);
	}
	*/
	
	// debug functions
	public function point( x : Float, y : Float, z : Float, color = 0x80FF0000, size = 1.0, depth = false ) {
		if( curProjMatrix == null )
			return;
		if( debugPoint == null ) {
			debugPoint = new Drawable(new h3d.prim.Plan2D(), new h3d.impl.Shaders.PointShader());
			debugPoint.material.blend(SrcAlpha, OneMinusSrcAlpha);
		}
		
		debugPoint.material.depthWrite = false;
		debugPoint.material.culling = None;
		debugPoint.material.depthTest = depth ? h3d.mat.Data.Compare.LessEqual : h3d.mat.Data.Compare.Always;
		debugPoint.shader.mproj = curProjMatrix;
		debugPoint.shader.delta = new h3d.Vector(x, y, z, 1);
		var gscale = 1 / 200;
		debugPoint.shader.size = new h3d.Vector(size * gscale, size * gscale * width / height);
		debugPoint.shader.color = color;
		debugPoint.render(h3d.Engine.getCurrent());
	}

	public function line( x1 : Float, y1 : Float, z1 : Float, x2 : Float, y2 : Float, z2 : Float, color = 0x80FF0000, depth = false ) {
		if ( curProjMatrix == null ) {
			if ( System.debugLevel==2 ) trace("line render failed, no proj mat");
			throw "FATAL ERROR";
		}
		if( debugLine == null ) {
			debugLine = new Drawable(new h3d.prim.Plan2D(), new h3d.impl.Shaders.LineShader());
			debugLine.material.blend(SrcAlpha, OneMinusSrcAlpha);
		}
		
		debugLine.material.depthTest = depth ? h3d.mat.Data.Compare.LessEqual : h3d.mat.Data.Compare.Always;
		debugLine.material.culling = None;
		debugLine.material.depthWrite = false;
		debugLine.shader.mproj = curProjMatrix;
		debugLine.shader.start = new h3d.Vector(x1, y1, z1);
		debugLine.shader.end = new h3d.Vector(x2, y2, z2);
		debugLine.shader.color = color;
		
		debugLine.render(h3d.Engine.getCurrent());
	}

	public function lineP( a , b , color = 0x80FF0000, depth = false ) {
		line(a.x, a.y, a.z, b.x, b.y, b.z, color, depth);
	}

	public function dispose() {
		driver.dispose();
		hxd.Stage.getInstance().removeResizeEvent(onStageResize);
	}
	
	function get_fps() {
		return Math.ceil(realFps * 100) / 100;
	}
	
	#if (openfl||lime)
	public function restoreOpenfl() {
		#if sys
			//lime will issue a clear by itself
			triggerClear = false;
		#end
		driver.restoreOpenfl();
	}
	#end
}
