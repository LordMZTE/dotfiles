package;

import lua.Table;

class StaticTools {
    public static inline function toTable<K, V>(map:Map<K, V>):Table<K, V> {
        return (untyped map : Dynamic).h;
    }

    /**
        Removes Haxe metadata from tables for picky lua functions.
        See: https://github.com/HaxeFoundation/haxe/issues/11805
    **/
    public static inline function removeMeta(x:Dynamic) {
        cast(x, AnyTable).__fields__ = null;
    }
}
