package actions;

import js.Browser;
import js.html.MouseEvent;

using js.lib.HaxeIterator;

class InfoAction extends Action {
    public function new() {}

	function get_label():String {
        return "Info";
	}

	function call(ev:MouseEvent) {
        var divElem = Browser.document.createDivElement();
        divElem.setAttribute("style", "overflow-y:scroll;height:500px;");

        {
            var labelElem = Browser.document.createParagraphElement();
            labelElem.innerText = '${ClearCookiesAction.cookies.length} cookies';
            divElem.appendChild(labelElem);
        }

        {
            var labelElem = Browser.document.createParagraphElement();
            labelElem.innerText = "Style Blacklist:";
            divElem.appendChild(labelElem);

            var listElem = Browser.document.createUListElement();
            for (domain in ToggleStyleAction.blacklist.keys()) {
                var liElem = Browser.document.createLIElement();
                liElem.innerText = domain;
                listElem.appendChild(liElem);
            }
            divElem.appendChild(listElem);
        }

        Notifications.showElem(divElem);
    }
}
