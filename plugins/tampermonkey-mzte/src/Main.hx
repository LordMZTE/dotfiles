import actions.ClearCookiesAction;
import actions.ToggleStyleAction;
import actions.InfoAction;
import js.Browser;

using Lambda;

final SITE_PLUGINS:Map<String, () -> ISitePlugin> = ["github.com" => siteplugin.Github.new];
final SITE_STYLES = Macro.siteStyles();

function main() {
    var ownStyle = Browser.document.createStyleElement();
    ownStyle.innerHTML = Macro.fileContent("own_style.css");

    var style = Browser.document.createStyleElement();
    style.innerHTML = Macro.fileContent("style.css");

    Browser.document.addEventListener("DOMContentLoaded", () -> {
        Browser.document.body.appendChild(ownStyle);

        if (!actions.ToggleStyleAction.blacklist.has(Browser.window.location.hostname)) {
            Browser.document.body.appendChild(style);
        }

        final siteStyle = SITE_STYLES[Browser.window.location.hostname];
        if (siteStyle != null) {
            var siteStyleElem = Browser.document.createStyleElement();
            siteStyleElem.innerHTML = siteStyle;
            Browser.document.body.appendChild(siteStyleElem);
            Browser.console.log("added site style: ", siteStyleElem);
        }

        final sitePlugin = SITE_PLUGINS[Browser.window.location.hostname];
        if (sitePlugin != null) {
            sitePlugin().onContentLoaded();
        }
    });

    [new InfoAction(), new ToggleStyleAction(style), new ClearCookiesAction(),].iter(a -> a.register());
}
