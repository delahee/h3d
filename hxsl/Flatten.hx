package hxsl;
using hxsl.Ast;

private class Alloc {
	public var t : VecType;
	public var pos : Int;
	public var size : Int;
	public var g : TVar;
	public var v : Null<TVar>;
	public function new(g, t, pos, size) {
		this.g = g;
		this.t = t;
		this.pos = pos;
		this.size = size;
	}
}

class Flatten {
	
	var globals : Array<TVar>;
	var params : Array<TVar>;
	var outVars : Array<TVar>;
	var varMap : Map<TVar,Alloc>;
	public var allocData : Map< TVar, Array<Alloc> >;
	
	public function new() {
	}
	
	public function flatten( s : ShaderData, kind : FunctionKind ) : ShaderData {
		globals = [];
		params = [];
		outVars = [];
		varMap = new Map();
		allocData = new Map();
		for( v in s.vars )
			gatherVar(v);
		var prefix = switch( kind ) {
		case Vertex: "vertex";
		case Fragment: "fragment";
		default: throw "assert";
		}
		pack(prefix + "Globals", Global, globals, VFloat);
		pack(prefix + "Params", Param, params, VFloat);
		packTextures(prefix + "Textures", globals.concat(params), TSampler2D);
		return {
			name : s.name,
			vars : outVars,
			funs : [for( f in s.funs ) {
				kind : f.kind,
				ret : f.ret,
				args : f.args,
				ref : f.ref,
				expr : mapExpr(f.expr),
			}],
		};
	}
	
	function mapExpr( e : TExpr ) : TExpr {
		e = switch( e.e ) {
		case TVar(v):
			var a = varMap.get(v);
			if( a == null )
				e
			else
				access(a, v.type, e.p);
		default:
			e.map(mapExpr);
		};
		return optimize(e);
	}
	
	function access( a : Alloc, t : Type, pos : Position ) : TExpr {
		inline function mkInt(v:Int) {
			return { e : TConst(CInt(v)), t : TInt, p : pos };
		}
		inline function read( index : Int ) : TExpr {
			return { e : TArray({ e : TVar(a.g), t : a.g.type, p : pos },mkInt((a.pos>>2)+index)), t : TVec(4,a.t), p : pos }
		}
		switch( t ) {
		case TMat4:
			return { e : TCall( { e : TGlobal(Mat4), t : TFun([]), p : pos }, [
				read(0),
				read(1),
				read(2),
				read(3),
			]), t : TMat4, p : pos }
		case TMat3x4:
			return { e : TCall( { e : TGlobal(Mat3x4), t : TFun([]), p : pos }, [
				read(0),
				read(1),
				read(2),
			]), t : TMat3x4, p : pos }
		case TArray(t, SConst(len)):
			var stride = Std.int(a.size / len);
			return { e : TArrayDecl([for( i in 0...len ) access(new Alloc(a.g, a.t, a.pos + stride * i, stride), t, pos)]), t : t, p : pos };
		case TSampler2D, TSamplerCube:
			return read(a.pos);
		default:
			var size = varSize(t, a.t);
			if( size <= 4 ) {
				var k = read(0);
				if( size == 4 ) {
					if( a.pos & 3 != 0 ) throw "assert";
					return k;
				} else {
					var sw = [];
					for( i in 0...size )
						sw.push(Tools.SWIZ[i + (a.pos & 3)]);
					return { e : TSwiz(k, sw), t : t, p : pos };
				}
			}
			return Error.t("Access not supported for " + t.toString(), null);
		}
	}

	
	function optimize( e : TExpr ) {
		switch( e.e ) {
		case TCall( { e : TGlobal(Mat3x4) }, [ { e : TCall( { e : TGlobal(Mat4) }, args) } ]):
			var rem = 0;
			var size = 0;
			while( size < 4 ) {
				var t = args[args.length - 1 - rem].t;
				size += varSize(t,VFloat);
				rem++;
			}
			if( size == 4 ) {
				for( i in 0...rem )
					args.pop();
				var emat = switch( e.e ) { case TCall(e, _): e; default: throw "assert"; };
				return { e : TCall(emat, args), t : e.t, p : e.p };
			}
		case TArray( { e : TArrayDecl(el) }, { e : TConst(CInt(i)) } ) if( i >= 0 && i < el.length ):
			return el[i];
		default:
		}
		return e;
	}
	
	function packTextures( name : String, vars : Array<TVar>, t : Type ) {
		var alloc = new Array<Alloc>();
		var g : TVar = {
			id : Tools.allocVarId(),
			name : name,
			type : t,
			kind : Param,
		};
		for( v in vars ) {
			if( v.type != t ) continue;
			var a = new Alloc(g, null, alloc.length, 1);
			a.v = v;
			varMap.set(v, a);
			alloc.push(a);
		}
		g.type = TArray(t, SConst(alloc.length));
		if( alloc.length > 0 ) {
			outVars.push(g);
			allocData.set(g, alloc);
		}
		return g;
	}
	
	function pack( name : String, kind : VarKind, vars : Array<TVar>, t : VecType ) {
		var alloc = new Array<Alloc>(), apos = 0;
		var g : TVar = {
			id : Tools.allocVarId(),
			name : name,
			type : TVec(0,t),
			kind : kind,
		};
		for( v in vars ) {
			switch( v.type ) {
			case TSampler2D, TSamplerCube:
				continue;
			default:
			}
			var size = varSize(v.type, t);
			var best : Alloc = null;
			for( a in alloc )
				if( a.v == null && a.size >= size && (best == null || best.size > a.size) )
					best = a;
			if( best != null ) {
				var free = best.size - size;
				if( free > 0 ) {
					var i = Lambda.indexOf(alloc, best);
					var a = new Alloc(g, t, best.pos + size, free);
					alloc.insert(i + 1, a);
					best.size = size;
				}
				best.v = v;
				varMap.set(v, best);
			} else {
				var a = new Alloc(g, t, apos, size);
				apos += size;
				a.v = v;
				varMap.set(v, a);
				alloc.push(a);
				var pad = (4 - (size % 4)) % 4;
				if( pad > 0 ) {
					var a = new Alloc(g, t, apos, pad);
					apos += pad;
					alloc.push(a);
				}
			}
		}
		g.type = TArray(TVec(4, t), SConst(apos >> 2));
		if( apos > 0 ) {
			outVars.push(g);
			allocData.set(g, alloc);
		}
		return g;
	}
	
	function varSize( v : Type, t : VecType ) {
		return switch( v ) {
		case TFloat if( t == VFloat ): 1;
		case TVec(n, t2) if( t == t2 ): n;
		case TMat4 if( t == VFloat ): 16;
		case TMat3x4 if( t == VFloat ): 12;
		case TMat3 if( t == VFloat ): 9;
		case TArray(at, SConst(n)):
			var s = varSize(at, t);
			s += (4 - (s & 3)) & 3;
			s * n;
		default:
			throw v.toString() + " size unknown for type " + t;
		}
	}
	
	function gatherVar( v : TVar ) {
		switch( v.type ) {
		case TStruct(vl):
			for( v in vl )
				gatherVar(v);
		default:
			switch( v.kind ) {
			case Global:
				if( v.hasQualifier(PerObject) )
					params.push(v);
				else
					globals.push(v);
			case Param:
				params.push(v);
			default:
				outVars.push(v);
			}
		}
	}
	
}