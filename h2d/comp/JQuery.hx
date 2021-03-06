package h2d.comp;
import h2d.css.Defs;

private typedef Query = Array<CssClass>;

@:access(h2d.comp.Component)
@:keep
class JQuery {
	public static var DEFAULT_API : Dynamic = { };
	
	var root : Component;
	var select : Array<Component>;
	
	public function new( root : Component, query : Dynamic ) {
		var lthis = root;
		while( root!=null && root.parentComponent != null )
			root = root.parentComponent;
		this.root = root;
		select = query!=null? getSet(query) : (lthis!=null ? [lthis] : []);
	}
	
	public inline function comps(): Array<Component> 					return getComponents();
	public inline function getComponents(): Array<Component> 			return select;
	
	
	public function clone() {
		var jq = new JQuery( root, null );
		jq.select = select.copy();
		return jq;
	}

	public inline function dataInt( name:String, ?d:Int = null ) : Int{
		var res = data(name,d);
		return Std.parseInt(Std.string(res));
	}
	
	public function data( name:String, ?d:Dynamic=null ) {
		if( d == null ){
			for ( s in select ) 
				if ( s.data != null && s.data.exists(name))
					return s.data[name];
		}
		else {
			for ( s in select ) 
				s.addData("data-" + name, d);
			return data(name,null);
		}
		return d;
	}
	
	inline function cssStr(d:Dynamic) {
		var s = new StringBuf();
		for ( f in Reflect.fields(d)) {
			s.add( f);
			s.add( ":");
			s.add( Reflect.field(d,f));
			s.add( ";");
		}
		return s.toString();
	}
	
	public function opacity(val:Float) {
		css( { opacity:val } );
		return this;
	}
	
	public function css(css:Dynamic, ?val:Dynamic) : Dynamic {
		if ( Std.is(css, Array)) {
			var arr : Array<Dynamic> = cast css;
			for ( s in select ) 
				for ( v in arr )
					css(v, val);
		}
		else if ( Std.is(css, String)) { //css('sapin','toto')
			if ( val != null) 
				for ( s in select ) {
					var lit =  Std.string(css + ":" + val + ";") ;
					s.addStyleString( lit );
				}
			else {//
				if ( select.length > 0 ) {
					var st = select[0].style;
					if ( st == null) return null;
					else return select[0].style.get(css);
				}
				else 
					return null;
			}
		}
		else if ( Std.is(css, Dynamic)) { //css('sapin','toto')
			var str = cssStr(css);
			for ( s in select ) s.addStyleString( str );
		}
			
		return this;
	}
	
	public function addClass( cl : String ) {
		for( s in select ) s.addClass(cl);
		return this;
	}

	public function removeClass( cl : String ) {
		for( s in select ) s.removeClass(cl);
		return this;
	}
	
	public function toggleClass( cl : String, ?flag : Bool ) {
		for( s in select ) s.toggleClass(cl,flag);
		return this;
	}
	
	public function hasClass( cl : String ) {
		for( s in select ) 
			if( s.hasClass(cl) )
				return true;
		return false;
	}
	
	public inline function length() {
		return select.length;
	}
	
	public function parent() {
		var sel = [];
		for ( s in select )
			if ( s.parentComponent != null )
				sel.push(s.parentComponent);
		return new JQuery(root,sel);
	}
	
	public inline function firstComp() : Null<h2d.comp.Component>		return select[0];
	
	public function nth(n:Int) {
		var sel = [];
		if( select[n]!=null)
			sel.push( select[n] );
		return new JQuery(root,[]);
	}
	
	public function nthChild(n:Int) {
		var sel = [];
		for ( s in select) {
			var n = s.components[n];
			if ( n != null)
				sel.push( n );
		}
		return new JQuery(root,sel);
	}
	
	public function first() {
		var sel = [];
		if( select.length > 1 )
			sel.push(select[0] );
		return new JQuery(root,sel);
	}
	
	public function last() {
		var sel = [];
		if( select.length > 1 )
			sel.push(select[select.length-1] );
		return new JQuery(root,sel);
	}
	
	public function next() {
		var sel = [];
		for ( s in select )
			if ( s.parentComponent != null ) {
				var idx = s.parentComponent.components.indexOf(s);
				if ( idx >= 0 ){
					var cand = s.parentComponent.components[idx + 1];
					if ( cand != null)
						sel.push(cand);
				}
			}
		return new JQuery(root,sel);
	}
	
	public function prev() {
		var sel = [];
		for ( s in select )
			if ( s.parentComponent != null ) {
				var idx = s.parentComponent.components.indexOf(s);
				if ( idx >= 1 )
					sel.push(s.parentComponent.components[idx - 1]);
			}
		return new JQuery(root,sel);
	}
	
	
	public function find( q : Dynamic ) {
		if( Std.is(q, Component) )
			return new JQuery(root, Lambda.has(select, q) ? null : q);
		else if( Std.is(q, String) ) {
			var q = parseQuery(q);
			var out = [];
			for( s in select )
				lookupRec(s, q, out);
			return new JQuery(root, out);
		}
		
		throw "Invalid JQuery " + q;
		return null;
	}
	
