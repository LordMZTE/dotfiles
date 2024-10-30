package ext.vim;

using StaticTools;

typedef CreateUserCommandOptions = {
    // incomplete
    nargs:Int,
};

private extern class ApiExt {
    @:luaDotMethod
    function nvim_create_user_command(name:String, command:Dynamic, opts:CreateUserCommandOptions):Void;
}

abstract Api(ApiExt) {
    public inline function createUserCommand(name:String, command:Dynamic, opts:CreateUserCommandOptions) {
        opts.removeMeta();
        this.nvim_create_user_command(name, command, opts);
    }
}
