import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Application.Storage;
import Toybox.Math;
import Toybox.Lang;

var DS = System.getDeviceSettings();
var SW = DS.screenWidth;
var SH = DS.screenHeight;
var centerX = SW/2;
var centerY = SH/2;

var game,state,pegs,colors,tries,dups,peg,res,sol,row,col,stats,wins,rows,losses;
var boardXY,boardWH,boardR,pegXY,pegR,solXY,coverXY,coverWH,resXY,resR,ridgeXY,ridgeWH,ridgeR,colXY,colR;
var dupXY,dupWH,newXY,newWH,clearXY,clearWH,guessXY,guessWH,quitXY,quitWH,statsXY,statsWH,buttonR,msgXY;
var adjtriesXY,adjtriesWH,adjpegsXY,adjpegsWH,adjcolorsXY,adjcolorsWH;
var mydc,so,tmp,tmp2,tmp3,tmp4,tmp5,tmpx,tmpy,tmpa1,tmpa2;

var bcolor = 0x906050;
var lcolor = 0xbbbbbb;
var dcolor = 0x333333;
var scolor = 0x222222;
var acolor = 0x6aa8a9;
var ccolor = 0x744d40;
var dupcolor = acolor;
var newcolor = acolor;
var clearcolor = acolor;
var guesscolor = acolor;
var statscolor = acolor;
var nopecolor = 0x808080;
var selcolor = Graphics.COLOR_YELLOW;

var pegcolors = [0xfc3214, 0x02c753, 0x047bd7, 0xd6d905, 0xf99f00, 0xbb9150, 0xd9dbca, 0x3d3d3d];
var rescolors = [0xffffff, 0x000000];

var center = Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER;
var left = Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER;
var right = Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER;

var maxtries = 12;
var mintries = 8;
var maxpegs = 6;
var minpegs = 3;
var maxcolors = 8;
var mincolors = 6;