	public function filter( q : Dynamic ) {
		if( Std.is(q, Component) )
			return new JQuery(root, Lambda.has(select, q) ? null : q);
		if( Std.is(q, String) ) {
			var q = parseQuery(q);
			return new JQuery(root, [for( s in select ) if( matchQuery(q, s) ) s]);
		}
		if( Std.is(q, JQuery) ) {
			var q : JQuery = q;
			return  new JQuery(root, [for( s in select ) if( Lambda.has(q.select, s) ) s]);
		}
		throw "Invalid JQuery " + q;
		return null;
	}

	public function not( q : Dynamic ) {
		if( Std.is(q, Component) )
			return new JQuery(root, [for( s in select ) if( s != q ) s]);
		if( Std.is(q, String) ) {
			var q = parseQuery(q);
			return new JQuery(root, [for( s in select ) if( !matchQuery(q, s) ) s]);
		}
		if( Std.is(q, JQuery) ) {
			var q : JQuery = q;
			return  new JQuery(root, [for( s in select ) if( !Lambda.has(q.select, s) ) s]);
		}
		throw "Invalid JQuery " + q;
		return null;
	}
	
	public function click( f : JQuery -> Void ) {
		for( c in select ) {
			var int = Std.instance(c, Interactive);
			if( int == null ) throw c + " is not interactive";
			int.onClick = function() f(new JQuery(root,c));
		}
		return this;
	}
	
	public function show() {	
		for( s in select )
			s.getStyle(true).display = true;
		return this;
	}

	public function hide() {
		for( s in select )
			s.getStyle(true).display = false;
		return this;
	}
	
	public function remove() {
		for ( s in select )
			s.dispose();
		select = [];
		return this;
	}
	
	public function toggle() {
		for( s in select ) {
			var s = s.getStyle(true);
			s.display = !s.display;
		}
		return this;
	}
	
	public function children() {
		var sel = [];
		for ( s in select )
			for( c in s.components)
				sel.push(c);
		return new JQuery(root,sel);
	}

	/**
	 * dispose of inner content
	 */
	public function empty() {
		for ( s in select )
			for( c in s.components.copy())
				c.dispose();
		return this;
	}
	
	public inline function iterator() {
		var it = select.iterator();
		return {
			hasNext : it.hasNext,
			next : function() return new JQuery(root, it.next()),
		};
	}
	
	public function text(?d:Dynamic) {
		if ( d == null ) 
			return _get_text();
		else {
			_set_text( Std.string( d ) );
			return _get_text();
		}
	}

	function _get_val() : Dynamic {
		var c = select[0];
		if( c == null ) return null;
		return switch( c.name ) {
		case "slider":
			cast(c, h2d.comp.Slider).value;
		case "checkbox":
			cast(c, h2d.comp.Checkbox).checked;
		case "input":
			cast(c, h2d.comp.Input).value;
		case "color":
			cast(c, h2d.comp.Color).value;
		case "itemlist":
			cast(c, h2d.comp.ItemList).selected;
		case "select":
			cast(c, h2d.comp.Select).value;
		case "button":
			cast(c, h2d.comp.Button).text;
		default:
			null;
		}
	}

	public inline function val( ?v:Dynamic):Dynamic {
		return (v==null)?_get_val():_set_val(v);
	}
	
	function _set_val( v : Dynamic ) {
		for( c in select )
			switch( c.name ) {
			case "slider":
				cast(c, h2d.comp.Slider).value = v;
			case "checkbox":
				cast(c, h2d.comp.Checkbox).checked = v != null && v != false;
			case "input":
				cast(c, h2d.comp.Input).value = Std.string(v);
			case "color":
				cast(c, h2d.comp.Color).value = v;
			case "itemlist":
				cast(c, h2d.comp.ItemList).selected = v;
			case "select":
				cast(c, h2d.comp.Select).setValue(v);
			case "button":
			cast(c, h2d.comp.Button).text = v;
			default:
				null;
			}
		return this;
	}

	function _get_text() {
		var c = select[0];
		if( c == null ) return "";
		return switch( c.name ) {
		case "button":
			cast(c, h2d.comp.Button).text;
		case "label":
			cast(c, h2d.comp.Label).text;
		default:
			"";
		}
	}
	
	function _set_text(v:String) {
		for( c in select )
			switch( c.name ) {
			case "button":
				cast(c, h2d.comp.Button).text = v;
			case "label":
				cast(c, h2d.comp.Label).text = v;
			default:
			}
		return this;
	}
	
	
	function _set_style(v:String) {
		var s = new h2d.css.Style();
		new h2d.css.Parser().parse(v, s);
		for( c in select )
			c.addStyle(s);
		return this;
	}
	
