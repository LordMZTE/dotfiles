package ext.vim;

import lua.Table;

enum abstract LogLevel(Int) {
    var Trace;
    var Debug;
    var Info;
    var Warn;
    var Error;
    var Off;
}

@:native("vim")
extern class Vim {
    public static var loop:Loop;
    public static var api:Api;
    public static var keymap:Keymap;

    public static var env:Table<String, String>;
    public static var opt:Table<String, Opt>;

    public static function print(x:Dynamic):Void;
    public static function schedule(f:() -> Void):Void;
    public static function notify(msg:String, ?level:LogLevel, ?opts:AnyTable):Void;
    public static function cmd(cmd:String):Void;
}
