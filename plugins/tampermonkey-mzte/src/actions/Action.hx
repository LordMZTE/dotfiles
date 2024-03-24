package actions;

import js.html.MouseEvent;

abstract class Action {
    var label(get, never):String;

    public function register():Void {
        GM.registerMenuCommand(this.label, this.call);
    };

    abstract function get_label():String;
    abstract function call(ev: MouseEvent):Void;
}
