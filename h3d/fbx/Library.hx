package h3d.fbx;

import haxe.ds.Vector;
import hxd.Math;

import h3d.col.Point;

import hxd.System;

using h3d.fbx.Data;

enum AnimationMode {
	FrameAnim;
	LinearAnim;
}

private class AnimCurve {
	public var def : DefaultMatrixes;
	public var object : String;
	public var t : { t : Array<Float>, x : Array<Float>, y : Array<Float>, z : Array<Float> };
	public var r : { t : Array<Float>, x : Array<Float>, y : Array<Float>, z : Array<Float> };
	public var s : { t : Array<Float>, x : Array<Float>, y : Array<Float>, z : Array<Float> };
	public var a : { t : Array<Float>, v : Array<Float> };
	public var uv : Array<{ t : Float, u : Float, v : Float }>;
	public var shapes : Array<{ t:Array<Float>, v:Array<Float> }>;
	
	public function new(def:h3d.fbx.DefaultMatrixes, object:String) {
		this.def = def;
		this.object = object;
	}
}

class DefaultMatrixes {
	public var trans : Null<Point>;
	public var scale : Null<Point>;
	public var rotate : Null<Point>;
	public var preRot : Null<Point>;
	public var wasRemoved : Null<Int>;
	
	public function new() {
	}

	public static inline function rightHandToLeft( m : h3d.Matrix ) {
		// if [x,y,z] is our original point and M the matrix
		// in right hand we have [x,y,z] * M = [x',y',z']
		// we need to ensure that left hand matrix convey the x axis flip,
		// in order to have [-x,y,z] * M = [-x',y',z']
		m._12 *= -1;
		m._13 *= -1;
		m._21 *= -1;
		m._31 *= -1;
		m._41 *= -1;
	}
	
	public function toMatrix(leftHand) {
		var m = new h3d.Matrix();
		m.identity();
		if( scale != null ) m.scale(scale.x, scale.y, scale.z);
		if( rotate != null ) m.rotate(rotate.x, rotate.y, rotate.z);
		if( preRot != null ) m.rotate(preRot.x, preRot.y, preRot.z);
		if( trans != null ) m.translate(trans.x, trans.y, trans.z);
		if( leftHand ) rightHandToLeft(m);
		return m;
	}
	
}

class Library {

	var root : FbxNode;
	var ids : Map<Int,FbxNode>;
	var connect : Map<Int,Array<Int>>;
	var invConnect : Map<Int,Array<Int>>;
	var leftHand : Bool;
	var defaultModelMatrixes : Map<String,DefaultMatrixes>;
	
	var uvAnims : Map<String, Array<{ t : Float, u : Float, v : Float }>>;
	
	/**
		Allows to prevent some terminal unskinned joints to be removed, for instance if we want to track their position
	**/
	public var keepJoints : Map<String,Bool>;
	
	/**
		Allows to skip some objects from being processed as if they were not part of the FBX
	**/
	public var skipObjects : Map<String,Bool>;
	
	/**
		Set how many bones per vertex should be created in skin data in makeObject(). Default is 3
	**/
	public var bonesPerVertex = 3;
	
	/**
		If there are too many bones, the model will be split in separate render passes.
	**/
	public var maxBonesPerSkin = 34;
	
	/**
		Consider unskinned joints to be simple objects
	**/
	public var unskinnedJointsAsObjects : Bool;
	
	public var allowVertexColor : Bool = true;
	public static var detectBadVertices = false;
	
	public function new() {
		root = new FbxNode("Root", [], [] );
		keepJoints = new Map();
		skipObjects = new Map();
		reset();
	}
	
	function reset() {
		ids = new Map();
		connect = new Map();
		invConnect = new Map();
		defaultModelMatrixes = new Map();
	}
	
	public function loadTextFile( data : String ) {
		load(Parser.parse(data));
	}
	
	public function load( root : FbxNode ) {
		reset();
		this.root = root;
		for( c in root.childs )
			init(c);
	}
	
	function convertPoints( a : Array<Float> ) {
		var p = 0;
		for( i in 0...Std.int(a.length / 3) ) {
			a[p] = -a[p]; // inverse X axis
			p += 3;
		}
	}
	
	public function leftHandConvert() {
		if( leftHand ) return;
		leftHand = true;
		for( g in root.getAll("Objects.Geometry") ) {
			for( v in g.getAll("Vertices") )
				convertPoints(v.getFloats());
			for( v in g.getAll("LayerElementNormal.Normals") )
				convertPoints(v.getFloats());
		}
	}
	
	function init( n : FbxNode ) {
		switch( n.name ) {
		case "Connections":
			for( c in n.childs ) {
				if( c.name != "C" )
					continue;
				var child = c.props[1].toInt();
				var parent = c.props[2].toInt();
				
				var c = connect.get(parent);
				if( c == null ) {
					c = [];
					connect.set(parent, c);
				}
				c.push(child);

				if( parent == 0 )
					continue;
								
				var c = invConnect.get(child);
				if( c == null ) {
					c = [];
					invConnect.set(child, c);
				}
				c.push(parent);
			}
		case "Objects":
			for( c in n.childs )
				ids.set(c.getId(), c);
		default:
		}
	}
	
