package h2d;

enum TType {
	TLinear;
	TLoop; 			// loop : valeur initiale -> valeur finale -> valeur initiale
	TLoopEaseIn; 	// loop avec départ lent
	TLoopEaseOut; 	// loop avec fin lente
	TEase;
	TEaseIn; 		// départ lent, fin linéaire
	TEaseOut; 		// départ linéaire, fin lente
	TBurn; 			// départ rapide, milieu lent, fin rapide,
	
	TBurnIn; 		// départ rapide, fin lente,
	TBurnOut; 		// départ lente, fin rapide
	TZigZag; 		// une oscillation et termine sur Fin
	TRand; 			// progression chaotique de début -> fin. ATTENTION : la durée ne sera pas respectée (plus longue)
	TShake; 		// variation aléatoire de la valeur entre Début et Fin, puis s'arrête sur Début (départ rapide)
	TShakeBoth; 	// comme TShake, sauf que la valeur tremble aussi en négatif
	TJump; 			// saut de Début -> Fin
	TElasticEnd; 	// léger dépassement à la fin, puis réajustment
	
	TBurn2; 		// départ rapide, milieu lent, fin rapide,
}


@:enum
abstract TVarName(Int) {
	var VNone		= -1;
	
	var VX			= 0;
	var VY			= 1;
	var VScaleX		= 2;
	var VScaleY		= 3;
	var VAlpha		= 4;
	var VRotation	= 5;
	
	var VR			= 6;
	var VG			= 7;
	var VB			= 8;
	var VA			= 9;
	
	var VScale		= 10;
	
	var VWidth		= 11;
	var VHeight		= 12;
}

@:publicFields
class Tween {
	static var GUID = 0;
	var uid 		= 0;
	var man 		: Tweenie;	 
	var parent		: TSprite;
	var vname		: TVarName = VNone;
	var n			: Float = 0.0;
	var ln			: Float = 0.0;
	var speed		: Float = 0.0;
	var from		: Float;
	var to			: Float;
	var type		: TType;
	var plays		: Int; // -1 = infini, 1 et plus = nombre d'exécutions (1 par défaut)
	var fl_pixel	: Bool; // arrondi toutes les valeurs si TRUE (utile pour les anims pixelart)
	
	var onUpdate	: Null<TSprite->Void>;
	var onUpdateT	: Null<TSprite->Float->Void>; // callback appelé avec la progression (0->1) en paramètre
	var onEnd		: Null<TSprite->Void>;
	
	var interpolate	: Float->Float;
	var delayMs		: Float;
	
	public inline function new (
		parent		 ,
	    vname		 ,
	    n			 ,
	    ln			 ,
	    speed		 ,
	    from		 ,
	    to			 ,
	    type		 ,
	    plays		 ,
	    fl_pixel	 ,
	    interpolate
	) {
		this.parent			= parent		;
		this.vname		    = vname		 	;
		this.n			    = n			 	;
		this.ln			    = ln			;
		this.speed		    = speed			;
		this.from		    = from			;
		this.to			    = to			;
		this.type		    = type		 	;
		this.plays		    = plays		 	;
		this.fl_pixel	    = fl_pixel	 	;
		this.interpolate    = interpolate	;
		uid = GUID++;
	}
	
	public inline function reset (
		parent		 ,
	    vname		 ,
	    n			 ,
	    ln			 ,
	    speed		 ,
	    from		 ,
	    to			 ,
	    type		 ,
	    plays		 ,
	    fl_pixel	 ,
	    interpolate
	) {
		//if ( Tweenie.DEBUG )trace("reset " + uid);
		
		this.parent			= parent		;
		this.vname		    = vname		 	;
		this.n			    = n			 	;
		this.ln			    = ln			;
		this.speed		    = speed			;
		this.from		    = from			;
		this.to			    = to			;
		this.type		    = type		 	;
		this.plays		    = plays		 	;
		this.fl_pixel	    = fl_pixel	 	;
		this.interpolate    = interpolate	;
		uid = GUID++;
		
		//if ( Tweenie.DEBUG ) trace("nuid: " + uid);
	}
	
	public 
	#if!debug inline #end
	function clear (){
		//if ( Tweenie.DEBUG ) trace("clear " + uid);
		
		n 			= 0.0;
		ln			= 0.0;
		speed 		= 0.0;
		plays		= 0;
		from		= 0.0;
		to			= 0.0;
		vname 		= VNone;
		interpolate	= null;
		parent 		= null;
		onUpdate 	= null;
		onUpdateT 	= null;
		onEnd 		= null;
	}
	
