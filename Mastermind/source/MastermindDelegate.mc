import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;

class MastermindDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        return false;
    }

    function onTap(clickEvent) as Boolean {
        var xy = clickEvent.getCoordinates();
        switch (state) {
            case 0:
                if (inbox(xy,adjcolorsXY[0],adjcolorsWH) and colors < maxcolors) {
                    colors++;
                    savegame();
                    WatchUi.requestUpdate();
                    return true;
                }
                if (inbox(xy,adjcolorsXY[1],adjcolorsWH) and colors > mincolors) {
                    colors--;
                    savegame();
                    WatchUi.requestUpdate();
                    return true;
                }
                tmp = [adjtriesWH[0],adjtriesWH[1]/2];
                tmp2 = [adjtriesXY[0],adjtriesXY[1]+tmp[1]];
                if (inbox(xy,adjtriesXY,tmp) and tries < maxtries) {
                    tries++;
                    savegame();
                    WatchUi.requestUpdate();
                    return true;
                }
                if (inbox(xy,tmp2,tmp) and tries > mintries) {
                    tries--;
                    savegame();
                    WatchUi.requestUpdate();
                    return true;
                }
                tmp = [adjpegsWH[0],adjpegsWH[1]/2];
                tmp2 = [adjpegsXY[0],adjpegsXY[1]+tmp[1]];
                if (inbox(xy,adjpegsXY,tmp) and pegs < maxpegs) {
                    pegs++;
                    savegame();
                    WatchUi.requestUpdate();
                    return true;
                }
                if (inbox(xy,tmp2,tmp) and pegs > minpegs) {
                    pegs--;
                    savegame();
                    WatchUi.requestUpdate();
                    return true;
                }
                if (inbox(xy,dupXY,dupWH)) {
                    dups = !dups;
                    savegame();
                    WatchUi.requestUpdate();
                    return true;
                }
                if (inbox(xy,newXY,newWH)) {
                    state++;
                    newgame2();
                    savegame();
                    WatchUi.requestUpdate();
                    return true;
                }
                break;
            case 1:
                for (var i=0;i<colors;i++) {
                    if (inCircle(xy, colXY[i], colR)) {
                        peg[row][col] = i;
                        col = (col + 1) % pegs;
                        savegame();
                        WatchUi.requestUpdate();
                        return true;
                    }
                }
                for (var i=0;i<pegs;i++) {
                    if (inCircle(xy,pegXY[row][i],pegR)) {
                        col = i;
                        savegame();
                        WatchUi.requestUpdate();
                        return true;
                    }
                }
                if (inbox(xy, clearXY, clearWH)) {
                    for (var i=0;i<pegs;i++) {
                        peg[row][i] = null;
                    }
                    col = 0;
                    savegame();
                    WatchUi.requestUpdate();
                    return true;
                }
                tmp = true;
                for (var i=0;i<pegs;i++) {
                    if (peg[row][i] == null) { tmp = false; break; }
                }
                if (inbox(xy, guessXY, guessWH) and tmp) {
                    setresult();
                    savegame();
                    WatchUi.requestUpdate();
                    return true;
                }
                break;
            case 2:
                if (inbox(xy,statsXY,statsWH)) {
                    showstats();
                    WatchUi.requestUpdate();
                    return true;
                }
                if (inbox(xy,newXY,newWH)) {
                    newgame();
                    WatchUi.requestUpdate();
                    return true;
                }
                break;
        }
        return false;
    }

    public function inCircle(point, circle, rad) {
        var x = point[0];
        var y = point[1];
        var cx = circle[0];
        var cy = circle[1];
        return ((x - cx) * (x - cx) + (y - cy) * (y - cy) <= rad * rad);
    }

    // Check if a point is within a box
    // boxxy = [x,y] coordinates of upper left corner of box
    // boxwh = [w,h] width and height of box
    // point = [x,y] coordinates of point to check
    public function inbox(point,boxxy,boxwh) as Boolean {
        if (point[0]<boxxy[0]) {return false;}
        if (point[0]>boxxy[0]+boxwh[0]) {return false;}
        if (point[1]<boxxy[1]) {return false;}
        if (point[1]>boxxy[1]+boxwh[1]) {return false;}
        return true;
    }
}