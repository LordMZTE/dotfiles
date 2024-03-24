#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import sys.io.File;
#end

macro function init() {
    var oldHeader = Context.definedValue("source-header");
    var header = Std.string(File.read("assets/header.txt").readAll());
    Compiler.define("source-header", '$header\n//$oldHeader');
    return macro {};
}

macro function fileContent(path:String):haxe.macro.Expr.ExprOf<String> {
    return macro $v{Std.string(File.read(path).readAll())};
}

