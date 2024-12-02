import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;
import Toybox.Application.Storage;
import Toybox.Math;

var DS = System.getDeviceSettings();
var SW = DS.screenWidth;
var SH = DS.screenHeight;
var center = Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER;

var game,puzzle;

var letters = ["Q","W","E","R","T","Y","U","I","O","P","A","S","D","F","G","H","J","K","L","Z","X","C","V","B","N","M"];
var letterX = new [26];
var letterY = new [26];
var letterStatus = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
var rad = (SW*.9/10*.5).toNumber();

var keyboard = 0;
var keyboards = ["Single Tap", "Confirm Letter"];
var theme = 0;
var themes = ["Outlines", "Solid Colors", "Solid with Shadows"];
var solid = true;
var shadow = true;
var shadowcolor = 0x666666;

// Define the hangman area
var nooseH = SH*.2;
var nooseW = nooseH*.75;
var nooseX = (SW-nooseW)*.5;
var nooseY = SH*.025;
// Define the gallows line segments [x1,y1,x2,y2,color],[x1,y1,x2,y2,color]...
var gallows = [
    [nooseX+nooseW*.9, nooseY+nooseH, nooseX+nooseW*.9, nooseY, 0xcaa472],
    [nooseX+nooseW*.4, nooseY, nooseX+nooseW*.9, nooseY, 0xcaa472],
    [nooseX+nooseW*.4, nooseY+nooseH*.1, nooseX+nooseW*.4, nooseY, 0xcaa472],
    [0, nooseY+nooseH, SW, nooseY+nooseH, 0x00a000]
];
// Define the head circle [x,y,r,color]
var head = [nooseX+nooseW*.4, nooseY+nooseH*.125+nooseH*.125, nooseH*.125, 0xc6ab8d];
// Define the body line segments [x1,y1,x2,y2],[x1,y1,x2,y2]...
var body = [
    [nooseX+nooseW*.4, nooseY+nooseH*.125+nooseH*.25, nooseX+nooseW*.4, nooseY*.125+nooseH*.25+nooseH*.5, 0xff5151],
    [nooseX+nooseW*.1, nooseY+nooseH*.125+nooseH*.25, nooseX+nooseW*.4, nooseY+nooseH*.125+nooseH*.25+nooseH*.1, 0xff5151],
    [nooseX+nooseW*.7, nooseY+nooseH*.125+nooseH*.25, nooseX+nooseW*.4, nooseY+nooseH*.125+nooseH*.25+nooseH*.1, 0xff5151],
    [nooseX+nooseH*.1, nooseY+nooseH*.9, nooseX+nooseW*.4, nooseY*.125+nooseH*.25+nooseH*.5, 0x5972de],
    [nooseX+nooseW*.7, nooseY+nooseH*.9, nooseX+nooseW*.4, nooseY*.125+nooseH*.25+nooseH*.5, 0x5972de]
];

var puzzleX = SW/2;
var puzzleY = (SH/2-(nooseY+nooseH))/2+(nooseY+nooseH);

var newX,newY,newW,newH;
var tryX,tryY,tryW,tryH;
var so = SW*.008;
var soh = so/2;
var selected = -1;

// Figure out where to get puzzles (public Google Sheets?)
// Maybe keep 30 puzzles cached and get 10 at a time

