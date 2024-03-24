import js.Browser;
import js.html.Element;

function show(text:String):Void {
    var span = Browser.document.createSpanElement();
    span.innerText = text;
    showElem(span);
}

function showElem(elem:Element):Void {
    var div = Browser.document.createDivElement();
    div.className = "tampermonkey_mzte_notif";
    div.appendChild(elem);

    Browser.document.body.appendChild(div);
    Browser.window.setTimeout(div.remove, 5000);
}
