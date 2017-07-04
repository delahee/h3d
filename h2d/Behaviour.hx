package h2d;

class Behaviour { 
	public var 		obj : h2d.Entity;
	public var 		beforeChildren = false;
	public var 		onDispose = new hxd.Signal();
	public var 		onUpdate = new hxd.Signal();
	public var 		disposed = false;
	public var		name:String = null;
	
	public function new(o: h2d.Entity) 				{ 
		o.bhvs.push(this);
		obj = o;
	}
	
	public function dispose() 								{
		if (disposed) return;
		
		disposed = true;
		if (obj != null) obj.bhvs.remove(this);
		onDispose.trigger();
		onUpdate.dispose();
		onDispose.dispose();
	}
	
	public function update(e:h2d.Entity	) { 
		onUpdate.trigger();
	}

	public function clone(c) : hxd.Behaviour {
		throw "Please implement me";
		return null;
	}
	
	public static function anon( func : h2d.Entity -> Void, ent : h2d.Entity ) {
		var b = new h2d.Behaviour( ent );
		b.onUpdate.add( func.bind(ent) );
		return b;
	}
	
}
