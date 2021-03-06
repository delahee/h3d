package hxd.res;
import hxd.System;

using StringTools;
#if (air3 || sys)

@:allow(hxd.res.LocalFileSystem)
@:access(hxd.res.LocalFileSystem)
private class LocalEntry extends FileEntry {
	
	var fs : LocalFileSystem;
	var relPath : String;
	
	#if air3
	var file : flash.filesystem.File;
	var fread : flash.filesystem.FileStream;
	#else
	var file : String;
	var fread : sys.io.FileInput;
	#end

	function new(fs, name, relPath, file) {
		this.fs = fs;
		this.name = name;
		this.relPath = relPath;
		this.file = file;
		if( fs.createXBX && extension == "fbx" )
			convertToXBX();
	}
	
	static var INVALID_CHARS = ~/[^A-Za-z0-9_]/g;
	
	function convertToXBX() {
		function getXBX() {
			var fbx = null;
			try fbx = h3d.fbx.Parser.parse(getBytes().toString()) catch( e : Dynamic ) throw Std.string(e) + " in " + relPath;
			fbx = fs.xbxFilter(this, fbx);
			var out = new haxe.io.BytesOutput();
			new h3d.fbx.XBXWriter(out).write(fbx);
			return out.getBytes();
		}
		var target = fs.tmpDir + "R_" + INVALID_CHARS.replace(relPath,"_") + ".xbx";
		#if air3
		var target = new flash.filesystem.File(target);
		if( !target.exists || target.modificationDate.getTime() < file.modificationDate.getTime() ) {
			var fbx = getXBX();
			var out = new flash.filesystem.FileStream();
			out.open(target, flash.filesystem.FileMode.WRITE);
			out.writeBytes(fbx.getData());
			out.close();
		}
		file = target;
		#else
		var ttime = try sys.FileSystem.stat(target) catch( e : Dynamic ) null;
		if( ttime == null || ttime.mtime.getTime() < sys.FileSystem.stat(file).mtime.getTime() ) {
			var fbx = getXBX();
			sys.io.File.saveBytes(target, fbx);
		}
		#end
	}

	override function getSign() : Int {
		#if air3
		var old = fread == null ? -1 : fread.position;
		open();
		fread.endian = flash.utils.Endian.LITTLE_ENDIAN;
		var i = fread.readUnsignedInt();
		if( old < 0 ) close() else fread.position = old;
		return i;
		#else
		var old = if( fread == null ) -1 else fread.tell();
		open();
		var i = fread.readInt32();
		if( old < 0 ) close() else fread.seek(old, SeekBegin);
		return i;
		#end
	}

	override function getBytes() : haxe.io.Bytes {
		#if air3
		var fs = new flash.filesystem.FileStream();
		fs.open(file, flash.filesystem.FileMode.READ);
		var bytes = haxe.io.Bytes.alloc(fs.bytesAvailable);
		fs.readBytes(bytes.getData());
		fs.close();
		fs = null;
		return bytes;
		#else
		return sys.io.File.getBytes(LocalFileSystem.getOSPath(file));
		#end
	}
	
	override function open() {
		#if air3
		if( fread != null )
			fread.position = 0;
		else {
			fread = new flash.filesystem.FileStream();
			fread.open(file, flash.filesystem.FileMode.READ);
		}
		#else
		if( fread != null )
			fread.seek(0, SeekBegin);
		else
			fread = sys.io.File.read(file);
		#end
	}
	
	override function skip(nbytes:Int) {
		#if air3
		fread.position += nbytes;
		#else
		fread.seek(nbytes, SeekCur);
		#end
	}
	
	override function readByte() {
		#if air3
		return fread.readUnsignedByte();
		#else
		return fread.readByte();
		#end
	}
	
	override function read( out : haxe.io.Bytes, pos : Int, size : Int ) : Void {
		#if air3
		fread.readBytes(out.getData(), pos, size);
		#else
		fread.readFullBytes(out, pos, size);
		#end
	}

	override function close() {
		#if air3
		if( fread != null ) {
			fread.close();
			fread = null;
		}
		#else
		if( fread != null ) {
			fread.close();
			fread = null;
		}
		#end
	}

	override function get_isDirectory() {
		#if air3
		return file.isDirectory;
		#else
		return sys.FileSystem.isDirectory( LocalFileSystem.getOSPath( file ));
		#end
	}

	override function load( ?onReady : Void -> Void ) : Void {
		#if ((air3)||(openfl))
		if( onReady != null ) haxe.Timer.delay(onReady, 1);
		#else
		throw "TODO";
		#end
	}
	
