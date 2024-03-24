import js.html.MouseEvent;

@:native("") extern class GM {
    @:native("GM_registerMenuCommand")
    static function registerMenuCommand(label:String, cb:MouseEvent->Void):Void;

    @:native("GM_getValue")
    static function getValue(key:String, ?defaultValue:Dynamic):Dynamic;

    @:native("GM_setValue")
    static function setValue(key:String, value:Dynamic):Void;
}
