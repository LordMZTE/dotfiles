package ext.vim;

/**
    This class is a more complete version of the luv event loop.
**/
extern class Loop extends lua.lib.luv.Loop {
    @:luaDotMethod
    extern function os_homedir():String;
}