	public inline
	function apply( val : Float ) {
		if ( parent == null) return;
		
		var parentD = Std.instance(parent, h2d.Drawable);
		switch( vname ) {
			case VNone		: 
			case VX			: parent.x 			= val;
			case VY			: parent.y 			= val;
			case VScaleX	: parent.scaleX 	= val;
			case VScaleY	: parent.scaleY 	= val;
			
			case VRotation	: parent.rotation 	= val;
			
			case VAlpha		: parentD.alpha 	= val;
			case VR			: parentD.color.r 	= val;
			case VG			: parentD.color.g 	= val;
			case VB			: parentD.color.b 	= val;
			case VA			: parentD.color.a 	= val;
			case VScale		: parent.setScale( val );
			case VWidth		: parent.width		= val;
			case VHeight	: parent.height		= val;
		}
		//#if debug
		//trace("val:" + val);
		//#end
	}
	
	//public 
	//inline
	//function kill( withCbk = true ) {
		//if ( Tweenie.DEBUG ){
			//trace("kill " + uid);
		//}
		//
		//if ( withCbk )	
			//man.terminateTween( this );
		//else 
			//man.forceTerminateTween( this) ;
	//}
	
}

private typedef TSprite = h2d.Sprite;
private typedef TTw = Tween;

/**
 * tween order is not respected
 */
class Tweenie {
	static var 	DEFAULT_DURATION = DateTools.seconds(1);
	public var 	fps = hxd.Stage.getInstance().getFrameRate();

	var delayList		: hxd.Stack<TTw> = new hxd.Stack<TTw>();
	var tlist			: hxd.Stack<TTw> = new hxd.Stack<TTw>();
	public var 	pool 	: hxd.Stack<TTw> = new hxd.Stack();

	public function new() {}
	public inline function count() return tlist.length;
	
	//public static inline var DEBUG = true;
	
	public function exists(p:TSprite, v:TVarName) {
		for (t in tlist)
			if (t.parent == p && t.vname == v)
				return true;
		return false;
	}

	public function delay( delay_ms:Float, parent:TSprite, varName: TVarName, to:Float, ?tp:TType, ?duration_ms:Float) {
		var p = create(parent, varName, to, tp, duration_ms);
		tlist.remove(p);
		delayList.push(p);//finish pair
		p.delayMs = delay_ms;
		//#if debug
		//trace( p.delayMs);
		//#end
		//unpop in manager
		return p;
	}
	
	public function create(parent:TSprite, varName: TVarName, to:Float, ?tp:TType, ?duration_ms:Float) {
		var p = parent;
		var v = varName;
		if ( duration_ms==null )
			duration_ms = DEFAULT_DURATION;
			
		if ( tp==null )
			tp = TLinear;
			
		switch( varName ) {
			default:
			case VR, VG, VB, VA, VAlpha: 
				if ( !Std.is( p, h2d.Drawable )) {
					//#if false		
					//trace("tween creation failed : not drawable parent, v=" + varName + " tp=" + tp);
					//#end
					p = null;
				}
		}
		
		switch( varName ) {
			default:
			case VR, VG, VB, VA: 
				var p = Std.instance( p, h2d.Drawable );
				if ( p!=null && p.color == null) p.color = new h3d.Vector(1,1,1,1);
		}

		for(t in tlist.backWardIterator())
			if (t.parent == p && t.vname == v) 
				forceTerminateTween(t);
		
		var z = 0.0;
		
		// ajout
		var t : TTw = null;
		var from = retrieve(p, v);
		
		if (pool.length == 0){
			t = new TTw(
				p,
				v,
				z,
				z,
				1.0 / ( duration_ms*fps/1000 ), // une seconde
				from,
				to,
				tp,
				1,
				false,
				getInterpolateFunction(tp)
			);
			
			//if ( DEBUG )trace("newed " + t.uid);
			
		}
		else{
			t = pool.pop();
			t.reset(
				p,
				v,
				z,
				z,
				1 / ( duration_ms * fps / 1000 ), // une seconde
				
				from,
				to,
				tp,
				1,
				false,
				getInterpolateFunction(tp)
			); 
			
			//if ( DEBUG )trace("pooled out " + t.uid);
		}
		t.delayMs = 0;

		if( t.from==t.to )
			t.ln = 1; // tweening inutile : mais on s'assure ainsi qu'un update() et un end() seront bien appelés

		t.man = this;
		tlist.push(t);
		
		//if ( DEBUG )trace("created " + t.uid);

		return t;
	}
	