class HangmanView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        var gap = (rad*.2).toNumber();
        var x = (SW*.5-((rad+gap/2)*10)-gap/2).toNumber();
        var y = (SH*.5).toNumber();
        for (var i=0;i<10;i++) {
            letterX[i] = x;
            letterY[i] = y;
            x = x+rad*2+gap;
        }
        y = y + rad*2+gap;
        x = (SW*.5-((rad+gap/2)*9)-gap/2).toNumber();
        for (var i=10;i<19;i++) {
            letterX[i] = x;
            letterY[i] = y;
            x = x+rad*2+gap;
        }
        y = y + rad*2+gap;
        x = (SW*.5-((rad+gap/2)*7)-gap/2).toNumber();
        for (var i=19;i<26;i++) {
            letterX[i] = x;
            letterY[i] = y;
            x = x+rad*2+gap;
        }
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        dc.setColor(0x000000,0x000000);
        dc.clear();
        dc.setPenWidth(4);
        var tmp,tmp2,tmp3,tmp4;

        // Load the game details
        game = Storage.getValue("game");
        if (game == null) { newgame(); }
        puzzle = game.get("puzzle");
        letterStatus = game.get("status");
        keyboard = Storage.getValue("keyboard");
        if (keyboard == null) { keyboard = 0; }
        theme = Storage.getValue("theme");
        if (theme == null) { theme = 0; }
        switch (theme) {
            case 0:
                solid = false;
                shadow = false;
                break;
            case 1:
                solid = true;
                shadow = false;
                break;
            case 2:
                solid = true;
                shadow = true;
                break;
        }

        switch (keyboard) {
            case 0:
                newX = SW*.275;
                newY = SH*.81;
                newW = SW-newX*2;
                newH = SH*.13;
                tryX = SW;
                tryY = SH;
                tryW = 0;
                tryH = 0;
                break;
            case 1:
                newX = SW*.275;
                newY = SH*.81;
                newW = (SW-newX*2)/2-SW*.02;
                newH = SH*.13;
                tryX = newX+newW+SW*.04;
                tryY = newY;
                tryW = newW;
                tryH = newH;
                break;
        }

        // Split the puzzle into character arrays at spaces, 14 characters max per line
        var lines = [] as Array;
        var l = -1;
        var text = puzzle.toString() as String;
        for (var s=0;s<100;s++) {
            tmp2 = text.find(" ");
            if (tmp2 == null) {
                tmp2 = text.length();
            }
            if (l == -1) {
                lines.add(text.substring(null,tmp2));
                l++;
            } else if (lines[l].length() + tmp2 <= 13) {
                lines[l] = lines[l] + " " + text.substring(null,tmp2) as String;
            } else {
                lines.add(text.substring(null,tmp2));
                l++;
            }
            if (tmp2 == text.length()) { break; }
            text = text.substring(tmp2+1,null);
        }
        for (var i=0;i<lines.size();i++) {
            lines[i] = lines[i].toCharArray();
        }

        // Blank out letters not yet found
        var state = game.get("state");
        if (state != -1) {
            tmp3 = 0;
            for (var i=0;i<lines.size();i++) {
                for (var j=0;j<lines[i].size();j++) {
                    tmp2 = letters.indexOf(lines[i][j].toString());
                    if (tmp2 != -1) {
                        if (letterStatus[tmp2] == 0) {
                            lines[i][j] = "_";
                            tmp3++;
                        }
                    }
                }
            }
            if (tmp3 == 0 and state == 0) {
                state = 1;
                game.put("state",state);
                Storage.setValue("game",game);
                addStats();
            }
        }

        // Draw the structure
        dc.setPenWidth(4);
        for (var i=0;i<gallows.size();i++) {
            dc.setColor(gallows[i][4],-1);
            dc.drawLine(gallows[i][0].toNumber(),gallows[i][1].toNumber(),gallows[i][2].toNumber(),gallows[i][3].toNumber());
        }

        // Draw the man
        dc.setPenWidth(4);
        var segments = game.get("segments");
        var offX = 0;
        var offY = 0;
        switch (state) {
            case 1:
                segments = 6;
                offX = nooseW*1.2;
                offY = nooseH*.07;
                dc.setColor(Graphics.COLOR_GREEN,-1);
                tmp = (nooseX/2*1.75).toNumber();
                tmp2 = nooseY+nooseH/2;
                tmp3 = (nooseH*.2).toNumber();
                dc.drawText(tmp, tmp2-tmp3, Graphics.FONT_TINY, "YOU", center);
                dc.drawText(tmp, tmp2+tmp3, Graphics.FONT_TINY, "WON!", center);
                break;
            case -1:
                dc.setColor(Graphics.COLOR_RED,-1);
                tmp = (nooseX/2*1.5).toNumber();
                tmp2 = (nooseY+nooseH/2+nooseH*.2).toNumber();
                dc.drawText(tmp, tmp2, Graphics.FONT_TINY, "YOU", center);
                tmp = (SW-nooseX/2*1.5).toNumber();
                dc.drawText(tmp, tmp2, Graphics.FONT_TINY, "DIED", center);
                break;
        }
        if (segments > 0) {
            dc.setColor(head[3],-1);
            dc.fillCircle((head[0]+offX).toNumber(),(head[1]+offY).toNumber(),head[2].toNumber());
        }
        for (var i=0;i<body.size();i++) {
            if (segments-1 > i) {
                dc.setColor(body[i][4],-1);
                dc.drawLine((body[i][0]+offX).toNumber(),(body[i][1]+offY).toNumber(),(body[i][2]+offX).toNumber(),(body[i][3]+offY).toNumber());
            }
        }

        // Draw the puzzle
        dc.setColor(0xffffff,-1);
        tmp = ((SH*.5)-(nooseY+nooseH))*.8/lines.size();
        tmp2 = puzzleY-(lines.size()-1)*tmp/2;
        for (var i=0;i<lines.size();i++) {
            tmp3 = (SW*.85)/14;
            tmp4 = puzzleX-(lines[i].size()-1)*tmp3/2;
            for (var j=0;j<lines[i].size();j++) {
                dc.drawText((tmp4+j*tmp3), (tmp2+i*tmp).toNumber(), Graphics.FONT_TINY, lines[i][j], center);
            }
        }

        // Draw the keyboard
        dc.setPenWidth(2);
        for (var i=0;i<26;i++) {
            switch (letterStatus[i]) {
                case 0:
                    if (solid) {
                        if (shadow) {
                            dc.setColor(shadowcolor,-1);
                            dc.fillRoundedRectangle((letterX[i]+so).toNumber(), (letterY[i]+so).toNumber(), rad*2, rad*2, rad/2);
                        }
                        if (keyboard == 1 and selected == i) {
                            dc.setColor(Graphics.COLOR_YELLOW,-1);
                        } else {
                            dc.setColor(Graphics.COLOR_WHITE,-1);
                        }
                        dc.fillRoundedRectangle(letterX[i], letterY[i], rad*2, rad*2, rad/2);
                        if (shadow) {
                            dc.setColor(shadowcolor,-1);
                            dc.drawText((letterX[i]+rad-soh).toNumber(), (letterY[i]+rad-soh).toNumber(), Graphics.FONT_TINY, letters[i], center);
                        }
                        dc.setColor(Graphics.COLOR_BLACK,-1);
                    } else {
                        if (keyboard == 1 and selected == i) {
                            dc.setColor(Graphics.COLOR_YELLOW,-1);
                        } else {
                            dc.setColor(Graphics.COLOR_LT_GRAY,-1);
                        }
                        dc.drawRoundedRectangle(letterX[i], letterY[i], rad*2, rad*2, rad/2);
                        dc.setColor(Graphics.COLOR_WHITE,-1);
                    }
                    break;
                case 1:
                    dc.setColor(Graphics.COLOR_GREEN,-1);
                    break;
                case -1:
                    dc.setColor(Graphics.COLOR_RED,-1);
                    break;
            }
            dc.drawText(letterX[i]+rad, letterY[i]+rad, Graphics.FONT_TINY, letters[i], center);
        }

        // Draw the New Game button
        if (solid) {
            if (shadow) {
                dc.setColor(shadowcolor,-1);
                dc.fillRoundedRectangle((newX+so).toNumber(), (newY+so).toNumber(), newW.toNumber(), newH.toNumber(), (newH*.2).toNumber());
            }
            dc.setColor(Graphics.COLOR_YELLOW,-1);
            dc.fillRoundedRectangle(newX.toNumber(), newY.toNumber(), newW.toNumber(), newH.toNumber(), (newH*.2).toNumber());
            tmp = "New Game";
            if (keyboard == 1) { tmp = "New"; }
            if (shadow) {
                dc.setColor(shadowcolor,-1);
                dc.drawText((newX+newW/2-soh).toNumber(), (newY+newH/2-soh).toNumber(), Graphics.FONT_TINY, tmp, center);    
            }
            dc.setColor(Graphics.COLOR_BLACK,-1);
            dc.drawText((newX+newW/2).toNumber(), (newY+newH/2).toNumber(), Graphics.FONT_TINY, tmp, center);
        } else {
            dc.setColor(Graphics.COLOR_LT_GRAY,-1);
            dc.drawRoundedRectangle(newX.toNumber(), newY.toNumber(), newW.toNumber(), newH.toNumber(), (newH*.2).toNumber());
            dc.setColor(Graphics.COLOR_YELLOW,-1);
            tmp = "New Game";
            if (keyboard == 1) { tmp = "New"; }
            dc.drawText((newX+newW/2).toNumber(), (newY+newH/2).toNumber(), Graphics.FONT_TINY, tmp, center);
        }

        // Draw the Try button
        if (keyboard == 1) {
            if (solid) {
                if (shadow) {
                    dc.setColor(shadowcolor,-1);
                    dc.fillRoundedRectangle((tryX+so).toNumber(), (tryY+so).toNumber(), tryW.toNumber(), tryH.toNumber(), (tryH*.2).toNumber());
                }
                dc.setColor(Graphics.COLOR_BLUE,-1);
                dc.fillRoundedRectangle(tryX.toNumber(), tryY.toNumber(), tryW.toNumber(), tryH.toNumber(), (tryH*.2).toNumber());
                if (shadow) {
                    dc.setColor(shadowcolor,-1);
                    dc.drawText((tryX+tryW/2-soh).toNumber(), (tryY+tryH/2-soh).toNumber(), Graphics.FONT_TINY, "Try", center);
                }
                dc.setColor(Graphics.COLOR_BLACK,-1);
                dc.drawText((tryX+tryW/2).toNumber(), (tryY+tryH/2).toNumber(), Graphics.FONT_TINY, "Try", center);
            } else {
                dc.setColor(Graphics.COLOR_LT_GRAY,-1);
                dc.drawRoundedRectangle(tryX.toNumber(), tryY.toNumber(), tryW.toNumber(), tryH.toNumber(), (tryH*.2).toNumber());
                dc.setColor(Graphics.COLOR_BLUE,-1);
                dc.drawText((tryX+tryW/2).toNumber(), (tryY+tryH/2).toNumber(), Graphics.FONT_TINY, "Try", center);
            }
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}

