import flash.events.MouseEvent;
import flash.ui.Mouse;
import flash.utils.Timer;
import flash.events.TimerEvent;
import masc.tags.AnalogInput;

var enableContainer:Boolean=false;
var editingT:Boolean=false;
var textTar:*;
var bolVal:Boolean;
var val:XML;
var mObj:Object;

var mainData:Object=new Object();
var vplc:Boolean=false;
var container:MovieClip=new MovieClip();
var menuBtns:MovieClip=new MovieClip();
var projectFile:File=new File();
var so:SharedObject = SharedObject.getLocal("kmasc");
var lastProject:DataProvider=new DataProvider();
var initT:Timer=new Timer(2000);
var mascFilter:FileFilter=new FileFilter("Проекты котельных MASC","*.kmasc;*.xml");
var projectXML:XML=new XML('<config><Servers></Servers><Sources></Sources><Objects></Objects></config>');
var activeObj:Array=[]; //----------------Переделать чтоб при получении отправлять всем подрисанным активным объектам--activeObj[]-----------------------------//
var insWindArr:Array=[];
var sourceArr:Array=[];
var iconArr:Array=[];
var activePage:uint=4294967295;
var cycleTrigger:String="ENTER_FRAME";
var clientWins:Array=[];
var numPadArr:Array=[];
var myPubs:Vector.<String>=new Vector.<String>();
var kotelnie:Array=[];
var firstRun:Boolean=false;
var tables:Array=[]; //Массив таблиц для процессов определения SP

var updateTimer:Timer=new Timer(100000);

var wM:Number=(stage.fullScreenWidth/stage.stageWidth);
var hM:Number=(stage.fullScreenHeight/stage.stageHeight);
trace("Соотношение сторон окна приложения и собственно экрана окна: "+stage.fullScreenWidth,stage.stageWidth,wM,stage.fullScreenHeight,stage.stageHeight,hM);

var autoStart:Boolean=false;
var iter:Number=0; 

var options:NativeWindowInitOptions = new NativeWindowInitOptions(); 
options.systemChrome = NativeWindowSystemChrome.NONE; 
options.type = NativeWindowType.NORMAL;
//options.type = NativeWindowType.UTILITY 
options.resizable = false; 
options.maximizable = false;
options.transparent = true;

var targ:*; var evt:*;
stage.addEventListener(MouseEvent.MOUSE_DOWN, getMDown);
stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, getRDown);
function getRDown(e:MouseEvent):void{
	if (e.target==stage) return;
	targ=e.target; //trace(targ.name);
	targ.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, getRUp);
}
function getRUp(e:MouseEvent):void{
	targ.stage.removeEventListener(MouseEvent.MOUSE_UP, getRUp);
	if (targ==stage) return;
	if (e.target==targ) {
		if (targ is FizAI) {trace("Clicked fizAI. Opening settings"); setsFizAI(targ); return;}
	}
}
function getMDown(e:MouseEvent):void{
	if (e.target==stage) return;
	targ=e.target; //trace(targ.name);
	if (targ.name=="dragWin") {trace("Start dragging window mode is vplc="+vplc); if (vplc==true) {dragWindow(e);} else {dragParent(targ);} return;}
	if (targ.name=="dragPar") {dragParent(e); return;}
	if (targ.name=="headSl"){setSlMove(targ); return;}
	targ.stage.addEventListener(MouseEvent.MOUSE_UP, getMUp);
}
function getMUp(e:MouseEvent):void{
	targ.stage.removeEventListener(MouseEvent.MOUSE_UP, getMUp);
	if (targ==stage) return;
	if (e.target==targ) {
		if (targ.name=="closeWin") {closeWin(e); return;}
		if (targ.name=="fullWin") {fullWin(e); return;}
		if (targ.name.substr(0,7)=="getSrc_"){trace("Get Source for target data");}
		if (targ is PushBtn) {trace("Clicked PushButton. Send new status data"); insertPushBtn(targ); return;}
		if (targ is SlideBtn) {trace("Clicked SlideButton. Send new status data"); insertPushBtn(targ); return;}
		if (targ is FizAI) {trace("Clicked fizAI. Opening numpad for input"); setNumPad(targ,"MASC/tags/AI/"+targ.num,"SP",targ.SP); return;}
		
	
		if (targ is KlapanD) {trace("Clicked KlapanD. Send new status data"); return;}
		if (targ is PumpD) {trace("Clicked PumpD. Send new status data"); return}
		if (targ is TextData) {trace("Clicked TextData. Opening numpad for input"); setNumPad(targ,targ.dst,"fiz",targ.fiz); return;}
		if (targ is KlapanA) {trace("Clicked KlapanA. Opening numpad for input"); setNumPad(targ,"MASC/tags/DA/"+targ.num,"MV",targ.MV); return;}
		if (targ.name.substr(0,3)=="dig"){evt=e; enterDigitData(targ);}
		if (targ is Kotel0) {trace("Kotel pressed")}
		if (targ is ObjectBtn) {trace("Some object btn pressed pressed"); processObjBtn(targ)}
		if (targ is ModeAM) {processMode(targ)}
		getMClick(e);
	}
}

