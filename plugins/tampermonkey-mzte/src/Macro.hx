#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

var assetRoot = "../../cgout/cgassets/tampermonkey-mzte";

macro function init() {
    var oldHeader = Context.definedValue("source-header");
    var header = Std.string(File.read('$assetRoot/header.txt').readAll());
    Compiler.define("source-header", '$header\n//$oldHeader');
    return macro {};
}

macro function fileContent(path:String):haxe.macro.Expr.ExprOf<String> {
    return macro $v{Std.string(File.read('$assetRoot/$path').readAll())};
}

macro function siteStyles():haxe.macro.Expr.ExprOf<Map<String, String>> {
    var map:Array<haxe.macro.Expr> = [];

    for (f in FileSystem.readDirectory('$assetRoot/site_styles')) {
        if (f.endsWith(".css")) {
            map.push(macro $v{f.substr(0, f.length - 4)} => Macro.fileContent($v{'site_styles/$f'}));
        }
    }

    return macro $a{map};
}
