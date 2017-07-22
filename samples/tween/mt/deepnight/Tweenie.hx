package mt.deepnight;

enum TType {
	TLinear;
	TLoop; // loop : valeur initiale -> valeur finale -> valeur initiale
	TLoopEaseIn; // loop avec départ lent
	TLoopEaseOut; // loop avec fin lente
	TEase;
	TEaseIn; // départ lent, fin linéaire
	TEaseOut; // départ linéaire, fin lente
	TBurn; // départ rapide, milieu lent, fin rapide,
	
	TBurnIn; // départ rapide, fin lente,
	TBurnOut; // départ lente, fin rapide
	TZigZag; // une oscillation et termine sur Fin
	TRand; // progression chaotique de début -> fin. ATTENTION : la durée ne sera pas respectée (plus longue)
	TShake; // variation aléatoire de la valeur entre Début et Fin, puis s'arrête sur Début (départ rapide)
	TShakeBoth; // comme TShake, sauf que la valeur tremble aussi en négatif
	TJump; // saut de Début -> Fin
	TElasticEnd; // léger dépassement à la fin, puis réajustment
	
	TBurn2; // départ rapide, milieu lent, fin rapide,
}

// GoogleDoc pour tester les valeurs de Bézier
// ->	https://spreadsheets.google.com/ccc?key=0ArnbjvQe8cVJdGxDZk1vdE50aUxvM1FlcDAxNWRrZFE&hl=en&authkey=CLCwp8QO

@:publicFields
class Tween {
	var man 		: Tweenie;	 
	var parent		: Dynamic;
	var vname		: String;
	var n			: Float;
	var ln			: Float;
	var speed		: Float;
	var from		: Float;
	var to			: Float;
	var type		: TType;
	var plays		: Int; // -1 = infini, 1 et plus = nombre d'exécutions (1 par défaut)
	var fl_pixel	: Bool; // arrondi toutes les valeurs si TRUE (utile pour les anims pixelart)
	var onUpdate	: Null<Void->Void>;
	var onUpdateT	: Null<Float->Void>; // callback appelé avec la progression (0->1) en paramètre
	var onEnd		: Null<Void->Void>;
	var interpolate	: Float->Float;
	
	var forceProperties = true;
	
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
	    onUpdate	 ,
	    onUpdateT	 ,
	    onEnd		 ,
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
		this.onUpdate	    = onUpdate	 	;
		this.onUpdateT	    = onUpdateT	 	;
		this.onEnd		    = onEnd		 	;
		this.interpolate    = interpolate	;
	}
	
	public inline
	function apply( val ) {
		if ( parent == null) return;
		else 
		if ( Reflect.hasField( parent, vname ) && !forceProperties )
			Reflect.setField( parent, vname, val );
		else 										
			Reflect.setProperty(parent, vname, val);
	}
	
	public inline function kill( withCbk = true ) {
		if ( withCbk )	
			man.terminateTween( this );
		else 
			man.forceTerminateTween( this) ;
	}
	
}

/**
 * tween order is not respected
 */
class Tweenie {
	static var DEFAULT_DURATION = DateTools.seconds(1);
	public var fps = 60.0;

	var tlist			: hxd.Stack<Tween>;
	var errorHandler	: String->Void;

	public function new() {
		tlist = new hxd.Stack<Tween>();
		errorHandler = onError;
	}
	
	function onError(e) {
		trace(e);
	}
	
	public function count() {
		return tlist.length;
	}
	
	public function setErrorHandler(cb:String->Void) {
		errorHandler = cb;
	}
	
	public inline function create(parent:Dynamic, varName:String, to:Float, ?tp:TType, ?duration_ms:Float) {
		return create_(parent, varName, to, tp, duration_ms);
	}
	
	public function exists(p:Dynamic, v:String) {
		for (t in tlist)
			if (t.parent == p && t.vname == v)
				return true;
		return false;
	}

