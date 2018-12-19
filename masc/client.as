import flash.events.MouseEvent;

this.addChild(container); setChildIndex(container,2); addChild(menuBtns); setChildIndex(menuBtns,3);
NativeApplication.nativeApplication.addEventListener(KeyboardEvent.KEY_DOWN,getKey);
function getKey(e:KeyboardEvent):void{trace(e.charCode,e.keyCode);}

function getRClick(e:MouseEvent):void{
	trace(e.target);
	if (e.target==stage) {trace("RClick. Clicked stage. Open Menu"); return;}
	trace("RClick. "+e.target.name);
}
function getMClick(e:MouseEvent):void{

	if (e.target.name=="findProj_btn") findProject(e); //if (e.target==startWindow.findProj_btn) findProject(e);
	//if (e.target.parent==startWindow.lastProjList) lastProjSelected(e);
	if (e.target.name=="stopRuntime_btn") stopProject(e); //if (e.target==stopRuntime_btn) stopProject(e);
	if (e.target.name=="exitRuntime_btn") exitProgram(e); //if (e.target==exitRuntime_btn) exitProgram(e);
	//if (e.target==startRuntime_btn) startProject(e);
	if (e.target.name=="addAI_btn") windowAddAI();
	if (e.target is MovieClip || e.target is Button) true; else return;
	if (e.target.name=="hidePar") {e.target.parent.visible=false;}
}

function initProject():void{
	try{projectXML=XML(projectFile.data);} catch (Error:*) {trace(Error); return;}
	var item:Object=new Object();
	item={label:projectFile.name, data:projectFile.nativePath}
	for each(var prog in lastProject.toArray()){
		//trace("Comparing items "+prog.data,item.data)
		if (prog.data==item.data){
			lastProject.removeItem(prog);
		}
	}
	lastProject.addItem(item);
	so.data.lastProject=lastProject.toArray(); //so.data.lastProject=null; //Это если вдруг надо очистить
	so.flush();
	startWindow.visible=false;
	setUpClient(); //Теперь запускаем функцию подключения к брокерам и расположения всего проекта и стартовой страницы//
	stopRuntime_btn.visible=true;
	exitRuntime_btn.visible=false;
}
function stopProject(e:MouseEvent):void{
	stopRuntime_btn.visible=false;
	exitRuntime_btn.visible=true;
	setDownProject(); //Теперь запускаем функцию внешнего файла для остановки и очистки всего всего//
	startWindow.visible=true;
}
function setDownProject():void{
	trace("Stoping runtime");
	tryDisconnect();
	container.removeChildren(); menuBtns.removeChildren();
	iconArr=[]; activeObj=[];
	for each (var mainD:String in mainData) delete mainData.mainD;	
}

function setUpClient():void{ //распаковка нового проекта
	trace("Project loaded.")// trace("Starting runtime: "+projectXML);
	menuBtns.removeChildren();
	iconArr=[];
	trace(container.x,container.y,getChildIndex(container));
	var ns=projectXML.namespace();
	tryConnect();
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
	stage.addEventListener(MouseEvent.RIGHT_CLICK, getRClick);
}

function updateData(e:Event=null):void{
	if (servicing==false){
		connect_mc.gotoAndStop(3); //trace("No connection!");
		if (enableContainer) enableContainer=false;
		return;
	}
	if (enableContainer==false) enableContainer=true;
	activeOs.text=(activeObj.length).toString();
	for each(var obj in activeObj) updateWindowObject(obj)
}