class MastermindView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        loadgame();
        getcoordinates();
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        mydc = dc;
        mydc.setColor(Graphics.COLOR_BLACK,Graphics.COLOR_BLACK);
        mydc.clear();

        loadgame();

        // Draw screen
        if (state == 0) { getcoordinates(); }

        drawridge(boardXY,boardWH,boardR);

        for (var i=0;i<ridgeXY.size();i++) {
            drawridge(ridgeXY[i],ridgeWH,ridgeR);
        }

        if (state == 2) {
            for (var i=0;i<solXY.size();i++) {
                tmp = sol[i];
                if (tmp != null) { tmp = pegcolors[tmp]; }
                drawpeg(solXY[i],pegR,tmp,false);
            }
        } else {
            drawcover();
        }

        for (var i=0;i<pegXY.size();i++) {
            for (var j=0;j<pegXY[i].size();j++) {
                tmp = peg[i][j];
                if (tmp != null) { tmp = pegcolors[tmp]; }
                drawpeg(pegXY[i][j],pegR,tmp,(state == 1 and row==i and col==j));
            }
        }
        for (var i=0;i<resXY.size();i++) {
            for (var j=0;j<resXY[i].size();j++) {
                tmp = res[i][j];
                if (tmp != null) { tmp = rescolors[tmp]; }
                drawpeg(resXY[i][j],resR,tmp,false);
            }
        }

        switch (state) {
            case 0:
                // Draw tries adjustment button
                drawbutton(adjtriesXY,adjtriesWH,"",acolor,true);
                tmp = adjtriesXY[0]+adjtriesWH[0]/2;
                tmp2 = adjtriesXY[1]+adjtriesWH[0]/2;
                mydc.setColor(lcolor,-1);
                mydc.drawText(adjtriesXY[0]-SW*7/100, tmp2, Graphics.FONT_TINY, tries, right);
                if (tries == maxtries) { mydc.setColor(nopecolor,-1); }
                else { mydc.setColor(Graphics.COLOR_BLACK,-1); }
                mydc.drawText(tmp,tmp2,Graphics.FONT_SMALL,"+",center);
                tmp2 = adjtriesXY[1]+adjtriesWH[1]-adjtriesWH[0]/2;
                if (tries == mintries) { mydc.setColor(nopecolor,-1); }
                else { mydc.setColor(Graphics.COLOR_BLACK,-1); }
                mydc.drawText(tmp,tmp2,Graphics.FONT_MEDIUM,"-",center);
                tmp2 = [adjtriesWH[0]*85/100, adjtriesWH[1]*8/100];
                tmp = [adjtriesXY[0]*105/100, adjtriesXY[1]+adjtriesWH[1]/2-tmp2[1]*80/100];
                drawridge(tmp,tmp2,ridgeR/4);
                tmp = [adjtriesXY[0]*105/100, adjtriesXY[1]+adjtriesWH[1]/2+tmp2[1]*80/100];
                drawridge(tmp,tmp2,ridgeR/4);

                // Draw duplicate option button
                drawbutton(dupXY,dupWH,"",dupcolor,true);
                if (dups) { tmp = 0; }
                else { tmp = 1; }
                drawpeg([dupXY[0]+dupWH[0]*20/100,dupXY[1]+dupWH[1]/2],pegR,pegcolors[0],false);
                drawpeg([dupXY[0]+dupWH[0]*50/100,dupXY[1]+dupWH[1]/2],pegR,pegcolors[tmp],false);
                drawpeg([dupXY[0]+dupWH[0]*80/100,dupXY[1]+dupWH[1]/2],pegR,pegcolors[2],false);

                // Draw start button                
                drawbutton(newXY,newWH,"Start",newcolor,true);

                // Draw peg count adjustment button
                drawbutton(adjpegsXY,adjpegsWH,"",acolor,true);
                tmp = adjpegsXY[0]+adjpegsWH[0]/2;
                tmp2 = adjpegsXY[1]+adjpegsWH[0]/2;
                if (pegs == maxpegs) { mydc.setColor(nopecolor,-1); }
                else { mydc.setColor(Graphics.COLOR_BLACK,-1); }
                mydc.drawText(tmp,tmp2,Graphics.FONT_SMALL,"+",center);
                tmp2 = adjpegsXY[1]+adjpegsWH[1]-adjpegsWH[0]/2;
                if (pegs == minpegs) { mydc.setColor(nopecolor,-1); }
                else { mydc.setColor(Graphics.COLOR_BLACK,-1); }
                mydc.drawText(tmp,tmp2,Graphics.FONT_MEDIUM,"-",center);
                mydc.setColor(lcolor,-1);
                mydc.drawText(adjpegsXY[0]-SW*7/100, tmp2, Graphics.FONT_TINY, pegs, right);
                tmp2 = adjpegsXY[1]+adjpegsWH[1]/2;
                drawpeg([tmp,tmp2],pegR,null,false);

                // Draw colors
                for (var i=0;i<colors;i++) {
                    drawcirclebutton(colXY[i],colR,"",pegcolors[i]);
                }

                // Draw color adjustment buttons
                drawbutton(adjcolorsXY[0],adjcolorsWH,"",acolor,(colors<maxcolors));
                tmp = adjcolorsXY[0][0]+adjcolorsWH[0]/2;
                tmp2 = adjcolorsXY[0][1]+adjcolorsWH[0]/2;
                if (colors == maxcolors) { mydc.setColor(nopecolor,-1); }
                else { mydc.setColor(Graphics.COLOR_BLACK,-1); }
                mydc.drawText(tmp,tmp2,Graphics.FONT_SMALL,"+",center);
                
                drawbutton(adjcolorsXY[1],adjcolorsWH,"",acolor,(colors>mincolors));
                tmp = adjcolorsXY[1][0]+adjcolorsWH[0]/2;
                tmp2 = adjcolorsXY[1][1]+adjcolorsWH[0]/2;
                if (colors == mincolors) { mydc.setColor(nopecolor,-1); }
                else { mydc.setColor(Graphics.COLOR_BLACK,-1); }
                mydc.drawText(tmp,tmp2,Graphics.FONT_MEDIUM,"-",center);
                break;
            case 1:
                tmp = false;
                tmp2 = true;
                for (var i=0;i<pegs;i++) {
                    if (peg[row][i] == null) { tmp2 = false; }
                    else { tmp = true; }
                }
                drawbutton(clearXY,clearWH,"Clear",clearcolor,tmp);
                drawbutton(guessXY,guessWH,"Guess",guesscolor,tmp2);
                
                for (var i=0;i<colors;i++) {
                    drawcirclebutton(colXY[i],colR,"",pegcolors[i]);
                }
                break;
            case 2:
                drawbutton(statsXY,statsWH,"Stats",statscolor,true);
                drawbutton(newXY,newWH,"New",newcolor,true);

                mydc.setColor(lcolor,-1);
                if (row >= tries) { tmp = "You\nlost"; }
                else { tmp = "You\nwon!"; }
                mydc.drawText(msgXY[0],msgXY[1],Graphics.FONT_TINY,tmp,left);
        }
    }

    function drawridge(xy,wh,r) {
        var w = wh[0];
        var h = wh[1];
        mydc.setColor(lcolor,-1);
        mydc.fillRoundedRectangle(xy[0]-1,xy[1]-h/2-1,w,h,r);
        mydc.setColor(dcolor,-1);
        mydc.fillRoundedRectangle(xy[0]+1,xy[1]-h/2+1,w,h,r);
        mydc.setColor(bcolor,-1);
        mydc.fillRoundedRectangle(xy[0],xy[1]-h/2,w,h,r);
    }

    function drawbutton(xy,wh,t,c,v) {
        mydc.setColor(lcolor,-1);
        mydc.fillRoundedRectangle(xy[0]-1,xy[1]-1,wh[0],wh[1],buttonR);
        mydc.setColor(dcolor,-1);
        mydc.fillRoundedRectangle(xy[0]+1,xy[1]+1,wh[0],wh[1],buttonR);
        mydc.setColor(c,-1);
        mydc.fillRoundedRectangle(xy[0],xy[1],wh[0],wh[1],buttonR);
        if (v) { mydc.setColor(Graphics.COLOR_BLACK,-1); }
        else { mydc.setColor(nopecolor,-1); }
        mydc.drawText(xy[0]+wh[0]/2,xy[1]+wh[1]/2-1,Graphics.FONT_XTINY,t,center);
    }

    function drawcirclebutton(xy,r,t,c) {
        mydc.setColor(lcolor,-1);
        mydc.fillCircle(xy[0]-1,xy[1]-1,r);
        mydc.setColor(dcolor,-1);
        mydc.fillCircle(xy[0]+1,xy[1]+1,r);
        mydc.setColor(c,-1);
        mydc.fillCircle(xy[0],xy[1],r);
        mydc.setColor(Graphics.COLOR_BLACK,-1);
        mydc.drawText(xy[0],xy[1]-1,Graphics.FONT_TINY,t,center);
    }

    // xy is the x,y coordinate
    // c is the color index (null if not filled)
    function drawpeg(xy,r,c,s) {
        if (c == null) {
            mydc.setColor(dcolor,-1);
            mydc.fillCircle(xy[0]-1,xy[1]-1,r);
            mydc.setColor(lcolor,-1);
            mydc.fillCircle(xy[0]+1,xy[1]+1,r);
            mydc.setColor(bcolor,-1);
            mydc.fillCircle(xy[0],xy[1],r);

            mydc.setColor(scolor,-1);
            mydc.fillCircle(xy[0]-1,xy[1]-1,r/2);
            mydc.setColor(lcolor,-1);
            mydc.fillCircle(xy[0]+1,xy[1]+1,r/2);
            mydc.setColor(dcolor,-1);
            mydc.fillCircle(xy[0],xy[1],r/2);
        } else {
            mydc.setColor(lcolor,-1);
            mydc.fillCircle(xy[0]-1,xy[1]-1,r);
            mydc.setColor(dcolor,-1);
            mydc.fillCircle(xy[0]+1,xy[1]+1,r);

            mydc.setColor(c,-1);
            mydc.fillCircle(xy[0],xy[1],r);
        }
        if (s) {
            mydc.setColor(selcolor,-1);
            mydc.setPenWidth(2);
            mydc.drawCircle(xy[0],xy[1],r+1);
        }

    }

    function drawcover() {
        var xy = coverXY;
        var w = coverWH[0];
        var h = coverWH[1];
        // draw a trapezoid
        mydc.setColor(lcolor,-1);
        mydc.fillRoundedRectangle(xy[0]-1,xy[1]-h/2-1,w,h,2);
        mydc.setColor(dcolor,-1);
        tmp = [
            [xy[0]+1,xy[1]-h/2+1],
            [xy[0]+w+h*20/100+1,xy[1]-h/2+1],
            [xy[0]+w+1,xy[1]+h/2+1],
            [xy[0]+1,xy[1]+h/2+1]
        ];
        mydc.fillPolygon(tmp);
        mydc.setColor(ccolor,-1);
        mydc.fillRoundedRectangle(xy[0],xy[1]-h/2,w,h,2);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}