function enterDigitData(targ:*):void{
	var pad:NumPad = targ.parent;
	var digit:String=targ.name.substring(3,targ.name.length);
	if (digit.length>4) digit=digit.split("_")[0];
	trace(digit);
	if (int(digit)>0 || digit=="0") pad.val_txt.appendText(digit);
	switch (digit) {
		case "C": pad.val_txt.text=""; break
		case "R": pad.val_txt.text=pad.val_txt.text.substr(0,pad.val_txt.text.length-1); break;
		case "Dot": if (pad.val_txt.text.indexOf(".")==-1) pad.val_txt.appendText("."); break;
		case "M": if (pad.val_txt.text.indexOf("-")==-1) pad.val_txt.text="-"+pad.val_txt.text; else pad.val_txt.text=pad.val_txt.text.substring(1,pad.val_txt.text.length); break;
		case "OK": if (pad.val_txt.length>0) {pad.val=Number(pad.val_txt.text); insertNumPad(pad);} 
			closeWin(evt);
		break;
		case "X": closeWin(evt); break;
	}
	pad.sVal_txt.visible=Boolean(pad.val_txt.length==0);
}

function removePar(e:MouseEvent):void{
	var par = e.target.parent;
	if (par is NumPad) numPadArr.splice(numPadArr.indexOf(par),1);
	removeChild(par);
}
function dragParent(target:*):void{
	targ=target; targ.parent.startDrag();
	targ.stage.addEventListener(MouseEvent.MOUSE_UP, dropParent);
}
function dropParent(e:MouseEvent):void{
	targ.parent.stopDrag();
	targ.stage.removeEventListener(MouseEvent.MOUSE_UP, dropParent);
}
function dragWindow(e:*):void{trace("Drag window init"); var window:NativeWindow = e.target.stage.nativeWindow; window.startMove();}
function closeWin(e:*):void{
	trace("close window init"); 
	if (vplc) {
		var window:NativeWindow = e.target.stage.nativeWindow;
		var clW:Number=clientWins.indexOf(window);
		if (clW >=0) {clientWins.splice(clW,1); trace("Removed client window. Total now="+clientWins.length);}
		var par = e.target.parent;
		if (par is NumPad) numPadArr.splice(numPadArr.indexOf(par),1);
		window.close();	
		try {
			window.stage.removeEventListener(MouseEvent.MOUSE_DOWN,getMDown);
			window.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, getRDown);
		} catch (Error:*) {"No MouseDown event for his window"}
	} else {
		removePar(e);
	}
}
function fullWin(e:*):void{
	if (vplc) {var window:NativeWindow = e.target.stage.nativeWindow; window.stage.scaleMode=StageScaleMode.NO_SCALE; window.x=window.y=0;}
}

stopRuntime_btn.visible=startWindow.visible=false;
initT.addEventListener(TimerEvent.TIMER, noProjectLoaded);
initT.start();

