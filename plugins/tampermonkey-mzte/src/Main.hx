import js.Browser;

function main() {
    var ownStyle = Browser.document.createStyleElement();
    ownStyle.innerHTML = Macro.fileContent("assets/own_style.css");

    var style = Browser.document.createStyleElement();
    style.innerHTML = Macro.fileContent("assets/style.css");

    Browser.document.addEventListener("DOMContentLoaded", () -> {
        Browser.document.body.appendChild(ownStyle);

        if (!actions.ToggleStyleAction.blacklist.has(Browser.window.location.hostname)) {
            Browser.document.body.appendChild(style);
        }
    });

    new actions.InfoAction().register();
    new actions.ToggleStyleAction(style).register();
    new actions.ClearCookiesAction().register();
}