function getcoordinates() {
    // Define screen areas and sizes
    boardWH = [SW*50/100,SH*87/100];
    tmp = boardWH[1];
    tmp3 = boardWH[0];
    boardXY = [(SW-tmp3)/2,SH/2];
    tmp2 = tmp/(tries+1);   // try height
    tmpy = (SH-tmp+tmp2)/2; // first try row Y coordinate
    ridgeWH = [tmp3*95/100,tmp2*93/100];
    coverWH = [ridgeWH[0]*80/100,ridgeWH[1]];
    pegR = ridgeWH[1]*30/100;
    resR = pegR*30/100;
    ridgeR = pegR;
    boardR = ridgeR*7/5;
    buttonR = ridgeR*2/3;

    ridgeXY = [];
    coverXY = [];
    solXY = [];
    pegXY = [];
    resXY = [];
    tmpx = (SW-ridgeWH[0])/2;
    for (var i=0;i<tries+1;i++) {
        // Try peg coordinates
        tmp3 = [];
        tmp4 = (ridgeWH[0]*80/100-tmp2)/(pegs-1);
        for (var j=0;j<pegs;j++) {
            tmp3.add([tmpx+tmp2/2+j*tmp4,tmpy]);
        }
        if (i==0) {
            solXY = tmp3;
            coverXY = [tmpx,tmpy];
        } else {
            pegXY.add(tmp3);
            // Result peg coordinates
            tmp3 = [];
            tmp4 = ridgeWH[1]*25/100;
            tmp5 = tmpx+ridgeWH[0]*90/100;
            switch (pegs) {
                case 3:
                    tmp3.add([tmp5-tmp4,tmpy]);
                    tmp3.add([tmp5,tmpy]);
                    tmp3.add([tmp5+tmp4,tmpy]);
                    break;
                case 4:
                    tmp3.add([tmp5-tmp4,tmpy-tmp4]);
                    tmp3.add([tmp5+tmp4,tmpy-tmp4]);
                    tmp3.add([tmp5-tmp4,tmpy+tmp4]);
                    tmp3.add([tmp5+tmp4,tmpy+tmp4]);
                    break;
                case 5:
                    tmp3.add([tmp5-tmp4,tmpy-tmp4]);
                    tmp3.add([tmp5+tmp4,tmpy-tmp4]);
                    tmp3.add([tmp5,tmpy]);
                    tmp3.add([tmp5-tmp4,tmpy+tmp4]);
                    tmp3.add([tmp5+tmp4,tmpy+tmp4]);
                    break;
                case 6:
                    tmp3.add([tmp5-tmp4,tmpy-tmp4]);
                    tmp3.add([tmp5,tmpy-tmp4]);
                    tmp3.add([tmp5+tmp4,tmpy-tmp4]);
                    tmp3.add([tmp5-tmp4,tmpy+tmp4]);
                    tmp3.add([tmp5,tmpy+tmp4]);
                    tmp3.add([tmp5+tmp4,tmpy+tmp4]);
                    break;
            }
            resXY.add(tmp3);
            // Ridge / try area coordinates
            ridgeXY.add([tmpx,tmpy]);
        }
        tmpy += tmp2;
    }
    pegXY = pegXY.reverse();
    resXY = resXY.reverse();
    ridgeXY = ridgeXY.reverse();

    // Adjust board size coordinates
    adjcolorsXY = [
        [SW*59/100,SH*33/100],
        [SW*59/100,SH*51/100]
    ];
    adjcolorsWH = [SW*16/100,SW*16/100];
    adjtriesXY = [SW*25/100,SH*10/100];
    adjtriesWH = [SW*16/100,SH*39/100];
    adjpegsXY = [SW*25/100,SH*51/100];
    adjpegsWH = [SW*16/100,SH*39/100];

    // Adjust colors, tries, and pegs button coordinates
    adjcolorsXY = [
        [SW*56/100,SH*33/100],
        [SW*56/100,SH*51/100]
    ];
    adjcolorsWH = [SW*16/100,SW*16/100];
    adjtriesXY = [SW*28/100,SH*17/100];
    adjtriesWH = [SW*16/100,SH*32/100];
    adjpegsXY = [SW*28/100,SH*51/100];
    adjpegsWH = [SW*16/100,SH*32/100];

    // Color selector coordinates
    colR = SH*5/100;
    colXY = [];

    tmp = colors-3;
    tmp2 = colR*9/4;

    tmpy = (SH-tmp2*(tmp-1))/2;
    for (var i=0;i<tmp;i++) {
        colXY.add([SW*82/100,tmpy+i*tmp2]);
    }
    tmp = colors-tmp;
    tmpy = (SH-tmp2*(tmp-1))/2;
    for (var i=0;i<tmp;i++) {
        colXY.add([SW*82/100+tmp2,tmpy+i*tmp2]);
    }

    // Duplicate allowed button coordinates
    dupXY = [SW*3/100,SH*33/100];
    dupWH = [SW*19/100,SH*16/100];

    // Start / new game button coordinates
    newXY = [SW*3/100,SH*51/100];
    newWH = [SW*19/100,SH*16/100];

    // Clear button coordinates
    clearXY = [SW*3/100,SH*33/100];
    clearWH = [SW*19/100,SH*16/100];

    // Guess button coordinates
    guessXY = [SW*3/100,SH*51/100];
    guessWH = [SW*19/100,SH*16/100];

    // Stats button coordinates
    statsXY = [SW*3/100,SH*33/100];
    statsWH = [SW*19/100,SH*16/100];

    msgXY = [SW*77/100,SH/2];
}

