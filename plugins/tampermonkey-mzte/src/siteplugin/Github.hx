package siteplugin;

import js.Browser;

final REMOVE_CLASSES:Array<String> = ["copilotPreview__container", "AppHeader-CopilotChat"];

class Github implements ISitePlugin {
    public function new() {}

    public function onContentLoaded() {
        for (clazz in REMOVE_CLASSES) {
            for (elem in Browser.document.getElementsByClassName(clazz)) {
                elem.remove();
            }
        }
    }
}