function newgame() as Void {
    var tmp = Math.rand() % puzzles.size();
    game = {
        "ver" => 1,
        "state" => 0,
        "segments" => 0,
        "puzzle" => puzzles[tmp],
        "status" => [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    };
    Storage.setValue("game",game);
    selected = -1;
}

function addStats() as Void {
    var stats = Storage.getValue("stats");
    var segments = game.get("segments");
    if (stats == null) {
        stats = [0,0,0,0,0,0,0];
    }
    stats[segments]++;
    Storage.setValue("stats",stats);
}

function showStats() {
    var stats = Storage.getValue("stats");
    if (stats == null) { return; }
    var menu = new WatchUi.CustomMenu(45, Graphics.COLOR_BLACK,{
        :title => new $.DrawableMenuTitle(),
        :titleItemHeight => 70
    });
    var labels = ["Perfect","Head","Body","1 Arm","2 Arms","1 Leg","RIP"];
    var total = 0;
    var max = 0;
    for (var i=0;i<stats.size();i++) {
        if (stats[i] > max) { max = stats[i]; }
        total += stats[i];
    }
    for (var i=0;i<stats.size();i++) {
        menu.addItem(new $.CustomItem(i,labels[i],stats[i],total,max));
    }
    WatchUi.pushView(menu, new $.HangmanStatsDelegate(), WatchUi.SLIDE_UP);
    WatchUi.requestUpdate();
}

class HangmanStatsDelegate extends WatchUi.Menu2InputDelegate {
    public function initialize() {
        Menu2InputDelegate.initialize();
    }

    public function onSelect(item as MenuItem) {
        return;
    }

    public function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class DrawableMenuTitle extends WatchUi.Drawable {
    public function initialize() {
        Drawable.initialize({});
    }
    
    public function draw(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE,Graphics.COLOR_BLACK);
        dc.clear();
        dc.drawText(dc.getWidth()/2,(dc.getHeight()*.7).toNumber(),Graphics.FONT_SMALL,"Statistics",center);
        dc.setPenWidth(3);
        dc.drawLine(0,dc.getHeight(),dc.getWidth(),dc.getHeight());
    }
}

class CustomItem extends WatchUi.CustomMenuItem {
    private var _id as Number;
    private var _label as String;
    private var _count as Number;
    private var _total as Number;
    private var _max as Number;

    public function initialize(id as Number, label as String, count as Number, total as Number, max as Number) {
        CustomMenuItem.initialize(id, {});
        _id = id;
        _label = label;
        _count = count;
        _total = total;
        _max = max;
    }

    public function draw(dc as Dc) as Void {
        // Fill background horizontally based on percentage
        var w = dc.getWidth();
        var h = dc.getHeight();
        var bx = w/8;
        var bw = w*6/8;
        var lx = bx;
        var cx = (w*.65).toNumber();
        var px = bx+bw;
        var pct = (_count*1.0/_total*100).toNumber();
        var mpct = (_max*1.0/_total*100).toNumber();
        mpct = 1-((mpct-pct)*1.0/mpct);
        dc.setColor(Graphics.COLOR_DK_GRAY,-1);
        dc.fillRectangle(bx,0,(bw*mpct).toNumber(),h);
        if (_id == 6) { dc.setColor(Graphics.COLOR_RED,-1); }
        else { dc.setColor(Graphics.COLOR_GREEN,-1); }
        dc.drawText(lx,h/2,Graphics.FONT_TINY,_label,Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_BLUE,-1);
        dc.drawText(cx,h/2,Graphics.FONT_TINY,_count,Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_YELLOW,-1);
        dc.drawText(px,h/2,Graphics.FONT_TINY,pct+"%",Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class HangmanSettings extends WatchUi.Menu2 {
    public function initialize() {
        Menu2.initialize(null);
        Menu2.setTitle("Settings");

        var keyboardicon = new $.CustomIcon(keyboard);
        var themeicon = new $.CustomIcon(theme);

        Menu2.addItem(new WatchUi.IconMenuItem("Keyboard", keyboards[keyboard], "keyboard", keyboardicon, null));
        Menu2.addItem(new WatchUi.IconMenuItem("Theme", themes[theme], "theme", themeicon, null));
    }
}

class CustomIcon extends WatchUi.Drawable {
    private var _index as Number;

    public function initialize(index as Number) {
        _index = index;
        Drawable.initialize({});
    }

    public function draw(dc as Dc) as Void {
        dc.setColor(-1,-1);
        dc.clear();
    }
}