var regSrc:RegExp = /(ai|aq|di|dq|dd|da)\d*/ig;
var resArr:Array=[];
var resType:String="";
var resNum:int=-1;
function searchData(topic:String, object:Object):void{
	
}
function updateWindowObject(obj:*):void{
	var reqVal:String="";
	//trace("Updating data for active objects "+obj);
	if (obj is FizAI) {reqVal="MASC/tags/PLC/AI/"+(obj.num).toString(); if (mainData[reqVal]) obj.processData(mainData[reqVal]); }//trace("Got a fizAI. Need info "+reqVal+". In mainData="+mainData[reqVal]); 
	if (obj is TextData) {reqVal=obj.src; if (mainData[reqVal]) obj.processData(mainData[reqVal]); }//trace("Got a TextData. Need info "+reqVal+". In mainData="+mainData[reqVal]); 
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
//-----------------------------

function manageAnalogInput(action:String,params:Array):void{ //Функция обработки манипуляций с Аналоговыми входами
	if (params.length<2) return;
	var pObj:Object=new Object();
	pObj.topic="update";
	pObj.a=action;
	pObj.f="AI";
	pObj.p=params.join(",");
	publishObj(true,pObj);
	//params[0 тип*,1 номер, 2 имя канала, 3 источник cod, 4 инженерные единицы, 5 фильтрация, 6 мин_cod, 7 макс_cod, 8 мин_мА, 9 макс_мА, 10 мин_физ, 11 макс_физ];
	//			Если второй тип, то с шестой позиции идут отличия								6 преобразующее выражение ];
}

function updateSlider(e:MouseEvent):void{
	//if (tar.mouseX>tar.maxX){tar.headSl.x=tar.maxX} else {tar.headSl.x=tar.mouseX}
	//if (tar.mouseX<0){tar.headSl.x=0}
	trace("tar.mouseY="+tar.mouseY+" tar.maxY="+tar.maxY);
	if (tar.mouseY>tar.maxY){tar.headSl.y=tar.maxY} else {tar.headSl.y=tar.mouseY}
	if (tar.mouseY<0){tar.headSl.y=0}
	tar.inputVal.x=-50+tar.headSl.x;
	tar.inputVal.y=-10+tar.headSl.y;
	if (tar.vect=="VD"){
		//trace(tar.valH,tar.valL,tar.headSl.y);
		tar.inputVal.text=int((tar.valH-tar.valL)*(tar.headSl.y/100)+tar.valL).toString();
	} else if (tar.vect=="VU") {
		tar.inputVal.text=int((tar.valH-tar.valL)*(tar.headSl.y/100)+tar.valL).toString();
	} else if (tar.vect=="HL") {
		tar.inputVal.text=int((tar.valH-tar.valL)*(tar.headSl.x/100)+tar.valL).toString();
	} else if (tar.vect=="HR") {
		tar.inputVal.text=int((tar.valH-tar.valL)*(tar.headSl.x/100)+tar.valL).toString();
	}
}
function dropSlider(e:MouseEvent):void{
	stage.removeEventListener(MouseEvent.MOUSE_MOVE,updateSlider);
	stage.removeEventListener(MouseEvent.MOUSE_UP,dropSlider);
	tar.enable=true;
	if (int(tar.inputVal.text)!=tar.val.text){
		trace("New data arrived!!!");
		//tryPublish(true,[tar.reqVal,int(tar.inputVal.text)]);
		//flushData(tar.src,tar.path,tar.inputVal.text);
	}
	//sl.maxY=100;sl.valL=50;sl.valH=500;
	tar.inputVal.visible=false;
	tar.enable=true;
	tar=null;
}

function devData(e:KeyboardEvent):void{
	if (e.keyCode==27) {
		textTar.inputVal.visible=false;
		textTar.enable=true; editingT=false;
		textTar=null;
	}
	if (e.keyCode!=13) return;
	var tx:TextField=textTar.inputVal;
	stage.removeEventListener(KeyboardEvent.KEY_UP,devData);
	var tarVal:String=String(textTar.val).split(" ")[0];
	if (tx.text!=tarVal){
		trace("Flushing data!!!");
		//flushData(textTar.src,textTar.path,tx.text);
		//publishInfo(tar,tx.text);
		//tryPublish(true,[tar.reqVal,tx.text]);
	}
	textTar.inputVal.visible=false;
	textTar.enable=true; editingT=false;
	textTar=null;
}
function setInputT(targ:*):void{
	textTar=targ;
	//inputT_txt.x=stage.mouseX-inputT_txt.width/2; inputT_txt.y=stage.mouseY-inputT_txt.height/2;
	if (!textTar.enable) return;
	textTar.enable=false; //curTar=tar;
	editingT=true;
	var tx:TextField=textTar.inputVal;
	tx.text=String(textTar.val.text).split(" ")[0];
	tx.visible=true; stage.focus=tx;
	tx.setSelection(0,tx.length);
	stage.addEventListener(KeyboardEvent.KEY_UP,devData);
}

var tar:*;

function setSlMove(tar:*):void{
	trace("Slider head grabbed. Start dragging");
	tar=tar.parent;
	tar.enable=false;
	tar.inputVal.text=tar.val.text;
	tar.inputVal.x=-50+tar.headSl.x;
	tar.inputVal.y=-10+tar.headSl.y;
	tar.inputVal.visible=true;
	stage.addEventListener(MouseEvent.MOUSE_MOVE,updateSlider);
	stage.addEventListener(MouseEvent.MOUSE_UP,dropSlider);
}

function insertNumPad(pad:NumPad):void{
	trace("Inserting data to broker "+pad.topic,pad.par,pad.val);
	
}
function insertPushBtn(btn:PushBtn):void{
	//false,'{"fiz":'+(1-targ.stat).toString()+', "path":"'+targ.path+'"}'
}

function getPageNum(e:MouseEvent):void{
	tar=e.target;
	trace("Menu Button Clicked");
	if (tar is Icon_0) {trace("Clicked toPageBtn"+tar.page); setPage(int(tar.page));}
}
function toggleShow(trg:*):void{//Эта функция срабатывает от кнопки и пытается найти и скрыть объект с именем после знака _ в имени кнопки
	var par:*=trg.parent;
	var child:String=trg.name.substring(5,trg.name.length);
	try {
		var targ:*=par.getChildByName(child);
		if (targ){targ.visible=!targ.visible;}
	} catch (Error:*) {trace("No child "+child+" in parent: "+par)}
	return;//tar=null;
} 
function removeData():void{ //Очистка рабочего поля, и активных объектов. Работает перед распаковной нового проекта setUpClient()
	this.removeEventListener(Event.ENTER_FRAME, updateData);
	//set_btn.visible=true; //rem_btn.visible=false;
	container.removeChildren();
	activeObj=[]; activeOs.text="";
}

function updateFunc(object:Object):void {
	
}

function processOBjBtn(btn:ObjectBtn):void{
	if (btn.name=="gor0"){}
	if (btn.name=="gor1"){}
}
function processMode(btn:ModeAM):void{
	var par:*=btn.parent;
	if (par is Kotel0){
		
	}
}

var errArr:Vector.<String>=new Vector.<String>();
function processError(err:String):void{
	for each (var error in errArr) {
		if (error==err) return;
	}
	errArr.push(err);
	trace("Error "+errArr.length+": "+err);
}

function sendVPLC(e:TimerEvent=null):void{
	//Пустая функция, нужна, чтоб не ругался mqtt.as на клиента без VLPC 
}
//-------------------НА УДАЛЕНИЕ-------------------//

/*
var sig:String="";
function getRev(_path:String):Boolean{
	var ns=projectXML.namespace();
	for each (var source_ in projectXML..ns::Sources..ns::source){
		for each (var module_ in source_..ns::module){
			sig=(module_.@type).toString();
			if (sig.length>sig.split("DI").join("").length){
				for each (var var_ in module_.children()){
					if ((var_.@path)==_path){
						return (var_.@reverse=="1");
					}
				}
			}
		}
	}
	return false;
}

function getPath(targ:*, _source:int, _module:int, _var:int):String{
	var ns=projectXML.namespace(); 
	for each (var source_ in projectXML..ns::Sources..ns::source){
		if (source_.@id ==_source){
			for each (var module_ in source_..ns::module){
				if (int(module_.@id) == _module){
					for each (var var_ in module_.children()){
						if (int(var_.@id)==_var){
							trace("Variable path found: "+ source_.@path+"/"+var_.@path); 
							targ.units=var_.@units;
							return source_.@path+"/"+var_.@path;
						}
					}
				}
			}
		}
	}
	//return 
	//trace("variable path = "+projectXML..ns::Sources..ns::source[_source]..ns::module[_module]..ns::ai[varNum]);
	return "null";
}
*/