import js.Browser;

function main() {
    var elem = Browser.document.createStyleElement();
    elem.innerHTML = Macro.fileContent("assets/style.css");
    Browser.document.addEventListener("DOMContentLoaded", () -> Browser.document.body.appendChild(elem));
}
