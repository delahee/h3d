package hxd;

@generic
class Pool<T> {

	public var actives : hxd.Stack<T> = new hxd.Stack<T>();
	var pool 	: hxd.Stack<T> = new hxd.Stack<T>();
	public var allocProc : T -> Void = function(_){}
	public var deleteProc :T -> Void = function(_){}
	var cl : Class <T>;
	
	public function new( cl : Class<T>, ?allocProc : T -> Void, ?deleteProc : T -> Void ) {
		this.cl = cl;
		if(actives!=null)actives.reserve(10);
		pool.reserve(10);
		
		if( allocProc!=null) this.allocProc = allocProc;
		if( deleteProc!=null) this.deleteProc = deleteProc;
	}
	
	public function alloc() : T{
		if ( pool.length == 0 ){
			//this active becomes untracked
			var inst =  Type.createInstance( cl,[] );
			allocProc(inst);
			if(actives!=null)actives.push( inst );
			return inst;
		}
		else {
			var nt = pool.pop();
			allocProc(nt);
			if(actives!=null)actives.push(nt);
			return nt;
		}
	}
	
	public function free(t) : Void {
		if (t == null) return;
		delete(t);
	}
		
	public function delete(t) : Void{
		if (t == null) return;
		
		deleteProc(t);
		if(actives!=null)actives.remove(t);
		pool.push(t);
	}
	
	public function nbPooled(){
		return pool.length;
	}
	
	public function nbActives(){
		return actives.length;
	}
}