	inline
	function retrieve(parent:TSprite,varName:TVarName) : Float {
		return
		if ( parent == null) 0.0;
		else {
			var parentD = Std.instance( parent, h2d.Drawable); 
			switch( varName ) {
				case VNone		: 0.0;
				case VX			: parent.x 			;
				case VY			: parent.y 			;
				case VScaleX	: parent.scaleX 	;
				case VScaleY	: parent.scaleY 	;
				case VRotation	: parent.rotation 	;
				case VScale		: parent.scaleX * parent.scaleY;
				
				case VAlpha		: parentD.alpha;
				case VR			: parentD.color.r;
				case VG			: parentD.color.g;
				case VB			: parentD.color.b;
				case VA			: parentD.color.a;
				case VWidth		: parent.width;
				case VHeight	: parent.height;
			}
		}
	}

	public static inline function fastPow2(n:Float):Float return n*n;
	public static inline function fastPow3(n:Float):Float return n*n*n;

	public static inline function bezier(t:Float, p0:Float, p1:Float, p2:Float, p3:Float) {
		var minust = 1.0 - t;
		
		return
			fastPow3(minust)*p0 +
			3*( t*fastPow2(minust)*p1 + fastPow2(t)*(minust)*p2 ) +
			fastPow3(t)*p3;
	}

	public function delete(parent:Dynamic) { // attention : les callbacks end() / update() ne seront pas appelés !
		for(t in tlist.backWardIterator())
			if(t.parent==parent) {
				tlist.remove(t);
				t.clear();
				pool.push(t);
			}
	}
	
	// suppression du tween sans aucun appel aux callbacks onUpdate, onUpdateT et onEnd (!)
	public function killWithoutCallbacks(parent:TSprite, ?varName:TVarName=VNone) : Bool {
		for (t in tlist.backWardIterator())
			if (t.parent==parent && (varName==VNone || varName==t.vname)){
				forceTerminateTween(t);
				return true;
			}
		return false;
	}
	
	public function terminate(parent:TSprite, ?varName:TVarName=VNone) {
		for (t in tlist.backWardIterator())
			if (t.parent==parent && (varName==VNone || varName==t.vname)){
				forceTerminateTween(t);
			}
	}
	
	public function forceTerminateTween(t:TTw) {
		if( tlist.remove(t) ){
			t.clear();
			pool.push(t);
		}
	}
	
	public function terminateTween(t:TTw, ?fl_allowLoop = false) {
		var v = t.from+(t.to-t.from)*t.interpolate(1);
		if (t.fl_pixel)
			v = Math.round(v);
		t.apply(v);
		onUpdate(t, 1);
		
		var ouid = t.uid;
		
		onEnd(t);
		
		if( ouid == t.uid ){
			if( fl_allowLoop && (t.plays==-1 || t.plays>1) ) {
				if( t.plays!=-1 )
					t.plays--;
				t.n = t.ln = 0;
			}
			else{
				forceTerminateTween(t);
			}
		}
	}
	public function terminateAll() {
		for(t in tlist)
			t.ln = 1;
		update();
	}
	
	inline function onUpdate(t:TTw, n:Float) {
		if ( t.onUpdate!=null ) 	t.onUpdate(t.parent);
		if ( t.onUpdateT!=null )	t.onUpdateT(t.parent,n);
	}
	
	inline function onEnd(t:TTw) {
		if ( t.onEnd!=null )		t.onEnd(t.parent);
	}
	
