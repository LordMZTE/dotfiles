package ext.mzte_nv;

import lua.Table.AnyTable;

@:luaRequire("mzte_nv")
extern class MZTENv {
    public static var reg:AnyTable;

    public static var cpbuf:CPBuf;
    public static var compile:Compile;

    @:luaDotMethod
    public static function onInit():Void;
}