	function getSet( query : Dynamic ) {
		var set;
		if( query == null )
			set = [];
		else if( Std.is(query,Component) )
			set = [query];
		else if( Std.is(query, Array) ) {
			var a : Array<Dynamic> = query;
			for( v in a ) if( !Std.is(v, Component) ) throw "Invalid JQuery "+query;
			set = a;
		} 
		else if ( Std.is(query, String) ) {
			var squery : String = cast query;
			if ( StringTools.startsWith( squery , "<")) {
				var comps = h2d.comp.Parser.fromHtml(squery, DEFAULT_API);
				var a :Array<Component>= [];
				for ( c in comps.getComponents() ) {
					c.remove();
					a.push(cast c);
				}
				set = a;
			}
			else 
				set = lookup(root, squery);
		}
		else
			throw "Invalid JQuery " + query;
			
		#if debug 
		if ( set == null )
			throw "assert null set";
		#end
		
		return set;
	}
	
	//???
	public function add( query : Dynamic ) {
		if ( Std.is( query, String)) {
			var squery : String = cast query;
			var src = new JQuery(null, squery );
			add( src );
		}
		else if ( Std.is( query, JQuery)) {
			var jquery : JQuery = cast query;
			for ( s in select ) 
				for ( c in jquery.getComponents() ) {
					var cl : Component = cast ( c.parent == null ? c : c.clone());
					cl.remove();
					s.addChild( cl );
				}
		}
		else if ( Std.is(query, Component) ) {
			var cquery : Component = cast query;
			for ( s in select ) {
				cquery.remove();
				s.addChild( cquery );
			}
		}
		return this;
	}
	
	public function append( query : Dynamic ) {
		if ( Std.is( query, String)) {
			var squery : String = cast query;
			var src = new JQuery(null, squery );
			append( src );
		}
		else if ( Std.is( query, JQuery)) {
			var jquery : JQuery = cast query;
			for ( s in select ) 
				for ( c in jquery.getComponents() ) {
					var cl : Component = cast c.clone();
					cl.remove();
					s.addChild( cl );
				}
		}
		return this;
	}
	
	
	function lookup( root : Component, query : String ) {
		var set = [];
		if ( root == null ) return set;
		
		if( query.lastIndexOf(",") < 0 )
			lookupRec(root, parseQuery(query), set);
		else {
			var queries = query.split(",");
			for( query in queries) 
				lookupRec(root, parseQuery(query), set);
		}
		return set;
	}
	
	function lookupParent( root : Component, query : String,stopAtFirst:Bool ) {
		var set = [];
		if ( root == null ) return set;
		
		if( query.lastIndexOf(",") < 0 )
			lookupParentRec(root, parseQuery(query), set,stopAtFirst);
		else {
			var queries = query.split(",");
			for( query in queries) 
				lookupParentRec(root, parseQuery(query), set,stopAtFirst);
		}
		return set;
	}
	
	function parseQuery(q) : Query {
		return new h2d.css.Parser().parseClasses(q);
	}
	
	function matchQuery(q:Query, comp:Component) {
		if( q!=null && comp != null)
		for( r in q )
			if( h2d.css.Engine.ruleMatch(r, comp) )
				return true;
		return false;
	}
	
	function lookupRec(comp:Component, q, set : Array<Component> ) {
		if( matchQuery(q, comp) )
			set.push(comp);
		for( s in comp.components )
			lookupRec(s, q, set);
	}
	
	function lookupParentRec(comp:Component, q, set : Array<Component>, stopAtfirst ) {
		if( matchQuery(q, comp) )
			set.push(comp);
		if ( stopAtfirst && set.length > 0)
			return;
			
		if( comp.parentComponent != null)
			lookupParentRec(comp.parentComponent, q, set,stopAtfirst);
	}
	
	//todo implements parents and closest with this 
	var markList : Map<Component,Bool>;
	function startLookupBothwaysRec( comp:Component, q, set : Array<Component> ) {
		markList = new Map();
		lookupBothwaysRec(comp, q, set);
	}
	
	function lookupBothwaysRec(comp:Component, q, set : Array<Component> ) {
		if ( markList.exists(comp)) return;
		markList.set( comp, true);
		if( matchQuery(q, comp) )
			set.push(comp);
		for( s in comp.components )
			lookupRec(s, q, set);
		if( comp.parentComponent != null)
			lookupParentRec(comp.parentComponent, q, set, false);
	}
	
	public function closest(q:Dynamic) {
		if( Std.is(q, Component) )
			return new JQuery(root, Lambda.has(select, q) ? null : q);
		else if( Std.is(q, String) ) {
			var q = parseQuery(q);
			var out = [];
			for( s in select )
				lookupParentRec(s, q, out,true);
			return new JQuery(root, out);
		}
		
		throw "Invalid JQuery " + q;
		return null;
	}
	
	function toString(){
		return 'JQuery (length='+select.length+') '+select.map(function(o) return "\n\t"+o.toString()).join("");
	}

	public function document() : JQuery {
		return new JQuery(root, root);
	}
	
	public function scrollTop() : JQuery {
		for( s in select) {
			var sc = Std.instance( s, h2d.comp.Scroll );
			if( sc != null)
				sc.scrollTop();
		}
		return this;
	}

}