	public function getGeometry( name : String = "" ) : Geometry {
		var geom = null;
		for( g in root.getAll("Objects.Geometry") )
			if( g.hasProp(PString("Geometry::" + name)) ) {
				geom = g;
				break;
			}
		if( geom == null )
			throw "Geometry " + name + " not found";
		return new Geometry(this, geom);
	}

	public function collectByName(nodeName:String) {
		var r = [];
		for ( n in ids ) {
			if ( n.name == nodeName )
				r.push(n);
		}
		return r;
	}
	
	//TODO optimize this
	public function getParent( node : FbxNode, nodeName : String, ?opt : Bool )  : FbxNode{
		var p = getParents(node, nodeName);
		if( p.length > 1 )
			throw node.getName() + " has " + p.length + " " + nodeName + " parents";
		if ( p.length == 0 && !opt ) {
			var allParents = getParents(node);
			var hierarch = dumpParents(node);
			
			throw "Missing " + node.getName() + " " + nodeName + " parent among "+allParents+".";//no parent, maybe a bone with no parent ? 
		}
		return p[0];
	}

	public function hasChild( node : FbxNode, nodeName : String)  : Bool{
		var c = connect.get(node.getId());
		if( c != null )
			for( id in c ) {
				var n = ids.get(id);
				if( n == null ) throw id + " not found";
				if ( nodeName != null && n.name != nodeName ) 
					continue;
				return true;
			}
		
		return false;
	}
	
	public function getChild( node : FbxNode, nodeName : String, ?opt : Bool )  : FbxNode {
		var c = connect.get(node.getId());
		if( c != null )
			for( id in c ) {
				var n = ids.get(id);
				if( n == null ) throw id + " not found";
				if ( nodeName != null && n.name != nodeName )
					continue;
				return n;
			}
		throw "Missing " + node.getName() + " " + nodeName + " child";
	}
	
	public function getChilds( node : FbxNode, ?nodeName : String ) : Array<FbxNode>{
		var c = connect.get(node.getId());
		var subs = [];
		if( c != null )
			for( id in c ) {
				var n = ids.get(id);
				if( n == null ) throw id + " not found";
				if ( nodeName != null && n.name != nodeName )					
					continue;
				subs.push(n);
			}
		return subs;
	}

	
	public function dumpParents(node : FbxNode, ?rep:Array<{depth:Int,n:FbxNode}> = null,?depth=0 ) {
		if ( rep == null ) rep = [];
		var ns = getParents(node);
		for ( n in ns ) {
			rep.push( { depth:depth + 1, n : n } );
			dumpParents(n, rep,depth+1);
		}
		return rep;
	}
	
	public function dumpChildren<T>(node : FbxNode, proc : FbxNode->T, ?rep:Array<{depth:Int,n:T}> = null,?depth=0 ) {
		if ( rep == null ) rep = [];
		var ns = getChilds(node);
		for ( n in ns ) {
			rep.push( { depth:depth + 1, n : proc(n) } );
			dumpChildren(n, proc,rep,depth+1);
		}
		return rep;
	}
	
	public function getParents( node : FbxNode, ?nodeName : String ) {
		var id = node.getId();
		var c = invConnect.get(id);
		var pl = [];
		if( c != null )
			for( id in c ) {
				var n = ids.get(id);
				if( n == null ) throw id + " not found";
				if ( nodeName != null && n.name != nodeName ) {
					continue;
				}
				pl.push(n);
			}
			
		return pl;
	}
	
	public function getRoot() {
		return root;
	}
	
	public function ignoreMissingObject( name : String ) {
		var def = defaultModelMatrixes.get(name);
		if( def == null ) {
			def = new DefaultMatrixes();
			def.wasRemoved = -1;
			defaultModelMatrixes.set(name, def);
		}
	}

	function getObjectCurve( curves : Map < Int, AnimCurve > , model : FbxNode, curveName : String, animName : String ) : AnimCurve {
		var c = curves.get(model.getId());
		if( c != null )
			return c;
		var name = model.getName();
		if( skipObjects.get(name) )
			return null;
		// if it's an empty model with no sub nodes, let's ignore it (ex : Camera)
		if( model.getType() == "Null" && getChilds(model, "Model").length == 0 )
			return null;
		var def = defaultModelMatrixes.get(name);
		if( def == null )
			throw "Object curve "+name+" used in anim "+animName+" was not found in library";
		// if it's a move animation on a terminal unskinned joint, let's skip it
		if( def.wasRemoved != null ) {
			if( curveName != "Visibility" && curveName != "UV" ){
				return null;
			}
			// apply it on the skin instead
			model = ids.get(def.wasRemoved);
			name = model.getName();
			c = curves.get(def.wasRemoved);
			def = defaultModelMatrixes.get(name);
			// todo : change behavior not to remove the mesh but the skin instead!
			if( def == null ) throw "assert";
		}
		if ( c == null ) {
			c = new AnimCurve(def, name);
			curves.set(model.getId(), c);
		}
		return c;
	}
	