function setresult() {
    tmp = 0;
    var tmpa = [];
    var tmpb = [];
    for (var i=0;i<pegs;i++) {
        tmpa.add(sol[i]);
        tmpb.add(peg[row][i]);
    }
    for (var i=0;i<pegs;i++) {
        if (tmpb[i] == tmpa[i]) {
            tmpa[i] = null;
            tmpb[i] = -1;
            res[row][tmp] = 1;
            tmp++;
        }
    }
    if (tmp == pegs) {
        addstats(true);
        state++;
    } else {
        for (var i=0;i<pegs;i++) {
            for (var j=0;j<pegs;j++) {
                if (tmpb[i] == tmpa[j]) {
                    tmpa[j] = null;
                    tmpb[i] = -1;
                    res[row][tmp] = 0;
                    tmp++;
                    break;
                }
            }
        }
        row++;
        col = 0;
        if (row >= tries) {
            addstats(false);
            state++;
        }
    }
}

function newgame() {
    peg = [];
    res = [];
    sol = [null,null,null,null,null,null];
    for (var i=0;i<12;i++) {
        tmpa1 = [];
        tmpa2 = [];
        for (var j=0;j<6;j++) {
            tmpa1.add(null);
            tmpa2.add(null);
        }
        peg.add(tmpa1);
        res.add(tmpa2);
    }
    row = 0;
    col = 0;
    state = 0;
    savegame();
}

