package ext.vim;

import lua.Table.AnyTable;

typedef CreateUserCommandOptions = {
    // incomplete
    nargs:Int,
};

private extern class ApiExt {
    @:luaDotMethod
    function nvim_create_user_command(name:String, command:Dynamic, opts:CreateUserCommandOptions):Void;
}

/**
    Removes Haxe metadata from tables for picky lua functions.
    See: https://github.com/HaxeFoundation/haxe/issues/11805
**/
private inline function removeMeta(x:Dynamic) {
    cast(x, AnyTable).__fields__ = null;
}

abstract Api(ApiExt) {
    public inline function createUserCommand(name:String, command:Dynamic, opts:CreateUserCommandOptions) {
        removeMeta(opts);
        this.nvim_create_user_command(name, command, opts);
    }
}
