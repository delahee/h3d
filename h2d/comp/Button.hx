package h2d.comp;

class Button extends Interactive {
	
	var tf : h2d.Text;
	
	public var text(default, set) : String;
	
	public function new(text, ?parent) {
		super("button",parent);
		tf = new h2d.Text(null, this);
		this.text = text;
	}

	function get_text() {
		return tf.text;
	}
	
	function set_text(t) {
		needRebuild = true;
		return text = t;
	}
	
	override function resize( ctx : Context ) {
		if( ctx.measure )
			textResize( tf, text );
		super.resize(ctx);
	}
	
}
