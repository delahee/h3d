package h2d;

class Entity extends Sprite {
	public var bhvs : hxd.Stack<h2d.Behaviour> = new hxd.Stack<h2d.Behaviour>();
	public function new(p) {
		super(p);
	}
	
	public override function dispose() {
		super.dispose();
		for (b in bhvs.backWardIterator()) {
			b.obj = null;
			b.dispose();
		}
	}
	
	public override function sync(ctx) {
		for (b in bhvs) 
			if(b.beforeChildren)
				b.update(this);
					
		super.sync(ctx);
					
		for (b in bhvs) 
			if(!b.beforeChildren)
				b.update(this);
	}
	
	public function anon(proc:h2d.Entity->Void) {
		h2d.Behaviour.anon( proc, this );
	}
	
	public function getBhvByName(name:String) : Null<h2d.Behaviour> {
		for ( b in bhvs ) 
			if ( b.name == name )
				return b;
		return null;
	}
}