function windowAddAI():void{
	var win:WinAddAI=new WinAddAI();
	trace("Opening a new window with size "+win.width, win.height);
	win.doAI_btn.addEventListener(MouseEvent.CLICK, addNewAI);
	win.close_btn.addEventListener(MouseEvent.CLICK, closeWinAI);
	win.type_cb.addEventListener(Event.CHANGE, changeTypeAI);
	win.getSrc_src.addEventListener(MouseEvent.CLICK, getSource);
	win.labels1.visible=win.mltp.visible=false;
	
	if (vplc==true) {
		var window:NativeWindow = new NativeWindow(options);
		window.title="Добавление AI";
		window.width=300;
		window.height=200;
		window.stage.align = StageAlign.TOP_LEFT;
		window.stage.scaleMode=StageScaleMode.NO_SCALE;
		window.stage.addChild(win);
		window.activate();
		trace(stage.mouseX,stage.mouseY, win.width,win.height);
		window.x=stage.fullScreenWidth/2-win.width/2; window.y=stage.fullScreenHeight/2-win.height/2;
		window.stage.addEventListener(MouseEvent.MOUSE_DOWN,getMDown);
	} else {
	//if (vplc) {window.x=stage.fullScreenWidth/2-win.width/2; window.y=stage.fullScreenHeight/2-win.height/2;} else {window.x=stage.mouseX-win.width/2; window.y=stage.mouseY-win.height/2;}
		win.x=stage.mouseX-win.width/2; win.y=stage.mouseY-win.height/2;
		checkBounds(win,10);
		addChild(win);
	}
}
function setsFizAI(aiFiz:FizAI):void{
	var win:WinPropAI=new WinPropAI();
	trace("Opening a new window with size "+win.width, win.height);
	win.close_btn.addEventListener(MouseEvent.CLICK, closeFizAI);
	win.config_btn.addEventListener(MouseEvent.CLICK, confAI);
	win.srcSP_cb.addEventListener(Event.CHANGE, setSrcSP);
	win.num_txt.text=(aiFiz.num).toString();
	
	var ns=projectXML.namespace();
	
	for each (var ai in projectXML..ns::PLC..ns::ai) {
		//----------Новый способ добавления Аналоговых сигналов----------//
		if (ai.@num==aiFiz.num){
			trace("Found AI in project XML. Num is "+ai.@num);
			for each (var par:XML in ai.attributes()) win.addProp("ai",ai.num,par.name(),par.valueOf());
			for each (var reg in ai..ns::reg){
				for each (par in reg.attributes()) win.addProp("reg",reg.num,par.name(),par.valueOf());
				for each (var cor in reg..ns::cor){
					for each (par in cor){
						win.addProp("cor",cor.num,par.name(),par.valueOf());
					}
				}
			}
			break;
		}
	}
	
	if (vplc==true) {
		var window:NativeWindow = new NativeWindow(options);
		window.title="Настройка сигнала AI";
		window.width=402; window.height=202;
		window.stage.align = StageAlign.TOP_LEFT;
		window.stage.scaleMode=StageScaleMode.NO_SCALE;
		window.alwaysInFront=true;
		window.stage.addChild(win);
		window.activate();
		trace(stage.mouseX,stage.mouseY, win.width,win.height);
		window.x=targ.stage.nativeWindow.x+targ.stage.mouseX; window.y=targ.stage.nativeWindow.y+targ.stage.mouseY;//window.x=stage.fullScreenWidth/2-win.width/2; window.y=stage.fullScreenHeight/2-win.height/2;
		window.stage.addEventListener(MouseEvent.MOUSE_DOWN,getMDown);
	} else {
	//if (vplc) {window.x=stage.fullScreenWidth/2-win.width/2; window.y=stage.fullScreenHeight/2-win.height/2;} else {window.x=stage.mouseX-win.width/2; window.y=stage.mouseY-win.height/2;}
		win.x=stage.mouseX-win.width/2; win.y=stage.mouseY-win.height/2;
		checkBounds(win,10);
		addChild(win);
	}
}
function setSrcSP(e:Event):void{
	var win:WinPropAI = e.target.parent;
	if (e.target.selectedItem.data=="table"){
		win.src_txt.text="таблица";
		win.t_cb.visible=win.getSrc_srcT.visible=win.srcT.visible=true;
		win.m_stp.visible=win.getSrc_srcM.visible=win.srcM.visible=false;
		
	} else if (e.target.selectedItem.data=="multyp") {
		win.src_txt.text="значение множителя";
		win.t_cb.visible=win.getSrc_srcT.visible=win.srcT.visible=false;
		win.m_stp.visible=win.getSrc_srcM.visible=win.srcM.visible=true;
	} else {
		win.src_txt.text="";
		win.t_cb.visible=win.getSrc_srcT.visible=win.srcT.visible=false;
		win.m_stp.visible=win.getSrc_srcM.visible=win.srcM.visible=false;
	}
}
function closeFizAI(e:MouseEvent):void{
	var win:WinPropAI = e.target.parent;
	win.close_btn.removeEventListener(MouseEvent.CLICK, closeFizAI);
	win.config_btn.removeEventListener(MouseEvent.CLICK, confAI);
	if (vplc) {var window:NativeWindow = win.stage.nativeWindow; window.stage.removeChild(win); window.close();} else removeChild(win);
}

