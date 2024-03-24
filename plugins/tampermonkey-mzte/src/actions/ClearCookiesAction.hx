package actions;

import js.lib.Date;
import js.Browser;
import js.html.MouseEvent;

class ClearCookiesAction extends Action {
    public static var cookies(get, never):Array<String>;

    public function new() {}

    function get_label():String {
        return "Clear Cookies";
    }

    function call(ev:MouseEvent) {
        var cks = cookies;

        var now = new Date().toUTCString();

        for (cookie in cks) {
            var key = cookie.split("=")[0];
            Browser.document.cookie = '$key=;expires=$now;path=/';
        }

        if (cks.length == 0) {
            Notifications.show("No Cookies to Delete.");
            return;
        }

        var notifElem = Browser.document.createDivElement();

        var labelElem = Browser.document.createParagraphElement();
        labelElem.innerText = "Deleted These Cookies:";
        notifElem.appendChild(labelElem);

        var listElem = Browser.document.createUListElement();
        listElem.setAttribute("style", "list-style-position: inside;");
        for (cookie in cks) {
            var liElem = Browser.document.createLIElement();
            liElem.innerText = cookie.split("=")[0];

            listElem.appendChild(liElem);
        }
        notifElem.append(listElem);

        Notifications.showElem(notifElem);
    }

    static function get_cookies():Array<String> {
        return Browser.document.cookie
            .split(";")
            .map(StringTools.trim)
            .filter(s -> s.length != 0);
    }
}
