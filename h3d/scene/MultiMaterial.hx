package h3d.scene;

class MultiMaterial extends Mesh {

	public var materials : Array<h3d.mat.MeshMaterial>;
	
	public function new( prim, mats : Array<h3d.mat.MeshMaterial> , ?parent ) {
		super(prim, mats[0], parent);
		this.materials = mats;
	}
	
	override function clone( ?o : Object ) {
		var m = o == null ? new MultiMaterial(null,materials) : cast o;
		m.materials = [for( m in materials ) m.clone()];
		super.clone(m);
		m.material = m.materials[0];
		return m;
	}
	
	@:access(h3d.mat.MeshMaterial.setup)
	function drawMaterial( ctx : RenderContext, mid : Int ) {
		var m = materials[mid];
		if( m == null )
			return;
		if( m.renderPass > ctx.currentPass ) {
			ctx.addPass(drawMaterial.bind(_,mid));
			return;
		}
		ctx.localPos = this.absPos;
		m.setup(ctx);
		ctx.engine.selectMaterial(m);
		primitive.selectMaterial(mid);
		primitive.render(ctx.engine);
	}
	
	override function draw( ctx : RenderContext ) {
		for( mid in 0...materials.length )
			drawMaterial(ctx,mid);
	}
	
}