	public function loadAnimation( mode : AnimationMode, ?animName : String, ?root : FbxNode, ?lib : Library ) : h3d.anim.Animation {
		if( lib != null ) {
			lib.defaultModelMatrixes = defaultModelMatrixes;
			return lib.loadAnimation(mode,animName);
		}
		if( root != null ) {
			var l = new Library();
			l.load(root);
			if( leftHand ) l.leftHandConvert();
			l.defaultModelMatrixes = defaultModelMatrixes;
			return l.loadAnimation(mode,animName);
		}
		var animNode = null;
		for( a in this.root.getAll("Objects.AnimationStack") )
			if( animName == null || a.getName()	== animName ) {
				if( animName == null )
					animName = a.getName();
				animNode = getChild(a, "AnimationLayer");
				break;
			}
		if( animNode == null ) {
			if( animName != null )
				throw "Animation not found " + animName;
			if( uvAnims == null )
				return null;
		}

		var curves = new Map();
		var P0 = new Point();
		var P1 = new Point(1, 1, 1);
		var F = Math.PI / 180;
		var allTimes = new Map();

		if ( animNode != null ) 
		for ( cn in getChilds(animNode, "AnimationCurveNode") ) {
			
			var model = getParent(cn, "Model", true);
			if ( model == null) continue;
			
			var c = getObjectCurve(curves, model, cn.getName(), animName);
			if( c == null ) continue;
			var data = getChilds(cn, "AnimationCurve");
			if( data == null ) continue;
			if( data[0] == null ) continue;
			if( data[0].get("KeyTime") == null ) continue;
			
			var cname = cn.getName();
			// collect all the timestamps
			var times = data[0].get("KeyTime").getFloats();
			for( i in 0...times.length ) {
				var t = times[i];
				// fix rounding error
				if( t % 100 != 0 ) {
					t += 100 - (t % 100);
					times[i] = t;
				}
				// this should give significant-enough key
				var it = Std.int(t / 200000);
				allTimes.set(it, t);
			}
			// handle special curves
			if( data.length != 3 ) {
				switch( cname ) {
				case "Visibility":
					c.a = {
						v : data[0].get("KeyValueFloat").getFloats(),
						t : times,
					};
					continue;
				default:
				}
				throw model.getName()+"."+cname + " has " + data.length + " curves";
			}
			// handle TRS curves
			var data = {
				x : data[0].get("KeyValueFloat").getFloats(),
				y : data[1].get("KeyValueFloat").getFloats(),
				z : data[2].get("KeyValueFloat").getFloats(),
				t : times,
			};
			// this can happen when resampling anims due to rounding errors, let's ignore it for now
			//if( data.y.length != times.length || data.z.length != times.length )
			//	throw "Unsynchronized curve components on " + model.getName()+"."+cname+" (" + data.x.length + "/" + data.y.length + "/" + data.z.length + ")";
			// optimize empty animations out
			var E = 1e-10, M = 1.0;
			var def = switch( cname ) {
			case "T": if( c.def.trans == null ) P0 else c.def.trans;
			case "R": M = F; if( c.def.rotate == null ) P0 else c.def.rotate;
			case "S": if( c.def.scale == null ) P1 else c.def.scale;
			default:
				throw "Unknown curve " + model.getName()+"."+cname;
			}
			var hasValue = false;
			for( v in data.x )
				if( v*M < def.x-E || v*M > def.x+E ) {
					hasValue = true;
					break;
				}
			if( !hasValue ) {
				for( v in data.y )
					if( v*M < def.y-E || v*M > def.y+E ) {
						hasValue = true;
						break;
					}
			}
			if( !hasValue ) {
				for( v in data.z )
					if( v*M < def.z-E || v*M > def.z+E ) {
						hasValue = true;
						break;
					}
			}
			// no meaningful value found
			if( !hasValue )
				continue;
			switch( cname ) {
			case "T": c.t = data;
			case "R": c.r = data;
			case "S": c.s = data;
			default: throw "assert";
			}
		}

		// process UVs
		if( uvAnims != null ) {
			var modelByName = new Map();
			for( obj in this.root.getAll("Objects.Model") )
				modelByName.set(obj.getName(), obj);
			for( obj in uvAnims.keys() ) {
				var frames = uvAnims.get(obj);
				var model = modelByName.get(obj);
				if( model == null ) throw "Missing model '" + obj + "' requires by UV animation";
				var c = getObjectCurve(curves, model, "UV", animName);
				if( c == null ) continue;
				c.uv = frames;
				for( f in frames )
					allTimes.set(Std.int(f.t / 200000), f.t);
			}
		}
		
		//trace("searching morphs");
		//process morphs 
		var cns :Array<FbxNode> =  getChilds(animNode, "AnimationCurveNode");
		cns = cns.filter(function(n) {
			return n.getStringProp(1) == "AnimCurveNode::DeformPercent";
		});
		var nbShapes = 0;
		for ( cn in cns ) {
			//trace("found a shape curve !");
			var animCurve : FbxNode = getChild(cn,"AnimationCurve");
			var tm :Array<Float> = animCurve.get("KeyTime").getFloats();
			for( i in 0...tm.length ) {
				var t = tm[i];
				if( t % 100 != 0 ) {
					t += 100 - (t % 100);
					tm[i] = t;
				}
				var it = Std.int(t / 200000);
				allTimes.set(it, t);
			}
			var g = getParent(cn, "Deformer");
			var model = getParent(g, "Deformer");
			model = getParent(model, "Geometry");
			model = getParent(model, "Model");
			var name = model.getName();
			var c = curves.get( model.getId() );
			if ( c == null) 
				curves.set( model.getId(), c = new AnimCurve(defaultModelMatrixes.get(name), name));
			if (c.shapes == null) c.shapes = [];
			c.shapes.push( {t:tm, v:animCurve.get("KeyValueFloat").getFloats()} );
			//times per shapes
			nbShapes++;
		}
		
		var allTimes = [for( a in allTimes ) a];
		allTimes.sort(sortDistinctFloats);
		var maxTime = allTimes[allTimes.length - 1];
		var minDT = maxTime;
		var curT = allTimes[0];
		for( i in 1...allTimes.length ) {
			var t = allTimes[i];
			var dt = t - curT;
			if( dt < minDT ) minDT = dt;
			curT = t;
		}
		var numFrames = maxTime == 0 ? 1 : 1 + Std.int((maxTime - allTimes[0]) / minDT);
		var sampling = 15.0 / (minDT / 3079077200); // this is the DT value we get from Max when using 15 FPS export

		switch( mode ) {
		case FrameAnim:
			var anim = new h3d.anim.FrameAnimation(animName, numFrames, sampling);

			for( c in curves ) {
				var frames = c.t == null && c.r == null && c.s == null ? null : new haxe.ds.Vector(numFrames);
				var alpha = c.a == null ? null : new haxe.ds.Vector(numFrames);
				var uvs = c.uv == null ? null : new haxe.ds.Vector(numFrames * 2);
				var shapes = c.shapes == null ? null : new haxe.ds.Vector( numFrames * nbShapes);
				// skip empty curves
				if( frames == null && alpha == null && uvs == null && shapes == null)
					continue;
				var ctx = c.t == null ? null : c.t.x;
				var cty = c.t == null ? null : c.t.y;
				var ctz = c.t == null ? null : c.t.z;
				var ctt = c.t == null ? [-1.] : c.t.t;
				var crx = c.r == null ? null : c.r.x;
				var cry = c.r == null ? null : c.r.y;
				var crz = c.r == null ? null : c.r.z;
				var crt = c.r == null ? [-1.] : c.r.t;
				var csx = c.s == null ? null : c.s.x;
				var csy = c.s == null ? null : c.s.y;
				var csz = c.s == null ? null : c.s.z;
				var cst = c.s == null ? [ -1.] : c.s.t;
				var cav = c.a == null ? null : c.a.v;
				var cat = c.a == null ? null : c.a.t;
				var cuv = c.uv;
				var def = c.def;
				var curShapes :Array<Int>= [];
				for ( i in 0...nbShapes )
					curShapes.push( 0 );
				
				var tp = 0, rp = 0, sp = 0, ap = 0, uvp = 0;
				var curMat = null;
				for( f in 0...numFrames ) {
					var changed = curMat == null;
					if( allTimes[f] == ctt[tp] ) {
						changed = true;
						tp++;
					}
					if( allTimes[f] == crt[rp] ) {
						changed = true;
						rp++;
					}
					if( allTimes[f] == cst[sp] ) {
						changed = true;
						sp++;
					}
					if( changed ) {
						var m = new h3d.Matrix();
						m.identity();
						if( c.s == null || sp == 0 ) {
							if( def.scale != null )
								m.scale(def.scale.x, def.scale.y, def.scale.z);
						} else
							m.scale(csx[sp-1], csy[sp-1], csz[sp-1]);

						if( c.r == null || rp == 0 ) {
							if( def.rotate != null )
								m.rotate(def.rotate.x, def.rotate.y, def.rotate.z);
						} else
							m.rotate(crx[rp-1] * F, cry[rp-1] * F, crz[rp-1] * F);

						if( def.preRot != null )
							m.rotate(def.preRot.x, def.preRot.y, def.preRot.z);

						if( c.t == null || tp == 0 ) {
							if( def.trans != null )
								m.translate(def.trans.x, def.trans.y, def.trans.z);
						} else
							m.translate(ctx[tp-1], cty[tp-1], ctz[tp-1]);

						if( leftHand )
							DefaultMatrixes.rightHandToLeft(m);

						curMat = m;
					}
					if( frames != null )
						frames[f] = curMat;
					if( alpha != null ) {
						if( allTimes[f] == cat[ap] )
							ap++;
						alpha[f] = cav[ap - 1];
					}
					if( uvs != null ) {
						if( allTimes[f] == cuv[uvp].t )
							uvp++;
						uvs[f<<1] = cuv[uvp - 1].u;
						uvs[(f<<1)|1] = cuv[uvp - 1].v;
					}
					if ( shapes != null ) {
						var inv100 : Float= 1.0 / 100.0;
						for ( si in 0...nbShapes) {
							var curPos : Int = curShapes[si];
							if ( curPos >= c.shapes[si].v.length)
								curPos = c.shapes[si].v.length - 1;
							
							var v : Float = c.shapes[si].v[curPos];
							if ( f < numFrames - 1 ) {
								var prevPos : Int = curPos - 1;
								var curTime = c.shapes[si].t[curPos];
								var frameTime = allTimes[f];
								if ( prevPos >= 0 ) {
									var vprev : Float = c.shapes[si].v[prevPos];
									var diff = curTime - frameTime;
									if( diff > 0 && curPos > 0){
										var wide = c.shapes[si].t[curPos] - c.shapes[si].t[prevPos];
										var r = 1.0 - diff / wide;
										
										v = hxd.Math.lerp( vprev,v,r); 
									}
								}
							}
							
							shapes[ f * nbShapes + si ] = v * inv100;
							if ( allTimes[f] >= c.shapes[si].t[curShapes[si]] )
								curShapes[si]++;								
						}
					}
				}
				/*
				#if debug
				for ( i in 0...nbShapes ) {
					trace("shapeChannel:"+i);	
					for ( f in 0...numFrames) 
						trace( "fr:"+f+ " value:"+ shapes[f * nbShapes + i]);
				}
				#end
				*/

				if( frames != null )
					anim.addCurve(c.object, frames);
				if( alpha != null )
					anim.addAlphaCurve(c.object, alpha);
				if( uvs != null )
					anim.addUVCurve(c.object, uvs);
				if ( shapes != null ) 
					anim.addShapes(c.object, shapes,nbShapes );
			}
			return anim;

		case LinearAnim:

			var anim = new h3d.anim.LinearAnimation(animName, numFrames, sampling);
			var q = new h3d.Quat(), q2 = new h3d.Quat();

			for( c in curves ) {
				var frames = c.t == null && c.r == null && c.s == null ? null : new haxe.ds.Vector(numFrames);
				var alpha = c.a == null ? null : new haxe.ds.Vector(numFrames);
				var uvs = c.uv == null ? null : new haxe.ds.Vector(numFrames * 2);
				var shapes = c.shapes == null ? null : new haxe.ds.Vector( numFrames*nbShapes );
				
				// skip empty curves
				if( frames == null && alpha == null && uvs == null && shapes == null)
					continue;
				var ctx = c.t == null ? null : c.t.x;
				var cty = c.t == null ? null : c.t.y;
				var ctz = c.t == null ? null : c.t.z;
				var ctt = c.t == null ? [-1.] : c.t.t;
				var crx = c.r == null ? null : c.r.x;
				var cry = c.r == null ? null : c.r.y;
				var crz = c.r == null ? null : c.r.z;
				var crt = c.r == null ? [-1.] : c.r.t;
				var csx = c.s == null ? null : c.s.x;
				var csy = c.s == null ? null : c.s.y;
				var csz = c.s == null ? null : c.s.z;
				var cst = c.s == null ? [ -1.] : c.s.t;
				var cav = c.a == null ? null : c.a.v;
				var cat = c.a == null ? null : c.a.t;
				var cuv = c.uv;
				var def = c.def;
				var tp = 0, rp = 0, sp = 0, ap = 0, uvp = 0;
				var curFrame = null;
				var curShapes :Array<Int>= [];
				for ( i in 0...nbShapes )
					curShapes.push( 0 );
				for( f in 0...numFrames ) {
					var changed = curFrame == null;
					if( allTimes[f] == ctt[tp] ) {
						changed = true;
						tp++;
					}
					if( allTimes[f] == crt[rp] ) {
						changed = true;
						rp++;
					}
					if( allTimes[f] == cst[sp] ) {
						changed = true;
						sp++;
					}
					if( changed ) {
						var f = new h3d.anim.LinearAnimation.LinearFrame();
						if( c.s == null || sp == 0 ) {
							if( def.scale != null ) {
								f.sx = def.scale.x;
								f.sy = def.scale.y;
								f.sz = def.scale.z;
							} else {
								f.sx = 1;
								f.sy = 1;
								f.sx = 1;
							}
						} else {
							f.sx = csx[sp - 1];
							f.sy = csy[sp - 1];
							f.sz = csz[sp - 1];
						}

						if( c.r == null || rp == 0 ) {
							if( def.rotate != null ) {
								q.initRotate(def.rotate.x, def.rotate.y, def.rotate.z);
							} else
								q.identity();
						} else
							q.initRotate(crx[rp-1] * F, cry[rp-1] * F, crz[rp-1] * F);

						if( def.preRot != null ) {
							q2.initRotate(def.preRot.x, def.preRot.y, def.preRot.z);
							q.multiply(q,q2);
						}

						f.qx = q.x;
						f.qy = q.y;
						f.qz = q.z;
						f.qw = q.w;

						if( c.t == null || tp == 0 ) {
							if( def.trans != null ) {
								f.tx = def.trans.x;
								f.ty = def.trans.y;
								f.tz = def.trans.z;
							} else {
								f.tx = 0;
								f.ty = 0;
								f.tz = 0;
							}
						} else {
							f.tx = ctx[tp - 1];
							f.ty = cty[tp - 1];
							f.tz = ctz[tp - 1];
						}

						if( leftHand ) {
							f.tx *= -1;
							f.qy *= -1;
							f.qz *= -1;
						}

						curFrame = f;
					}
					if( frames != null )
						frames[f] = curFrame;
					if( alpha != null ) {
						if( allTimes[f] == cat[ap] )
							ap++;
						alpha[f] = cav[ap - 1];
					}
					if( uvs != null ) {
						if( uvp < cuv.length && allTimes[f] == cuv[uvp].t )
							uvp++;
						uvs[f<<1] = cuv[uvp - 1].u;
						uvs[(f<<1)|1] = cuv[uvp - 1].v;
					}
					
					if ( shapes != null ) {
						var inv100 : Float= 1.0 / 100.0;
						for ( si in 0...nbShapes) {
							var curPos : Int = curShapes[si];
							if ( curPos >= c.shapes[si].v.length)
								curPos = c.shapes[si].v.length - 1;
							
							var v : Float = c.shapes[si].v[curPos];
							if ( f < numFrames - 1 ) {
								var prevPos : Int = curPos - 1;
								var curTime = c.shapes[si].t[curPos];
								var frameTime = allTimes[f];
								if ( prevPos >= 0 ) {
									var vprev : Float = c.shapes[si].v[prevPos];
									var diff = curTime - frameTime;
									if( diff > 0 && curPos > 0){
										var wide = c.shapes[si].t[curPos] - c.shapes[si].t[prevPos];
										var r = 1.0 - diff / wide;
										
										v = hxd.Math.lerp( vprev,v,r); 
									}
								}
							}
							
							shapes[ f * nbShapes + si ] = v * inv100;
							if ( allTimes[f] >= c.shapes[si].t[curShapes[si]] )
								curShapes[si]++;								
						}
					}
				}
				
				/*
				#if debug
				for ( i in 0...nbShapes ) {
					trace("shapeChannel:"+i);	
					for ( f in 0...numFrames) 
						trace( "fr:"+f+ " value:"+ shapes[f * nbShapes + i]);
				}
				#end
				*/

				if( frames != null )
					anim.addCurve(c.object, frames, c.r != null || def.rotate != null, c.s != null || def.scale != null);
				if( alpha != null )
					anim.addAlphaCurve(c.object, alpha);
				if( uvs != null )
					anim.addUVCurve(c.object, uvs);
				if( shapes != null )
					anim.addShapesCurve(c.object, shapes, nbShapes );
			}
			return anim;

		}
	}
	
