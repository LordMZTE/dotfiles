package ext.vim;

extern class Opt implements Dynamic {
    function prepend(x:Dynamic):Void;
    function append(x:Dynamic):Void;
    function remove(x:Dynamic):Void;
}