	static inline function identityStep(step) 	return step;
	static inline function fEase		(step) 	return bezier(step, 0,	0,		1,		1);
	static inline function fEaseIn		(step) 	return bezier(step, 0,	0,		0.5,	1);
	static inline function fEaseOut		(step) 	return bezier(step, 0,	0.5,	1,		1);
	static inline function fBurn		(step) 	return bezier(step, 0,	1,	 	0,		1);
	static inline function fBurnIn		(step) 	return bezier(step, 0,	1,	 	1,		1);
	static inline function fBurnOut		(step) 	return bezier(step, 0,	0,		0,		1);
	static inline function fZigZag		(step) 	return bezier(step, 0,	2.5,	-1.5,	1);
	static inline function fLoop		(step) 	return bezier(step, 0,	1.33,	1.33,	0);
	static inline function fLoopEaseIn	(step) 	return bezier(step, 0,	0,		2.25,	0);
	static inline function fLoopEaseOut	(step) 	return bezier(step, 0,	2.25,	0,		0);
	static inline function fShake		(step) 	return bezier(step, 0.5,	1.22,	1.25,	0);
	static inline function fShakeBoth	(step) 	return bezier(step, 0.5,	1.22,	1.25,	0);
	static inline function fJump		(step) 	return bezier(step, 0,	2,		2.79,	1);
	static inline function fElasticEnd	(step) 	return bezier(step, 0,	0.7,	1.5,	1);
	static inline function fBurn2		(step) 	return bezier(step, 0,	0.7,	 0.4,	1);
	
	static var videntityStep=  identityStep ;
	static var vfEase		=  fEase		;
	static var vfEaseIn		=  fEaseIn		;
	static var vfEaseOut	=  fEaseOut		;	
	static var vfBurn		=  fBurn		;
	static var vfBurnIn		=  fBurnIn		;
	static var vfBurnOut	=  fBurnOut		;	
	static var vfZigZag		=  fZigZag		;
	static var vfLoop		=  fLoop		;
	static var vfLoopEaseIn	=  fLoopEaseIn	;
	static var vfLoopEaseOut=  fLoopEaseOut	;	
	static var vfShake		=  fShake		;
	static var vfShakeBoth	=  fShakeBoth	;
	static var vfJump		=  fJump		;
	static var vfElasticEnd	=  fElasticEnd	;
	static var vfBurn2		=  fBurn2		;
	
	public static  
	function getInterpolateFunction(type:TType) {
		return switch(type) {
			case TLinear		: videntityStep   	;
			case TRand			: videntityStep   	;
			case TEase			: vfEase		    ;
			case TEaseIn		: vfEaseIn		 	;
			case TEaseOut		: vfEaseOut		 	;
			case TBurn			: vfBurn		 	;
			case TBurnIn		: vfBurnIn		 	;
			case TBurnOut		: vfBurnOut		 	;
			case TZigZag		: vfZigZag		 	;
			case TLoop			: vfLoop		 	;
			case TLoopEaseIn	: vfLoopEaseIn	 	;
			case TLoopEaseOut	: vfLoopEaseOut	 	;
			case TShake			: vfShake		 	;
			case TShakeBoth		: vfShakeBoth	 	;
			case TJump			: vfJump		 	;
			case TElasticEnd	: vfElasticEnd	 	;
			case TBurn2			: vfBurn2		 	;
		}
	}
	
	public static var vgetInterpolateFunction = getInterpolateFunction;
	
	inline function randFloat(f:Float):Float return Math.random()*f;
	
	public function update(?tmod = 1.0) {
		
		var deltaMs = tmod / fps * 1000.0;
		if ( delayList.length > 0 ) {
			for (t in delayList.backWardIterator() ) {
				t.delayMs -= deltaMs;
				if ( t.delayMs <= 0.0 ) {
					delayList.remove(t);
					tlist.push(t);
				}
			}
		}
		
		if ( tlist.length > 0 ) {
			for (t in tlist.backWardIterator() ) {
				var dist = t.to-t.from;
				if (t.type==TRand)
					t.ln+=if(Std.random(100)<33) t.speed * tmod else 0;
				else
					t.ln+=t.speed * tmod;
				t.n = t.interpolate(t.ln);
				if ( t.ln<1 ) {
					// en cours...
					var val =
						if (t.type!=TShake && t.type!=TShakeBoth)
							t.from + t.n*dist ;
						else if ( t.type==TShake )
							t.from + randFloat(hxd.Math.abs(t.n*dist)) * (dist>0?1:-1);
						else
							t.from + randFloat(t.n*dist) * (Std.random(2)*2-1);
					if (t.fl_pixel)
						val = Math.round(val);
					
					t.apply(val);
					
					onUpdate(t, t.ln);
				}
				else { // fini !
					terminateTween(t, true);
				}
			}
		}
	}
}