	public inline function getTakes(){
		return root.getAll("Takes.Take");
	}
	
	function isNullJoint( model : FbxNode ) {
		if( getParent(model, "Deformer", true) != null )
			return false;
		var parent = getParent(model, "Model", true);
		if( parent == null )
			return true;
		var t = parent.getType();
		if( t == "LimbNode" || t == "Root" )
			return false;
		return true;
	}

	function sortDistinctFloats( a : Float, b : Float ) {
		return if( a > b ) 1 else -1;
	}

	public function prepareObject( prepareTexture : String -> FbxNode -> Void ){
		// create all models
		for( model in root.getAll("Objects.Model") ) {
			var name = model.getName();
			if( skipObjects.get(name) )
				continue;
			var mtype = model.getType();
			switch( mtype ) {
			case "Mesh":
				// load materials
				var mats = getChilds(model, "Material");
				for( mat in mats ) {
					var tex = getChilds(mat, "Texture")[0];
					if( tex == null )
						continue;
					var path = tex.get("RelativeFilename").props[0].toString();
					prepareTexture(path,mat);
				}
			}
		}
	}

	/**
	 * @param	?textureLoader function to proxy texture loading
	 * @param	dynamicVertices = false params to tell whether vertices maybe modified during runtime
	 */
	@:noDebug
	public function makeObject( ?textureLoader : String -> FbxNode -> h3d.mat.MeshMaterial, dynamicVertices = false ) : h3d.scene.Object {
		var scene = new h3d.scene.Object();
		scene.name = "FbxLibrary Object";
		var hobjects = new Map();
		var hgeom = new Map();
		var objects = new Array();
		var hjoints = new Map();
		var joints = new Array();
		var hskins = new Map();
		
		if ( textureLoader == null ) {
			#if !cli_tools
			var tmpTex = null;
			textureLoader = function(_, _) {
				if( tmpTex == null )
					tmpTex = h3d.mat.Texture.fromColor(0xFFFF00FF);
				return new h3d.mat.MeshMaterial(tmpTex);
			}
			#end
		}
		
		// create all models
		for( model in root.getAll("Objects.Model") ) {
			var o : h3d.scene.Object;
			var name = model.getName();
			if( skipObjects.get(name) )
				continue;
			var mtype = model.getType();
			if( unskinnedJointsAsObjects && mtype == "LimbNode" && isNullJoint(model) )
				mtype = "Null";
			switch( mtype ) {
			case "Null", "Root", "Camera":
				var hasJoint = false;
				for( c in getChilds(model, "Model") )
					if( c.getType() == "LimbNode" ) {
						if( unskinnedJointsAsObjects && isNullJoint(c) ) continue;
						hasJoint = true;
						break;
					}
				if( hasJoint )
					o = new h3d.scene.Skin(null, null, scene);
				else
					o = new h3d.scene.Object(scene);
			case "LimbNode":
				var j = new h3d.anim.Skin.Joint();
				getDefaultMatrixes(model); // store for later usage in animation
				j.index = model.getId();
				j.name = model.getName();
				hjoints.set(j.index, j);
				joints.push({ model : model, joint : j });
				continue;
			case "Mesh":
				// load geometry
				var g = getChild(model, "Geometry");
				var prim = hgeom.get(g.getId());
				if( prim == null ) {
					prim = new h3d.prim.FBXModel(new Geometry(this, g));
					hgeom.set(g.getId(), prim);
				}
				// load materials
				var mats = getChilds(model, "Material");
				var tmats = [];
				var vcolor = prim.geom.getColors() != null;
				var lastAdded = 0;
				for( mat in mats ) {
					var tex = getChilds(mat, "Texture")[0];
					if( tex == null ) {
						tmats.push(null);
						continue;
					}
					var path = tex.get("RelativeFilename").props[0].toString();
					var mat = textureLoader(path,mat);
					if ( vcolor ) {
						hxd.System.trace3('detected vertex color');
						mat.hasVertexColor = true;
					}
					if ( mat == null ) {
						hxd.System.trace3("null mat detected");
						trace("Cannot load : "+path);
					}
					tmats.push(mat);
					lastAdded = tmats.length;
				}
				
				while( tmats.length > lastAdded )
					tmats.pop();
				
				function defaultMat()
				{
					#if cli_tools
					return null;
					#end
					return new h3d.mat.MeshMaterial(h2d.Tile.fromColor(0xFFFF00FF).getTexture());
				}
				
				if( tmats.length == 0 )
					tmats.push(defaultMat());
				
				//replace null materials by pink 
				var i = 0;
				for ( tm in tmats) {
					if ( tm == null ) 
						tmats[i] = defaultMat();
					i++;
				}
					
				// create object
				if( tmats.length == 1 )
					o = new h3d.scene.Mesh(prim, tmats[0], scene);
				else {
					prim.multiMaterial = true;
					o = new h3d.scene.MultiMaterial(prim, tmats, scene);
				}
				
				if( hasChild(g,"Deformer")){
					
					var blendShapes = getChilds(g, "Deformer").filter(function(n) return n.getType() == "BlendShape");
					if ( blendShapes.length > 1) throw "unsupported multiple morph for now";
					
					var blendShape = blendShapes[0];
					if( blendShape !=null)
						for ( bs in getChilds(blendShape) ) 
							prim.blendShapes.push( new h3d.fbx.Geometry( this, getChild(bs, "Geometry")) );
				}
				case type:
					throw "Unknown model type " + type+" for "+model.getName();
			}
			o.name = name;
			var m = getDefaultMatrixes(model);
			if( m.trans != null || m.rotate != null || m.scale != null || m.preRot != null )
				o.defaultTransform = m.toMatrix(leftHand);
			hobjects.set(model.getId(), o);
			objects.push( { model : model, obj : o } );
		}
		// rebuild joints hierarchy
		for( j in joints ) {
			var p = getParent(j.model, "Model");//if crash here, then you MUST ensure there is a dummy between scene top and you
			var jparent = hjoints.get(p.getId());
			if( jparent != null ) {
				jparent.subs.push(j.joint);
				j.joint.parent = jparent;
			} else if( p.getType() != "Root" && p.getType() != "Null" )
				throw "Parent joint not found " + p.getName();
		}
		// rebuild model hierarchy and additional inits
		for ( o in objects ) {
			
			var rootJoints = [];
			for( sub in getChilds(o.model, "Model") ) {
				var sobj = hobjects.get(sub.getId());
				if( sobj == null ) {
					if( sub.getType() == "LimbNode" ) {
						var j = hjoints.get(sub.getId());
						if( j == null ) throw "Missing sub joint " + sub.getName();
						rootJoints.push(j);
						continue;
					}
					throw "Missing sub " + sub.getName();
				}
				o.obj.addChild(sobj);
			}
			if( rootJoints.length != 0 ) {
				if( !Std.is(o.obj,h3d.scene.Skin) )
					throw o.obj.name + ":" + o.model.getType() + " should be a skin";
				var skin : h3d.scene.Skin = cast o.obj;
				var skinData = createSkin(hskins, hgeom, rootJoints, bonesPerVertex);
				
				if( skinData!=null){
					System.trace3("generating skin");
					
					// if we have a skinned object, remove it (only keep the skin) and set the material
					for( osub in objects ) {
						if( !osub.obj.isMesh() ) continue;
						var m = osub.obj.toMesh();
						if( m.primitive != skinData.primitive || m == skin )
							continue;
						skin.material = m.material;
						m.remove();
						// ignore key frames for this object
						defaultModelMatrixes.get(osub.obj.name).wasRemoved = o.model.getId();
					}
					// set the skin data
					if ( skinData.boundJoints.length > maxBonesPerSkin ) {
						if ( System.debugLevel >= 1 ) throw "too many joints by skin";
						skinData.split(maxBonesPerSkin, Std.instance(skinData.primitive, h3d.prim.FBXModel).geom.getIndexes().vidx);
					}
					skin.setSkinData(skinData);
				}
			}
		}
		return scene.numChildren == 1 ? scene.getChildAt(0) : scene;
	}
	
