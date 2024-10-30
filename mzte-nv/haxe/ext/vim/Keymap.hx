package ext.vim;

import haxe.Constraints.Function;
import haxe.extern.EitherType;

using StaticTools;

private extern class KeymapExt {
    @:luaDotMethod
    function set(mode:String, bind:String, handler:EitherType<String, Function>, options:Dynamic):Void;
}

abstract Keymap(KeymapExt) {
    public inline function set(mode:String, bind:String, handler:EitherType<String, Function>, options:Dynamic):Void {
        options.removeMeta();
        this.set(mode, bind, handler, options);
    }
}
