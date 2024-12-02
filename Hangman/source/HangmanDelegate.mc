import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application.Storage;

class HangmanDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new HangmanSettings(), new HangmanMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onTap(clickEvent) as Boolean {
//WatchUi.showToast("tap",{});
        var xy = clickEvent.getCoordinates();
        var state = game.get("state");
        if (state == 0) {
            for (var i=0;i<26;i++) {
                if (inbox([letterX[i],letterY[i]],[rad*2,rad*2],xy)) {
//WatchUi.showToast(letters[i],{});
                    if (letterStatus[i] == 0) {
                        switch (keyboard) {
                            case 0:
                               procLetter(i);
                                break;
                            case 1:
                                selected = i;
                                break;
                        }
                        WatchUi.requestUpdate();
                        return true;
                    }
                }
            }
        }
        if (inbox([newX,newY],[newW,newH],xy)) {
//WatchUi.showToast("new game",{});
            newgame();
            WatchUi.requestUpdate();
            return true;
        }
        if (inbox([tryX,tryY],[tryW,tryH],xy) and selected != -1) {
//WatchUi.showToast("try",{});
            procLetter(selected);
            selected = -1;
            WatchUi.requestUpdate();
            return true;
        }
        if (inbox([nooseX,nooseY],[nooseW,nooseH],xy)) {
            showStats();
        }
        return false;
    }

    // Check if a point is within a box
    // boxxy = [x,y] coordinates of upper left corner of box
    // boxwh = [w,h] width and height of box
    // point = [x,y] coordinates of point to check
    function inbox(boxxy,boxwh,point) as Boolean {
        if (point[0]<boxxy[0]) {return false;}
        if (point[0]>boxxy[0]+boxwh[0]) {return false;}
        if (point[1]<boxxy[1]) {return false;}
        if (point[1]>boxxy[1]+boxwh[1]) {return false;}
        return true;
    }

    function procLetter(l) {
        var segments = game.get("segments");
        if (puzzle.find(letters[l]) == null) {
            letterStatus[l] = -1;
            segments++;
            game.put("segments",segments);
            if (segments == 6) {
                game.put("state",-1);
                addStats();
            }
        } else {
            letterStatus[l] = 1;
        }
        game.put("status",letterStatus);
        Storage.setValue("game",game);
    }
}