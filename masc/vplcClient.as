import flash.filesystem.File;

var activePage:uint;
var projectXML:XML;
var mainData:Object;
var activeObj:Array=[];
var projectFile:File;
var container:MovieClip;
var menuBtns:MovieClip;
var iconArr:Array;
var vplc:*;

function updateWindowObject(obj:*):void{
	vplc.updateWindowObject(obj);
}
function updateClients():void{
	vplc.updateClients();
}

function initClient(caller:*):void{
	container=new MovieClip();
	stage.addChild(container);
	menuBtns=new MovieClip();
	stage.addChild(menuBtns);
	vplc=caller;
	projectXML=vplc.projectXML;
	activePage=vplc.activePage;
	mainData=vplc.mainData;
	activeObj=vplc.activeObj;
	projectFile=vplc.projectFile;
	iconArr=vplc.iconArr;
	trace(projectXML);
	
	trace("Project loaded.")// trace("Starting runtime: "+projectXML);
	menuBtns.removeChildren();
	iconArr=[];
	var ns=projectXML.namespace();
	for each (var page in projectXML..ns::Page) {
		var icoBtn;
		switch (uint(page.@icon)){
			case 0: icoBtn=new Icon_0(); break;
			//case 1: ; break;
			//case 2: ; break;
			default: icoBtn=new Icon_0(); break;
		}

		icoBtn.name_txt.text=(page.@name).toString(); icoBtn.name="showPage"; icoBtn.gotoAndStop(int(page.@icon)); icoBtn.mouseChildren=false; icoBtn.page=int(page.@id); iconArr[uint(page.@id)]=icoBtn;
	}
	var interval:uint=220;
	trace(iconArr.length);
	if (iconArr.length>7) {trace("Make smaller icons"); interval=150;}
	for (var f4r:Number=0; f4r<iconArr.length; f4r++){
		icoBtn=iconArr[f4r]; icoBtn.y=1025; icoBtn.x=55+(f4r * interval);
		if (interval==150) {icoBtn.name_txt.text=(page.@accronim).toString();}
		if (interval==65) {icoBtn.name_txt.text=""; icoBtn.removeChild(icoBtn.getChildByName("name_txt"));}
		icoBtn.height=55; icoBtn.scaleX=icoBtn.scaleY; menuBtns.addChild(icoBtn);
	}
	setPage(0);
	//stage.addEventListener(MouseEvent.RIGHT_CLICK, getRClick);
}

function updateClient():void{
	var reqVal:String="";
	activeOs.text=(activeObj.length).toString();
	for each(var obj in activeObj){
		//trace("Updating data for active objects "+obj);
		if (obj is FizAI) {reqVal="MASC/tags/PLC/AI/"+(obj.num).toString(); if (mainData[reqVal]) obj.processData(mainData[reqVal]); trace("Got a fizAI. Need info "+reqVal+". In mainData="+mainData[reqVal]); }//
		if (obj is TextData) {reqVal=obj.src; if (mainData[reqVal]) obj.processData(mainData[reqVal]); trace("Got a TextData. Need info "+reqVal+". In mainData="+mainData[reqVal]);}// 
		if (obj is KlapanA) { reqVal="MASC/tags/PLC/DA/"+(obj.num).toString();  if (mainData[reqVal]) obj.processData(mainData[reqVal]) }
		
		//if (obj is TankAI) {}
		//if (obj is TankData) {}
		//if (obj is KlapanD) {}
		//if (obj is PumpD) {}
		//if (obj is Slider) {}
		//if (obj is PushBtn) {}
		//if (obj is SlideBtn) {}
		//if (obj is Tube) {}
		//if (obj is Fitting1) {}
		//if (obj is Fitting2) {}
		//if (obj is Fitting3) {}
	}
}