function checkBounds(win:*,space:int):void{
	if (win.x>1920-space-win.width) {win.x=1920-space-win.width}
	if (win.y>1080-space-win.height) {win.y=1080-space-win.height}
	if (win.x<space) win.x=space;
	if (win.y<space) win.y=space;
}
function changeTypeAI(e:Event):void{
	var win:*=e.target.parent;
	var exp:int=e.target.selectedItem.data;
	trace("AI is now type "+exp);
	win.labels0.visible=win.mA_min.visible=win.mA_max.visible=win.cod_min.visible=win.cod_max.visible=win.fiz_min.visible=win.fiz_max.visible=Boolean(exp==0);
	win.labels1.visible=win.mltp.visible=Boolean(exp==1);
}

function getSource(e:MouseEvent):void{
	var win:*=e.target.parent; sourceArr=[];
	var txt:*=win.getChildByName((e.target.name).split("_")[1]);
	var srsWindow:WinGetSrc=new WinGetSrc();
	if (vplc) {
		var window:NativeWindow = new NativeWindow(options);
		window.title="Выбор источника";
		window.width=600;
		window.height=200;
		//if (vplc) {window.x=stage.fullScreenWidth/2-srsWindow.width/2; window.y=stage.fullScreenHeight/2-srsWindow.height/2;} else {window.x=stage.mouseX-srsWindow.width/2; window.y=stage.mouseY-srsWindow.width/2;}
		window.x=stage.fullScreenWidth/2-win.width/2; window.y=stage.fullScreenHeight/2-win.height/2;
		window.stage.align = StageAlign.TOP_LEFT; window.stage.scaleMode=StageScaleMode.NO_SCALE;
		window.stage.addChild(srsWindow);
		window.activate();
		window.stage.addEventListener(MouseEvent.MOUSE_DOWN, getMDown);
	} else {
		srsWindow.x=stage.mouseX-srsWindow.width/2; srsWindow.y=stage.mouseY-srsWindow.width/2;
		addChild(srsWindow);
	}
	srsWindow.txt=txt;
	
	var srcD:DataProvider=new DataProvider();
	trace("Getting data type= "+win.type_cb.selectedItem.data);
	var ns=projectXML.namespace(); var tempArr:Array=[];
	if (win.type_cb.selectedItem.data==0){
		trace("Get data from sources");
		for each (var source in projectXML..ns::Sources..ns::source) {
			trace(source.@id,source.@name,source.@path,source.@enabled);
			tempArr[0]=source.@id; tempArr[1]=source.@name; tempArr[2]=source.@path;
			//sourceArr[source.@id]=tempArr;
			sourceArr.push([tempArr[0],tempArr[1],tempArr[2],tempArr[2]]);
		}
	} else if (win.type_cb.selectedItem.data==1){
		trace("Get data from plc onb");
		for each (source in projectXML..ns::PLC.children()) {
			trace(source.@id,source.@name);
			tempArr[0]=source.@id; tempArr[1]=source.@name;
			var tSt:String=source.name(); trace("Название ноды: "+tSt);
			switch (tSt) {
				case "ai": tempArr[2]="MASC/tags/PLC/AI/"+source.@num; break;
				case "da": tempArr[2]="MASC/tags/PLC/DA/"+source.@num; break;
			}

			sourceArr.push([tempArr[0],tempArr[1],tempArr[1],tempArr[2]]);
		}
	}
	for each (var src in sourceArr){
		trace(src[2]);
		srcD.addItem({label:src[2], data:src[3]});
	}
	srsWindow.srcList.dataProvider=srcD;
	
	srsWindow.addSrs_btn.addEventListener(MouseEvent.CLICK, addSrs);
	srsWindow.srcList.addEventListener(Event.CHANGE, setSource);
	trace("Get source for window "+win.name+" into text field: "+txt.name);
	txt.text="Выбор источника для аналогово входа.....";
}
function closeSrsWin(e:MouseEvent):void{
	var srsWindow:WinGetSrc=e.currentTarget.parent;
	srsWindow.addSrs_btn.removeEventListener(MouseEvent.CLICK, addSrs);
	srsWindow.srcList.removeEventListener(Event.CHANGE, setSource);
	closeWin(e);
}
function addSrs(e:MouseEvent):void{
	var srsWindow:WinGetSrc=e.currentTarget.parent;
	srsWindow.hide();
	if (srsWindow.def) {
		if (srsWindow.def!="") srsWindow.txt.text=srsWindow.src.text+":"+srsWindow.def;
 	} else {
		srsWindow.txt.text=srsWindow.src.text;
	}
	closeSrsWin(e);
}
function setSource(e:Event):void{
	var srsWindow:WinGetSrc=e.currentTarget.parent;
	srsWindow.src.text=srsWindow.srcList.selectedItem.data;
	srsWindow.init();
	getListElements(srsWindow,srsWindow.src.text);
}