	function keepJoint( j : h3d.anim.Skin.Joint ) {
		return keepJoints.get(j.name);
	}
	
	@:noDebug
	function createSkin( hskins : Map<Int,h3d.anim.Skin>, hgeom : Map<Int,h3d.prim.FBXModel>, rootJoints : Array<h3d.anim.Skin.Joint>, bonesPerVertex ) {
		var allJoints = [];
		function collectJoints(j:h3d.anim.Skin.Joint) {
			// collect subs first (allow easy removal of terminal unskinned joints)
			for( j in j.subs )
				collectJoints(cast j);
			allJoints.push(j);
		}
		for( j in rootJoints )
			collectJoints(j);
		var skin = null;
		var geomTrans = null;
		var iterJoints = allJoints.copy();
		for( j in iterJoints ) {
			var jModel = ids.get(j.index);
			var subDef = getParent(jModel, "Deformer", true);
			var defMat = defaultModelMatrixes.get(jModel.getName());
			if( subDef == null ) {
				// if we have skinned subs, we need to keep in joint hierarchy
				if( j.subs.length > 0 || keepJoint(j) )
					continue;
				// otherwise we're an ending bone, we can safely be removed
				if( j.parent == null )
					rootJoints.remove(j);
				else
					j.parent.subs.remove(j);
				allJoints.remove(j);
				// ignore key frames for this joint
				defMat.wasRemoved = -1;
				continue;
			}
			// create skin
			if( skin == null ) {
				var def = getParent(subDef, "Deformer");
				skin = hskins.get(def.getId());
				// shared skin between same instances
				if( skin != null )
					return skin;
				var geom = hgeom.get(getParent(def, "Geometry").getId());
				skin = new h3d.anim.Skin(geom.getVerticesCount(), bonesPerVertex);
				geom.skin = skin;
				skin.primitive = geom;
				hskins.set(def.getId(), skin);
			}
			j.transPos = h3d.Matrix.L(subDef.get("Transform").getFloats());
			j.defMat = defMat.toMatrix(leftHand);
			if( leftHand ) DefaultMatrixes.rightHandToLeft(j.transPos);
			
			var weights = subDef.getAll("Weights");
			if( weights.length > 0 ) {
				var weights = weights[0].getFloats();
				var vertex = subDef.get("Indexes").getInts();
				for( i in 0...vertex.length ) {
					var w = weights[i];
					if ( w < 0.01 ) {
						#if !prod
						if ( detectBadVertices && w > 0.0) {
							hxd.System.trace1('vertex ${vertex[i]} has too little weight ( $w ) on bone ${j.name}');
						}
						#end
						continue;
					}
					skin.addInfluence(vertex[i], j, w);
				}
			}
		}
		if( skin == null ){
			hxd.System.trace1("No joint is skinned (" + [for ( j in iterJoints ) j.name].join(",") + ")");
			return null;
		}
		allJoints.reverse();
		for( i in 0...allJoints.length )
			allJoints[i].index = i;
		skin.setJoints(allJoints, rootJoints);
		skin.initWeights();
		return skin;
	}
	
	function getDefaultMatrixes( model : FbxNode ) {
		var d = new DefaultMatrixes();
		var F = Math.PI / 180;
		for( p in model.getAll("Properties70.P") )
			switch( p.props[0].toString() ) {
			case "GeometricTranslation":
				// handle in Geometry directly
			case "PreRotation":
				d.preRot = new Point(p.props[4].toFloat() * F, p.props[5].toFloat() * F, p.props[6].toFloat() * F);
			case "Lcl Rotation":
				d.rotate = new Point(p.props[4].toFloat() * F, p.props[5].toFloat() * F, p.props[6].toFloat() * F);
			case "Lcl Translation":
				d.trans = new Point(p.props[4].toFloat(), p.props[5].toFloat(), p.props[6].toFloat());
			case "Lcl Scaling":
				d.scale = new Point(p.props[4].toFloat(), p.props[5].toFloat(), p.props[6].toFloat());
			default:
			}
		defaultModelMatrixes.set(model.getName(), d);
		return d;
	}
	
}