	override function loadBitmap( onLoaded : hxd.BitmapData -> Void ) : Void {
		#if((flash)||(openfl))
			var loader = new flash.display.Loader();
			loader.contentLoaderInfo.addEventListener(flash.events.IOErrorEvent.IO_ERROR, function(e:flash.events.IOErrorEvent) {
				throw Std.string(e) + " while loading " + relPath;
			});
			loader.contentLoaderInfo.addEventListener(flash.events.Event.COMPLETE, function(_) {
				if ( System.debugLevel==1) trace('complete !');
				var content : flash.display.Bitmap = cast loader.content;
				onLoaded(hxd.BitmapData.fromNative(content.bitmapData));
				loader.unload();
			});
			
			//if ( System.isVerbose) trace('requesting loader '+file.url);
			var url = #if air3 file.url #else file #end;
			loader.load(new flash.net.URLRequest(url));
		#else
			if ( System.isVerbose) trace('not implemtented');
			throw "TODO";
		#end
	}
	
	public override function debugString() {
		#if air3
		return file.nativePath;
		#else 
		return "";
		#end
	}
	
	override function get_path() {
		return relPath == null ? "<root>" : relPath;
	}
	
	override function exists( name : String ) {
		return fs.exists(relPath == null ? name : relPath + "/" + name);
	}
	
	override function get( name : String ) {
		return fs.get(relPath == null ? name : relPath + "/" + name);
	}
	
	override function get_size() {
		#if air3
		return Std.int(file.size);
		#else
		return sys.FileSystem.stat(file).size;
		#end
	}

	override function iterator() {
		#if air3
		var arr = new Array<FileEntry>();
		
		if( file.exists )
		for( f in file.getDirectoryListing() )
			switch( f.name ) {
			case ".svn", ".git" if( f.isDirectory ):
				continue;
			default:
				arr.push(new LocalEntry(fs, f.name, relPath == null ? f.name : relPath + "/" + f.name, f));
			}
		return new hxd.impl.ArrayIterator(arr);
		#else
		var arr = new Array<FileEntry>();
		for( f in sys.FileSystem.readDirectory( LocalFileSystem.getOSPath(file) ) ) {
			switch( f ) {
			case ".svn", ".git" if( sys.FileSystem.isDirectory(file+"/"+f) ):
				continue;
			default:
				arr.push(new LocalEntry(fs, f, relPath == null ? f : relPath + "/" + f, file+"/"+f));
			}
		}
		return new hxd.impl.ArrayIterator(arr);
		#end
	}

	#if air3

	var watchCallback : Void -> Void;
	var watchTime : Float;
	static var WATCH_LIST : Array<LocalEntry> = null;

	static function checkFiles(_) {
		for( w in WATCH_LIST ) {
			var t = try w.file.modificationDate.getTime() catch( e : Dynamic ) -1;
			if( t != w.watchTime ) {
				// check we can write (might be deleted/renamed/currently writing)
				try {
					var f = new flash.filesystem.FileStream();
					f.open(w.file, flash.filesystem.FileMode.READ);
					f.close();
					f.open(w.file, flash.filesystem.FileMode.APPEND);
					f.close();
				} catch( e : Dynamic ) continue;
				w.watchTime = t;
				w.watchCallback();
			}
		}
	}

	override function watch( onChanged : Null < Void -> Void > ) {
		if( onChanged == null ) {
			if( watchCallback != null ) {
				WATCH_LIST.remove(this);
				watchCallback = null;
			}
			return;
		}
		if( watchCallback == null ) {
			if( WATCH_LIST == null ) {
				WATCH_LIST = [];
				flash.Lib.current.stage.addEventListener(flash.events.Event.ENTER_FRAME, checkFiles);
			}
			var path = path;
			for( w in WATCH_LIST )
				if( w.path == path ) {
					w.watchCallback = null;
					WATCH_LIST.remove(w);
				}
			WATCH_LIST.push(this);
		}
		watchTime = file.modificationDate.getTime();
		watchCallback = onChanged;
		return;
	}

	#end

}

/**
 * Tries to reach the local file sysytem
 */
class LocalFileSystem implements FileSystem {
	
	var baseDir : String;
	var root : FileEntry;
	public var createXBX : Bool;
	public var tmpDir : String;
	
