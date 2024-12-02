import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Application.Storage;

class HangmanMenuDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    public function onSelect(item as MenuItem) {
        switch (item.getId()) {
            case "keyboard":
                keyboard = (keyboard + 1) % keyboards.size();
                Storage.setValue("keyboard",keyboard);
                item.setSubLabel(keyboards[keyboard]);
                break;
            case "theme":
                theme = (theme + 1) % themes.size();
                Storage.setValue("theme",theme);
                item.setSubLabel(themes[theme]);
                break;
        }
    }

    public function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}