function addNewAI(e:MouseEvent):void{
	var win:WinAddAI = e.target.parent;
	win.doAI_btn.removeEventListener(MouseEvent.CLICK, addNewAI);
	win.close_btn.removeEventListener(MouseEvent.CLICK, closeWinAI);
	win.type_cb.removeEventListener(Event.CHANGE, changeTypeAI);
	win.getSrc_src.removeEventListener(MouseEvent.CLICK, getSource);
	
	if (win.src.text=="") return;
	trace("Adding new AI signal!");
	var analogInput:AnalogInput=new AnalogInput();
	analogInput.eu=win.eu.selectedItem.data; if (analogInput.eu=="other") analogInput.eu=win.other.text;
	analogInput.type=win.type_cb.selectedItem.data;
	analogInput.num=0;
	analogInput.addProp("name",win.name_txt.text);
	analogInput.addProp("src",win.src.text);
	analogInput.addProp("filtr",win.filtr.value);
	if (analogInput.type==1){
		analogInput.addProp("mltp",win.mltp.text);
	} else {
		analogInput.addProp("cod_min",win.cod_min.value); analogInput.addProp("cod_max",win.cod_max.value); analogInput.addProp("mA_min",win.mA_min.value); analogInput.addProp("mA_max",win.mA_max.value); 
		analogInput.addProp("fiz_min",win.fiz_min.value); analogInput.addProp("fiz_max",win.fiz_max.value);
	}
	
	addAnalogInput(analogInput);
	if (vplc) {var window:NativeWindow = win.stage.nativeWindow; window.stage.removeChild(win); window.close(); AI.push(analogInput);} else removeChild(win);
}
function confAI(e:MouseEvent):void{
	trace("Opening AI to config");
}
function closeWinAI(e:MouseEvent):void{
	var win:WinAddAI = e.target.parent;
	win.doAI_btn.removeEventListener(MouseEvent.CLICK, addNewAI);
	win.close_btn.removeEventListener(MouseEvent.CLICK, closeWinAI);
	win.type_cb.removeEventListener(Event.CHANGE, changeTypeAI);
	win.getSrc_src.removeEventListener(MouseEvent.CLICK, getSource);
	if (vplc) {var window:NativeWindow = win.stage.nativeWindow; window.stage.removeChild(win); window.close();} else removeChild(win);
}

function toMessage(capt:String, txt:String=""):void{
	var win:InfoWin=new InfoWin();
	win.capt.text=capt;
	win.txt.text=txt;
	trace("Opening a message window "+win.width, win.height);
	if (vplc) {
		var window:NativeWindow = new NativeWindow(options);
		window.title="capt";
		window.width=300;
		window.height=200;
		//window.x=stage.stageWidth/2-150; window.y=stage.stageHeight/2-100; //Это относится только к текущему окошку (его размеру)
		window.x=stage.fullScreenWidth/2-win.width/2; window.y=stage.fullScreenHeight/2-win.height/2;
		window.stage.align = StageAlign.TOP_LEFT; window.stage.scaleMode=StageScaleMode.NO_SCALE;
		window.stage.addChild(win);
		window.activate();
		window.stage.addEventListener(MouseEvent.MOUSE_DOWN, getMDown);
	} else {
		addChild(win);
	}
}

function init(file:String):void{
	initT.removeEventListener(TimerEvent.TIMER, noProjectLoaded);
	initT.stop();
	projectFile=new File(file);
	initProject();
}

if (so.data.lastProject) {
	trace("Got lastProject info");
	var array:Array=so.data.lastProject;
	for each (var objc in array) {
		trace(objc);
		for (var prop in objc){
			trace(prop+"="+objc[prop]);
		}
	}
	array.reverse();
	lastProject=new DataProvider(array);
	startWindow.lastProjList.dataProvider=lastProject;
	if (so.data.autoStart) {
		if (so.data.autostart[0]==1) {
			projectFile=new File(so.data.autostart[1]);
			trace("Autostart project: "+so.data.autostart[1]);
			trace(projectFile.exists, projectFile.name);
			if (!projectFile.exists) {processError("Файл проекта "+so.data.autostart[1]+" больше не существует"); return}
			projectFile.addEventListener(Event.COMPLETE, fileLoaded);
			projectFile.addEventListener(IOErrorEvent.IO_ERROR, errorLoading);
			projectFile.load();
		}
	}
}