	public function new( dir : String , ?useAbsolute=false) {
		baseDir = dir;
		#if air3
			var froot : flash.filesystem.File;
			
			var useUrl = false;
			
			#if mobile
			useUrl = true;
			#end
			
			if ( ! useAbsolute ){
				var path = flash.filesystem.File.applicationDirectory.nativePath + "/" + baseDir;
				if ( useUrl )	{
					path = flash.filesystem.File.applicationDirectory.url + baseDir;
					if ( path.startsWith("app://") ) path = "app:/" + path.substring("app://".length,path.length );
				}
				froot = new flash.filesystem.File(path);
				
				if ( !froot.exists ) {
					if ( System.debugLevel >= 2) {
						trace("path:" + flash.filesystem.File.applicationDirectory.nativePath);
						trace("path:" + flash.filesystem.File.applicationDirectory.url);
					}
					throw "air:Could not find dir " + dir;
				}
				baseDir = froot.nativePath;
				if ( useUrl )	{
					baseDir = froot.url;
				}
			}
			else {
				froot = new flash.filesystem.File(dir);
			}
			
			baseDir = baseDir.split("\\").join("/");
			if( !StringTools.endsWith(baseDir, "/") ) baseDir += "/";
			root = new LocalEntry(this, "root", null, froot);
		#else
			var exePath = Sys.programPath().split("\\").join("/").split("/");
			exePath.pop();
			
			var frootPath = exePath.join("/") + "/" + baseDir;
			if ( useAbsolute ){
				frootPath = dir;//let simplify :D
			}
			
			var froot = sys.FileSystem.fullPath(frootPath);
			trace("frootPath:"+frootPath);
			if ( !sys.FileSystem.isDirectory( getOSPath(froot)) ) {
				#if debug
				var osp = getOSPath(froot);
				trace("osp:" + osp);
				#end
				throw "sys:Could not find dir " + dir;
			}
			
			baseDir = froot.split("\\").join("/");
			if( !StringTools.endsWith(baseDir, "/") ) baseDir += "/";
			root = new LocalEntry(this, "root", null, baseDir);
		#end
		tmpDir = baseDir + ".tmp/";
	}
	
	static function getOSPath( __path : String ){
		#if switch
		if ( __path.startsWith("rom:/"))
			return __path;
		else 
			return "rom:/" + __path;
		#else 
			return __path;
		#end
	}
	
	public dynamic function xbxFilter( entry : FileEntry, fbx : h3d.fbx.Data.FbxNode ) : h3d.fbx.Data.FbxNode {
		return fbx;
	}
	
	public function getRoot() : FileEntry {
		return root;
	}
	
	public function getBaseDir(){
		return baseDir;
	}

	function open( path : String ) {
		#if air3
		var f = new flash.filesystem.File(baseDir + path);
		f.canonicalize();
		return f;
		#elseif sys
		var p = baseDir + path;
		var f = sys.FileSystem.fullPath( LocalFileSystem.getOSPath(p)).replace("\\","/");
		return f;
		#end
	}
	
	public function exists( path : String ) {
		#if air3
		var f = open(path);
		return f != null && f.exists;
		#elseif sys
		var f = open(path);
		return f != null && sys.FileSystem.exists(f);
		#end
	}
	
	public function get( path : String ) {
		#if air3
		var f = open(path);
		if( f == null || !f.exists )
			throw "File not found " + path;
		return new LocalEntry(this, path.split("/").pop(), path, f);
		#elseif sys
		var f = open(path);
		if ( f == null )
			throw "File not found " + path;
		//if ( !sys.FileSystem.exists(f) )
		//	throw "File not found 2" + path;
		return new LocalEntry(this, path.split("/").pop(), path, f);
		#end
	}
	
	public function saveContent( path : String, data : haxe.io.Bytes ) {
		#if air3
		var f = open(path);
		var o = new flash.filesystem.FileStream();
		o.open(f, flash.filesystem.FileMode.WRITE);
		o.writeBytes(data.getData());
		o.close();
		#elseif sys
		var f = open(path);
		sys.io.File.saveBytes(f, data);
		#end
	}

	public function saveContentAt( path : String, data : haxe.io.Bytes, dataPos : Int, dataSize : Int, filePos : Int ) {
		#if air3
		var f = open(path);
		var o = new flash.filesystem.FileStream();
		o.open(f, flash.filesystem.FileMode.UPDATE);
		if( filePos != o.position ) o.position = filePos;
		if( dataSize > 0 ) o.writeBytes(data.getData(),dataPos,dataSize);
		o.close();
		#elseif sys
		var f = open(path);
		var fc = sys.io.File.append(f);
		fc.seek(filePos, SeekCur);
		fc.writeFullBytes(data, dataPos, dataSize);
		fc.close();
		#end
	}
	
}

#else

class LocalFileSystem implements FileSystem {
	
	public function new( dir : String ) {
		#if flash
		if( flash.system.Capabilities.playerType == "Desktop" )
			throw "Please compile with -lib air3";
		#end
	
		throw "Local file system is not supported for this platform";
	}
	
	public function exists(path:String) {
		trace("no implementation");
		return false;
	}
	
	public function get(path:String) : FileEntry {
		trace("no implementation");
		return null;
	}

	public function getRoot() : FileEntry {
		trace("no implementation");
		return null;
	}
}

#end