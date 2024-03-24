package actions;

import js.lib.Set;
import js.Browser;
import js.html.StyleElement;
import js.html.MouseEvent;

class ToggleStyleAction extends Action {
    public static var blacklist(get, set):Set<String>;

    static function get_blacklist():Set<String> {
        var arr:Array<String> = GM.getValue("domainBlacklist", []);
        return new Set(arr);
    }

    static function set_blacklist(value:Set<String>):Set<String> {
        GM.setValue("domainBlacklist", [for (v in value) v]);
        return value;
    }

    var styleElem:StyleElement;

    public function new(style_elem:StyleElement) {
        this.styleElem = style_elem;
    }

    function get_label():String {
        return "Toggle Style";
    }

    function call(ev:MouseEvent) {
        var bl = blacklist;
        if (this.styleElem.parentElement == null) {
            Browser.document.body.appendChild(this.styleElem);
            bl.delete(Browser.window.location.hostname);
            Notifications.show("Style Enabled");
        } else {
            this.styleElem.remove();
            bl.add(Browser.window.location.hostname);
            Notifications.show("Style Disabled");
        }
        blacklist = bl;
    }
}