	function create_(p:Dynamic, v:String, to:Float, ?tp:TType, ?duration_ms:Float) {
		if ( duration_ms==null )
			duration_ms = DEFAULT_DURATION;

		trace(duration_ms);
		trace(fps);
		#if debug
		if ( p == null ) errorHandler("tween creation failed : null parent, v=" + v + " tp=" + tp);
		#end
			
		if ( tp==null )
			tp = TEase;

		// on supprime les tweens précédents appliqués à la même variable
		var tfound : TType = null;
		for(t in tlist.backWardIterator())
			if(t.parent==p && t.vname==v) {
				tfound = t.type;
				tlist.remove(t);
			}
			
		if ( tfound!=null ) {
			if (tp==TEase && (tfound==TEase || tfound==TEaseOut) )
				tp = TEaseOut;
		}
		// ajout
		var t : Tween = new Tween(
			p,
			v,
			0.0,
			0.0,
			1 / ( duration_ms*fps/1000 ), // une seconde
			Reflect.getProperty(p,v),
			to,
			tp,
			1,
			false,
			null,
			null,
			null,
			getInterpolateFunction(tp)
		);

		if( t.from==t.to )
			t.ln = 1; // tweening inutile : mais on s'assure ainsi qu'un update() et un end() seront bien appelés

		t.man = this;
		tlist.push(t);

		return t;
	}

	public static inline function fastPow2(n:Float):Float {
		return n*n;
	}
	
	public static inline function fastPow3(n:Float):Float {
		return n*n*n;
	}

	public static inline function bezier(t:Float, p0:Float, p1:Float,p2:Float, p3:Float) {
		return
			fastPow3(1-t)*p0 +
			3*( t*fastPow2(1-t)*p1 + fastPow2(t)*(1-t)*p2 ) +
			fastPow3(t)*p3;
	}

	public function delete(parent:Dynamic) { // attention : les callbacks end() / update() ne seront pas appelés !
		for(t in tlist.backWardIterator())
			if(t.parent==parent)
				tlist.remove(t);
	}
	
	// suppression du tween sans aucun appel aux callbacks onUpdate, onUpdateT et onEnd (!)
	public function killWithoutCallbacks(parent:Dynamic, ?varName:String) : Bool {
		for (t in tlist.backWardIterator())
			if (t.parent==parent && (varName==null || varName==t.vname)){
				tlist.remove(t);
				return true;
			}
		return false;
	}
	
	public function terminate(parent:Dynamic, ?varName:String) {
		for (t in tlist.backWardIterator())
			if (t.parent==parent && (varName==null || varName==t.vname))
				terminateTween(t);
	}
	
	public function forceTerminateTween(t:Tween) {
		tlist.remove(t);
	}
	
	public function terminateTween(t:Tween, ?fl_allowLoop=false) {
		var v = t.from+(t.to-t.from)*t.interpolate(1);
		if (t.fl_pixel)
			v = Math.round(v);
		t.apply(v);
		onUpdate(t,1);
		onEnd(t);
		if( fl_allowLoop && (t.plays==-1 || t.plays>1) ) {
			if( t.plays!=-1 )
				t.plays--;
			t.n = t.ln = 0;
		}
		else
			tlist.remove(t);
	}
	public function terminateAll() {
		for(t in tlist)
			t.ln = 1;
		update();
	}
	
	
	inline function onUpdate(t:Tween, n:Float) {
		if ( t.onUpdate!=null )
			t.onUpdate();
		if ( t.onUpdateT!=null )
			t.onUpdateT(n);
	}
	inline function onEnd(t:Tween) {
		if ( t.onEnd!=null )
			t.onEnd();
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
	
	public static inline function getInterpolateFunction(type:TType) {
		return switch(type) {
			case TLinear		: identityStep   ;
			case TRand			: identityStep   ;
			case TEase			: fEase		     ;
			case TEaseIn		: fEaseIn		 ;
			case TEaseOut		: fEaseOut		 ;
			case TBurn			: fBurn		     ;
			case TBurnIn		: fBurnIn		 ;
			case TBurnOut		: fBurnOut		 ;
			case TZigZag		: fZigZag		 ;
			case TLoop			: fLoop		     ;
			case TLoopEaseIn	: fLoopEaseIn	 ;
			case TLoopEaseOut	: fLoopEaseOut	 ;
			case TShake			: fShake		 ;
			case TShakeBoth		: fShakeBoth	 ;
			case TJump			: fJump		     ;
			case TElasticEnd	: fElasticEnd	 ;
			case TBurn2			: fBurn2		 ;
		}
	}
	
	public function update(?tmod = 1.0) {
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
							t.from + Lib.randFloat(Lib.abs(t.n*dist)) * (dist>0?1:-1);
						else
							t.from + Lib.randFloat(t.n*dist) * (Std.random(2)*2-1);
					if (t.fl_pixel)
						val = Math.round(val);
					
					t.apply(val);
					
					onUpdate(t, t.ln);
				}
				else // fini !
					terminateTween(t, true);
			}
		}
	}
}