function newgame2() {
    peg = [];
    res = [];
    sol = [];
    for (var i=0;i<tries;i++) {
        tmpa1 = [];
        tmpa2 = [];
        for (var j=0;j<pegs;j++) {
            tmpa1.add(null);
            tmpa2.add(null);
        }
        peg.add(tmpa1);
        res.add(tmpa2);
    }
    var tmpa = [];
    for (var i=0;i<colors;i++) {
        tmpa.add(i);
    }
    for (var i=0;i<pegs;i++) {
        tmp = Math.rand() % tmpa.size();
        sol.add(tmpa[tmp]);
        if (!dups) {
            tmpa.remove(tmpa[tmp]);
        }
    }
}

function savegame() {
    game = {
        "ver" => 1,
        "state" => state,
        "pegs" => pegs,
        "colors" => colors,
        "tries" => tries,
        "dups" => dups,
        "peg" => peg,
        "res" => res,
        "sol" => sol,
        "row" => row,
        "col" => col
    };
    Storage.setValue("game",game);
}

function loadgame() {
    game = Storage.getValue("game");
//    game = null;
    if (game == null) { 
        pegs = 4;
        tries = 9;
        dups = false;
        colors = 6;
        newgame();
    }
    state = game.get("state");
    pegs = game.get("pegs");
    colors = game.get("colors");
    tries = game.get("tries");
    dups = game.get("dups");
    peg = game.get("peg");
    res = game.get("res");
    sol = game.get("sol");
    row = game.get("row");
    col = game.get("col");
}

