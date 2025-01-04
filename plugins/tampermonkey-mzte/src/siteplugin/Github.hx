package siteplugin;

import js.Browser;

class Github implements ISitePlugin {
    public function new() {}

	public function onContentLoaded() {
        final ai_bullshit = Browser.document.getElementsByClassName("copilotPreview__container");
        for (elem in ai_bullshit) {
            elem.remove();
        }
    }
}