startWindow.lastProjList.addEventListener(Event.CHANGE, lastProjSelected);

function noProjectLoaded (e:TimerEvent):void{
	showAlert("No Project loaded. Opening starting window");
	startWindow.visible=true;
	initT.stop();
}

function exitProgram(e:MouseEvent):void{
	NativeApplication.nativeApplication.exit();
}
function lastProjSelected (e:Event):void{
	projectFile=new File(startWindow.lastProjList.selectedItem.data);
	trace("Selected a last project: "+startWindow.lastProjList.selectedItem.label+": "+startWindow.lastProjList.selectedItem.data);
	trace(projectFile.exists, projectFile.name);
	projectFile.addEventListener(Event.COMPLETE, fileLoaded);
	projectFile.addEventListener(IOErrorEvent.IO_ERROR, errorLoading);
	projectFile.load();
}
function findProject(e:MouseEvent):void{
	projectFile.addEventListener(Event.SELECT, fileSelected);
	projectFile.addEventListener(Event.CANCEL, cancelSelect);
	projectFile.browseForOpen("MASC проект", [mascFilter,new FileFilter("Все файлы","*.*")]);
}
function cancelSelect(e:Event):void{
	projectFile.removeEventListener(Event.SELECT, fileSelected);
	projectFile.removeEventListener(Event.CANCEL, cancelSelect);
}
function fileSelected(e:Event):void{
	projectFile.addEventListener(Event.COMPLETE, fileLoaded);
	projectFile.addEventListener(IOErrorEvent.IO_ERROR, errorLoading);
	projectFile.load();
}
function errorLoading(e:IOErrorEvent):void{
	projectFile.removeEventListener(Event.COMPLETE, fileLoaded);
	projectFile.removeEventListener(IOErrorEvent.IO_ERROR, errorLoading);
	showAlert("Ошибка загрузки файла!");
}
function fileLoaded(e:Event):void{
	projectFile.removeEventListener(Event.COMPLETE, fileLoaded);
	projectFile.removeEventListener(IOErrorEvent.IO_ERROR, errorLoading);
	initProject();
}

function showAlert(message:*):void{
	trace(message);
}

function setNumPad(targ:*,topic:String,par:String,val:Number=0):void{
	for each(var pad:NumPad in numPadArr){
		if (pad.targ==targ) {trace("Numpad on object already opened!"); return;}
	}
	trace("Seting up a Numpad. Param "+targ);
	pad=new NumPad();
	pad.sVal_txt.text=pad.nVal_txt.text=val.toString();
	pad.val_txt.text="";
	pad.sVal_txt.visible=true;
	pad.val_txt.text="";
	pad.valus="";
	pad.val=val;
	pad.targ=targ;
	pad.topic=topic;
	pad.par=par;
	
	//pad.x=targ.stage.mouseX-pad.width/2; pad.y=targ.stage.mouseY-pad.height/2; checkBounds(pad,10); targ.stage.addChild(pad); return;
	
	if (vplc==true) {
		var window:NativeWindow = new NativeWindow(options);
		window.title="Ввод значения";
		window.width=158; window.height=194;
		window.stage.align = StageAlign.TOP_LEFT;
		window.stage.scaleMode=StageScaleMode.NO_SCALE;
		window.alwaysInFront=true;
		window.stage.addChild(pad);
		window.activate();
		//trace(targ.stage.nativeWindow.x,targ.stage.nativeWindow.y,stage.mouseX,stage.mouseY, pad.width,pad.height);
		window.x=targ.stage.nativeWindow.x+targ.stage.mouseX; window.y=targ.stage.nativeWindow.y+targ.stage.mouseY;
		window.stage.addEventListener(MouseEvent.MOUSE_DOWN,getMDown);
	} else {
	//if (vplc) {window.x=stage.fullScreenWidth/2-win.width/2; window.y=stage.fullScreenHeight/2-win.height/2;} else {window.x=stage.mouseX-win.width/2; window.y=stage.mouseY-win.height/2;}
		pad.x=stage.mouseX; pad.y=stage.mouseY;
		checkBounds(pad,10); addChild(pad);
	}
	numPadArr.push(pad);
}