function addstats(won) {
    stats = Storage.getValue("stats");
    if (stats == null) {
        wins = 0;
        rows = [0,0,0,0,0,0,0,0,0,0,0,0];
        losses = 0;
        stats = {
            "wins" => wins,
            "rows" => rows,
            "losses" => losses
        };
    }
    wins = stats.get("wins");
    rows = stats.get("rows");
    losses = stats.get("losses");
    if (won) { wins++; rows[row]++; }
    else { losses++; }
    stats.put("wins",wins);
    stats.put("rows",rows);
    stats.put("losses",losses);
    Storage.setValue("stats",stats);
}

function showstats() {
    var stats = Storage.getValue("stats") as Dictionary;
    if (stats == null) { return; }
    wins = stats.get("wins") as Number;
    rows = stats.get("rows") as Array;
    losses = stats.get("losses") as Number;
    var menu = new WatchUi.CustomMenu(45, Graphics.COLOR_BLACK,{
        :title => new $.DrawableMenuTitle(),
        :titleItemHeight => 70
    });
    rows = rows.reverse();
    var labels = ["12 Tries","11 Tries","10 Tries","9 Tries","8 Tries","7 Tries","6 Tries","5 Tries","4 Tries","3 Tries","2 Tries","1 Try"];
    var total = 0;
    var max = 0;
    for (var i=0;i<rows.size();i++) {
        if (rows[i] > max) { max = rows[i]; }
    }
    if (losses > max) { max = losses; }
    total = wins + losses;
    for (var i=0;i<rows.size();i++) {
        menu.addItem(new $.CustomItem(i,labels[i],rows[i],total,max));
    }
    menu.addItem(new $.CustomItem(-1,"Losses",losses,total,max));
    WatchUi.pushView(menu, new $.MastermindStatsDelegate(), WatchUi.SLIDE_UP);
    WatchUi.requestUpdate();
}

class MastermindStatsDelegate extends WatchUi.Menu2InputDelegate {
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
        if (_id == -1) { dc.setColor(Graphics.COLOR_RED,-1); }
        else { dc.setColor(Graphics.COLOR_GREEN,-1); }
        dc.drawText(lx,h/2,Graphics.FONT_TINY,_label,Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_BLUE,-1);
        dc.drawText(cx,h/2,Graphics.FONT_TINY,_count,Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_YELLOW,-1);
        dc.drawText(px,h/2,Graphics.FONT_TINY,pct+"%",Graphics.TEXT_JUSTIFY_RIGHT|Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
