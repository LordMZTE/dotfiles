package ext.mzte_nv;

import lua.Table.AnyTable;

@:luaRequire("mzte_nv")
extern class MZTENv {
    public static var reg:AnyTable;

    public static var cpbuf:CPBuf;
    public static var compile:Compile;
    public static var tsn_actions:TSNActions;
    public static var utils:Utils;

    @:luaDotMethod
    public static function onInit():Void;
}
