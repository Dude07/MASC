import masc.tags.AnalogInput;
import masc.tags.AnalogOutput;
import masc.tags.DiscretInput;
import masc.tags.DiscretOutput;
import masc.tags.DeviceDiscret;
import masc.tags.DeviceAnalog;
import masc.tags.Kotelnaya;
import masc.tags.Kotel;
import masc.tags.Regulator;
import masc.tags.Correction;
import fl.data.DataProvider;
import fl.events.DataChangeEvent;
import fl.transitions.easing.Regular;

var AI:Vector.<AnalogInput>=new Vector.<AnalogInput>();
var AQ:Vector.<AnalogOutput>=new Vector.<AnalogOutput>();
var DI:Vector.<DiscretInput>=new Vector.<DiscretInput>();
var DQ:Vector.<DiscretOutput>=new Vector.<DiscretOutput>();
var DA:Vector.<DeviceAnalog>=new Vector.<DeviceAnalog>();
var DD:Vector.<DeviceDiscret>=new Vector.<DeviceDiscret>();
var kotelnie:Array=[];
var firstRun:Boolean=false;
var tables:Array=[]; //Массив таблиц для процессов определения SP
updateTimer.addEventListener(TimerEvent.TIMER, sendVPLC);

vplc=true; startRuntime_btn.visible=false; modBusBr_btn.visible=modBusStop_btn.visible=startCl_btn.visible=false;

function getMClick(e:MouseEvent):void{
	if (e.target==startWindow.findProj_btn) findProject(e);
	if (e.target==modBusBr_btn) startModBus();
	if (e.target==modBusStop_btn) stopModBus();
	//if (e.target.parent==startWindow.lastProjList) lastProjSelected(e);
	if (e.target==stopRuntime_btn) stopProject(e);
	if (e.target.name=="startRuntime_btn") startProject(e);
	if (e.target==exitRuntime_btn) exitProgram(e);
	if (e.target.name=="addAI_btn") windowAddAI();
	if (e.target is MovieClip || e.target is Button) true; else return;
	if (e.target.name=="hidePar") {e.target.parent.visible=false;}
	if (e.target.name=="viewBD_btn") showTrends();
	if (e.target.name=="startCl_btn") showClient();
	if (targ is Icon_0) {
		trace("Clicked toPageBtn"+targ.page);
		//var window:NativeWindow = targ.stage.nativeWindow; 
		var win:WinClient=targ.stage.getChildAt(0);
		win.setPage(int(targ.page));
	}
}

function sendVPLC(e:TimerEvent=null):void{
	if (!servicing) return;
	var pObj:Object; var arr:Array=[]; var inObj:Object;
	for each(var kotelnaya:Kotelnaya in kotelnie){
		if (kotelnaya.src_ping){
			pObj=new Object();
			arr=kotelnaya.src_ping.split(":"); 
			pObj.topic=arr[0];
			trace("Destenation array of Ping Kotelnaya = "+arr);
			trace("Topic = "+arr[0]);
			if (arr.length>1){
				if (arr.length>2){
					inObj=new Object();
					inObj[arr[2]]=true;
					pObj[arr[1]]=inObj;
					trace("Dest data is infolded in parameter "+arr[1]+". the value is "+arr[2]+"="+true);
				} else {
					pObj[arr[1]]=true;
					trace("Dest data is "+arr[1]+"="+true);
				}
			}
			trace("Обновляю пинг для котельной номер "+kotelnaya.num);
			publishObj(false,pObj,1,"none");
			
		}
		
		trace(new Date().time,kotelnaya.ping,new Date().time-kotelnaya.ping);
		if (Math.abs(new Date().time-kotelnaya.ping) > 35000) {
			if (kotelnaya.err==0) {
				trace("No connection with kotelnaya #"+kotelnaya.num+"!!!"); 
				kotelnaya.err=1; for each(var kotel:Kotel in kotelnaya.Kotli) kotel.noConn=true;
				updateClients();
			}
		} else {
			if (kotelnaya.err==1) {kotelnaya.err=0; for each(kotel in kotelnaya.Kotli) kotel.noConn=false; updateClients();}
		}
		
		if (firstRun){
			pObj=new Object();
			arr=kotelnaya.src_pubAll.split(":"); 
			pObj.topic=arr[0];
			trace("Destenation array of PubAllData of Kotelnaya = "+arr);
			trace("Topic = "+arr[0]);
			if (arr.length>1){
				if (arr.length>2){
					inObj=new Object();
					inObj[arr[2]]=true;
					pObj[arr[1]]=inObj;
					trace("Dest data is infolded in parameter "+arr[1]+". the value is "+arr[2]+"="+true);
				} else {
					pObj[arr[1]]=true;
					trace("Dest data is "+arr[1]+"="+true);
				}
			}
			trace("Запрос всех данных от котельной номер "+kotelnaya.num);
			publishObj(false,pObj,1,"none");
		}
	}
	firstRun=false;
}

function showClient():void{
	var opt:NativeWindowInitOptions = new NativeWindowInitOptions(); 
	opt.systemChrome = NativeWindowSystemChrome.NONE; 
	opt.type = NativeWindowType.NORMAL;
	//options.type = NativeWindowType.UTILITY 
	opt.resizable = false; 
	opt.maximizable = true;
	opt.transparent = false;
	trace("Starting client");
	var win:WinClient=new WinClient(); win.name="WinClient";
	var window:NativeWindow = new NativeWindow(opt);
	window.title="Окно клиента проекта";
	window.width=1920;
	window.height=1080;
	window.stage.align = StageAlign.TOP_LEFT;
	window.stage.scaleMode=StageScaleMode.NO_SCALE;
	window.stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
	window.stage.addChild(win);
	window.activate();
	window.stage.addEventListener(MouseEvent.MOUSE_DOWN,getMDown);
	win.initClient(this);
	clientWins.push(window);
	trace("Added client window. Total now="+clientWins.length);
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
	if (modBusStop_btn.visible) stopModBus();
	startWindow.visible=false;
	startRuntime_btn.visible=modBusBr_btn.visible=true;
	stopRuntime_btn.visible=modBusStop_btn.visible=false;	
	exitRuntime_btn.visible=true;
	if ((projectXML.projectType.@cycleTrigger).toString().length>0) cycleTrigger=projectXML.projectType.@cycleTrigger;
	trace("-----------------------------------------------------Project cycle trigget = "+cycleTrigger+" --------------------------------------------------------------------");
	
	var ns=projectXML.namespace();
	var trendBD = projectXML..ns::trendBD;
	trace("TrendBD setup Initialized.");
	var loc:String=trendBD.@name;
	if (loc.length>0) setUpDB(loc) else setUpDB("asProject")
}
function stopProject(e:MouseEvent):void{
	startRuntime_btn.visible=stopRuntime_btn.visible=modBusBr_btn.visible=modBusStop_btn.visible=startCl_btn.visible=false;
	exitRuntime_btn.visible=true;
	firstRun=true;
	setDownVLPC(); //Теперь запускаем функцию внешнего файла для остановки и очистки всего всего//
	startWindow.visible=true;
}
function setDownVLPC():void{
	trace("Stoping runtime");
	tryDisconnect();
	removeData();
	
	var window:NativeWindow
	while (clientWins.length>0){
		window = clientWins[0].stage.nativeWindow;
		clientWins.shift();
		window.close();	
		try {window.stage.removeEventListener(MouseEvent.MOUSE_DOWN,getMDown);} catch (Error:*) {"No MouseDown event for his window"}
	}
	while (numPadArr.length>0){
		window = numPadArr[0].stage.nativeWindow;
		numPadArr.shift();
		window.close();	
		try {window.stage.removeEventListener(MouseEvent.MOUSE_DOWN,getMDown);} catch (Error:*) {"No MouseDown event for his window"}
	}
}

function setUpVPLC():void{ //распаковка нового проекта
	trace("Project loaded. Starting VLPC");
	//trace(projectXML);
	AI=new Vector.<AnalogInput>();
	var addSrc:Boolean=false;
	var isMQTT:Boolean=false;
	var ns=projectXML.namespace();
	var tempArr:Array=[]; 
	for each (var source in projectXML..ns::Sources..ns::source) {
		trace(source.@id,source.@name,source.@type,source.@path,source.@adress);
		addSrc=true; //Изначально рассчитываем на добавление элемента
		tempArr[0]=source.@id; tempArr[1]=source.@name; tempArr[2]=source.@type; tempArr[3]=source.@path; tempArr[4]=source.@adress;
		if (tempArr[2].substr(0,4)=="MQTT") {
			//sourceArr[source.@id]=tempArr;
			for each (var sArr in sourceArr){
				if (tempArr[2]==sArr[2]){
					if (tempArr[3]==sArr[3]) addSrc=false;
				}
			}
			if (addSrc) {sourceArr.push([tempArr[0],tempArr[1],tempArr[2],tempArr[3]]);}//Если совпадают топики, то нет смысла наталкивать лишник сообщения...
		}
		if (tempArr[2].substr(0,4)=="MB") {}
	}
	
	for each (var ai in projectXML..ns::PLC..ns::ai) {
		//----------Новый способ добавления Аналоговых сигналов----------//
		var analogInput:AnalogInput=new AnalogInput();
		for each (var par:XML in ai.attributes()) analogInput.addProp(par.name(),par.valueOf());
		for each (var reg in ai..ns::reg){
			var regulator:Regulator=new Regulator();
			for each (par in reg.attributes()) regulator.addProp(par.name(),par.valueOf());
			for each (var cor in reg..ns::cor){
				var correction:Correction=new Correction();
				for each (par in cor){
					//trace("Attrib " + par.name() + " = " + par.valueOf());  //if (par.name()!="id") correction[par.name()]=par.valueOf(); - этот вариант не зашёл, так как ругается на то что не может создать уже имеющееся свойтво
					correction.addProp(par.name(),par.valueOf());
				}
				regulator.cors[correction.num]=correction;
			}
			analogInput.regs[regulator.num]=regulator;
		}
		AI.push(analogInput); //trace(analogInput);
		
		/*tempArr=[];
		switch (int(ai.@type)){
			case 0: tempArr=[int(ai.@type),int(ai.@num),ai.@name,ai.@src,ai.@eu, ai.@filtr, ai.@cod_min, ai.@cod_max, ai.@mA_min, ai.@mA_max, ai.@fiz_min, ai.@fiz_max]; break;
			case 1: tempArr=[int(ai.@type),int(ai.@num),ai.@name,ai.@src,ai.@eu, ai.@filtr, ai.@mltp]; break;
			default: ; break;
		}
		manageAnalogInput("init",tempArr); */
	}
	for each (var table in projectXML..ns::Tables..ns::table){
		//tables.push(getTableXML(table));																	//Пытаемся вытащить значения таблиц данных для задания на подачу
		var resDP:Array=[];
		for each(var pair in table..ns::pair){
			resDP.push({DT:Number(pair.@DT),SP:Number(pair.@SP)});
		}
		//trace("New table added "+resDP.length,resDP.toString());
		tables[table.@num]=resDP;
		
	}
	
	for each (var di in projectXML..ns::PLC..ns::di) manageDiscretInput("init",[int(di.@type),int(di.@num),di.@name,di.@src,di.@filtr]);
	for each (var dq in projectXML..ns::PLC..ns::dq) manageDiscretOutput("init",[int(dq.@type),int(dq.@num),dq.@name,dq.@src,dq.@dst,dq.@filtr]);
	
	for each (var Kotelniya in projectXML..ns::Kotelnaya) {																//Если в проекте есть котельные
		var kotelnaya:Kotelnaya=new Kotelnaya(); //var kotelnaya:Object=new Object();									//Создём экземпляр
		kotelnaya.num=int(Kotelniya.@num)																				//Прописываем все источники данных для неё
		kotelnaya.src_sets=Kotelniya.@sets;
		kotelnaya.src_ping=Kotelniya.@ping;
		kotelnaya.src_mode=Kotelniya.@mode;
		kotelnaya.src_pubAll=Kotelniya.@pubAll;
		kotelnaya.algorithm=getAlgorithm(Kotelniya.algorithm);																		//Пытаемся достать название алгоритма работы (основного алгоритма)
		kotelnaya.ping=new Date().time;
		
		for each (var kotel in Kotelniya..ns::kotel) kotelnaya.Kotli[int(kotel.@num)]=addKotel(Kotelniya,kotel);  		//Перебираем, добавляем все котлы котелной в массивы
		kotelnie[kotelnaya.num]=kotelnaya;																				//Добавляем собственно котельную в массив котельных
	} 
	
	startRuntime_btn.visible=false;
	stopRuntime_btn.visible=true;
	exitRuntime_btn.visible=false;
	startCl_btn.visible=true;
	ai_txt.text=aq_txt.text=di_txt.text=dq_txt.text=da_txt.text=dd_txt.text="";
	ai_txt.text=(AI.length).toString();
	aq_txt.text=(AQ.length).toString();
	di_txt.text=(DI.length).toString();
	dq_txt.text=(DQ.length).toString();
	da_txt.text=(DA.length).toString();
	dd_txt.text=(DD.length).toString();
	
    tryConnect();
	updateTimer.start();
}

function getAlgorithm(alg:XMLList):Object{
	var ret:Object=new Object();
	for each(var par in alg){
		ret[par]=alg[par];
	}
	return ret;
}

function startProject(e:MouseEvent):void{ setUpVPLC(); }
function publishAI(ai:AnalogInput):void{ //Функция по публикации значения AI
	if (pubAI_chb.selected && ai.pub) {
		var pObj:Object=new Object(); //publishData("MASC/tags/PLC/AI/"+(ai.num).toString(),'{"fiz":'+ai.fiz+',"SP":'+ai.SP+',"SPcor":'+ai.SPcor+',"err":'+ai.err+'}');
		if (ai.err==0) pObj.fiz=Number(ai.fiz);
		pObj.topic="PLC/AI/"+(ai.num).toString();  pObj.SP=ai.SP; pObj.SPcor=ai.SPcor; pObj.err=ai.err;
		if (ai.args.length>0 && writeDB_chb.selected) insertIntoDB("ai",ai.num,ai.args,ai.vals); //Это как формат записи, но надо предусмотреть алгоритм, который будет выдавать значения на архивирование. Типа ai.arc=["fiz","SP","SPcorr"] и так далее
		publishObj(false,pObj);
		trace(pObj.topic);
	}
}
function publishDI(di:DiscretInput):void{ //Функция по публикации значения DI
	if (pubDI_chb.selected && di.pub) {
		var pObj:Object=new Object();
		if (di.err==0) pObj.fiz=di.fiz;
		pObj.topic="PLC/DI/"+(di.num).toString();  pObj.err=di.err; //pObj.SP=ai.SP; pObj.SPcor=ai.SPcor; 
		if (di.args.length>0 && writeDB_chb.selected) insertIntoDB("di",di.num,di.args,di.vals);
		publishObj(false,pObj);
		trace(pObj.topic);
	}
}
function publishDQ(dq:DiscretOutput):void{ //Функция по публикации значения DQ
	if (pubDQ_chb.selected && dq.pub) {
		var pObj:Object=new Object();
		if (dq.err==0) pObj.fiz=dq.fiz;
		pObj.topic="PLC/DQ/"+(dq.num).toString();  pObj.err=dq.err; //pObj.SP=ai.SP; pObj.SPcor=ai.SPcor; 
		if (dq.args.length>0 && writeDB_chb.selected) insertIntoDB("dq",dq.num,dq.args,dq.vals);
		publishObj(false,pObj);
		trace(pObj.topic);
	}
}
function updateData(e:Event=null):void{ //Обработка сигналов и так далее. Функция (Event.ENTER_FRAME) вызывается с mqtt.as startClient() или же по прилёту данных вызывается функция update
	for each (var ai in AI) { processAI(ai); publishAI(ai);}
	for each (var di in DI) { processDI(di); publishDI(di);}
	for each (var dq in DQ) { processDQ(dq); publishDQ(dq);}
	updateClients();
	iter+=1;
	iter_txt.text=iter.toString();
	for each (var kotelnaya in kotelnie) processKotelnaya(kotelnaya);
}
function updateClients():void{
	for each(var window in clientWins){
		try {
			var win:WinClient=window.stage.getChildAt(0); //win.updateClient(); 
			win.activeOs.text=(win.activeObj.length).toString();
			for each(var obj in win.activeObj) updateWindowObject(obj);
		} catch (Error:*) {trace("Window update Error: "+Error.message)}
	}
}

function formFiz(form:String,fiz:Number):Number{
	var ed:int=form.split(".")[1].length;
	var dec:int=1;
	while (ed>0){ ed--; dec=dec*10;}
	var ret:Number=0;
	if (dec>1) ret=Math.round(fiz*dec)/dec; else ret=fiz  //Math.round(fizVal*(10^edis))/(10^edis)
	//trace(ed,dec);
	return ret;
}

function updateWindowObject(obj:*):void{
	//trace("Updating data for active objects "+obj);
	if (obj is FizAI) {
		//trace("Got a fizAI. Need info AI"+obj.num+". Found data="+AI[int(obj.num)]+"Need form: "+obj.form); 
		var ai:AnalogInput=AI[int(obj.num)];
		if (obj.form=="") obj.fiz=ai.fiz else obj.fiz=formFiz(obj.form,ai.fiz)
		obj.fiz_txt.text=obj.fiz.toString(); obj.eu_txt.text=ai.eu;
		obj.SP=ai.SP; obj.SP_txt.text=obj.SP.toString();
		obj.SPcor=ai.SPcor; 
		if (obj.SPcor!=0 && obj.SPcor!=obj.SP) {
			obj.SP=obj.SPcor; obj.SP_txt.text=obj.SPcor.toString();
			obj.SP_txt.textColor=0xCC3399;
		} else {
			obj.SP_txt.textColor=0x333333;
		}
		obj.err=ai.err; obj.err_mc.gotoAndStop(1+obj.err); if (obj.err) obj.fiz_txt.text="Error";
	}
	if (obj is LampDI){
		//trace("Got a lampDI. Need info DI"+obj.num+". Found data="+DI[int(obj.num)]+" value = "+DI[int(obj.num)].fiz); 
		if (DI[int(obj.num)]) obj.Status=DI[int(obj.num)].fiz;
	}
	if (obj is PushBtn || obj is SlideBtn){
		//trace("Got a PushBtn. Need info DQ"+obj.numDQ+". Found data="+DQ[int(obj.numDQ)]+" value = "+DQ[int(obj.numDQ)].fiz); 
		if (DQ[int(obj.numDQ)]) obj.Status=DQ[int(obj.numDQ)].fiz;
	}
	//if (obj is TextData) {reqVal=obj.src; if (mainData[reqVal]) obj.processData(mainData[reqVal]); trace("Got a TextData. Need info "+reqVal+". In mainData="+mainData[reqVal]);}// 
	//if (obj is KlapanA) { reqVal="MASC/tags/PLC/DA/"+(obj.num).toString();  if (mainData[reqVal]) obj.processData(mainData[reqVal]) }
	if (obj is Kotel0) {
		var kotel:Kotel=kotelnie[obj.kotelnaya].Kotli[obj.num];

		obj.noConn.visible=kotel.noConn;
		obj.isOn.gotoAndStop(1+kotel.isOn);
		obj.isFlame0.gotoAndStop(1+kotel.isFlame0);
		obj.isFlame1.gotoAndStop(1+kotel.isFlame1);
						
		if (obj.gor0.stat_mc.currentFrame!=(1+kotel.gor0)) {
			obj.gor0.wait.stop(); obj.gor0.wait.visible=false;
			obj.gor0.stat_mc.gotoAndStop(1+kotel.gor0);
		}
						
		if (obj.gor1.stat_mc.currentFrame!=(1+kotel.gor1)) {
			obj.gor1.wait.stop(); obj.gor1.wait.visible=false;
			obj.gor1.stat_mc.gotoAndStop(1+kotel.gor1);
		}
		
		obj.bigFlame_txt.visible=Boolean(kotel.gor1)
		if (obj.modeAM.currentFrame!=1+kotel.A) {
			obj.modeAM.gotoAndStop(int(1+kotel.A)); obj.modeAM.wait.visible=false;obj.modeAM.wait.stop();
			obj.gor0.visible=obj.gor1.visible=!kotel.A;
		}
		obj.block_mc.visible=kotel.blocked;
		obj.mouseEnabled=!kotel.blocked
		return;
	}
}

function processObjBtn(btn:ObjectBtn):void{
	var obj:*=btn.parent;
	if (obj is Kotel0){
		var kotel:Kotel=kotelnie[obj.kotelnaya].Kotli[obj.num];
		var pubObj:Object=new Object();
		
		if (btn.name=="gor0"){
			trace("Clicked power btn - gorelka_0"+kotel.src_gor0,kotel.gor0);
			obj.gor0.wait.play(); obj.gor0.wait.visible=true;
			sendDataMQTT(kotel.src_gor0,!kotel.gor0);
		}
		if (btn.name=="gor1"){
			trace("Clicker full flame btn gorelka_1");
			obj.gor1.wait.play(); obj.gor1.wait.visible=true;
			sendDataMQTT(kotel.src_gor1,!kotel.gor1);
		}
	}
}
function processMode(btn:ModeAM):void{
	var obj:*=btn.parent;
	if (btn.wait){ if (btn.wait is MovieClip) {btn.wait.play(); btn.wait.visible=true;}}
	trace("Change mode pressed for "+obj); 
	if (obj is Kotel0){
		var kotel:Kotel=kotelnie[obj.kotelnaya].Kotli[obj.num];

		var pObj:Object=new Object();
		var sendVal:Boolean=Boolean(1-kotel.A)
		
		var arr:Array=kotel.src_mode.split(":"); 
		pObj.topic=arr[0];
		trace("Destenation array of PushBtn = "+arr);
		trace("Topic = "+arr[0]);
		if (arr.length>1){
			if (arr.length>2){
				var inObj:Object=new Object();
				inObj[arr[2]]=sendVal;
				pObj[arr[1]]=inObj;
				trace("Dest data is infolded in parameter "+arr[1]+". the value is "+arr[2]+"="+sendVal);
			} else {
				pObj[arr[1]]=sendVal;
				trace("Dest data is "+arr[1]+"="+sendVal);
			}
		}
		trace("Переключаю режим работы котла №"+kotel.num+" котельной номер "+kotel.kotelnaya);
		publishObj(false,pObj,1,"none");
		return;

	}
	trace("Some other object modeAM pressed "+obj);
}

var regSrc:RegExp = /(ai|aq|di|dq|dd|da)\d*/ig; var resArr:Array=[]; var resType:String=""; var resNum:int=-1;
var updateEngine:Boolean=false;
function searchData(topic:String, object:Object):void{
	//resArr=topic.match(eData); trace(resArr)
	updateEngine=false;
	for (var prop in object){
		//trace(prop+"="+object[prop]);
		resNum=prop.search(regSrc);
		if (resNum>=0){
			resType=prop.toString();
			resNum=int(resType.substring(2,resType.length));
			resType=resType.substr(0,2);
			resType=resType.toLocaleUpperCase();
			//trace(resType,resNum);
			switch (resType) {
				case "AI": if (resNum<=AI.length-1) {processAI(AI[resNum]); publishAI(AI[resNum]); if (AI[resNum].pub==true) updateEngine=true; } break;
				case "DI": if (resNum<=DI.length-1) {processDI(DI[resNum]); publishDI(DI[resNum]); if (DI[resNum].pub==true) updateEngine=true; } break;
				case "DQ": if (resNum<=DQ.length-1) {processDQ(DQ[resNum]); publishDQ(DQ[resNum]); if (DQ[resNum].pub==true) updateEngine=true; } break;
			}
		}
		
		/*resNum=topic.search(regSrc);
		if (resNum>=0){
			
			resType=topic.substring(resNum,topic.length);//prop.toString();
			resNum=int(resType.substring(2,resType.length));
			resType=resType.substr(0,2);
			resType=resType.toLocaleUpperCase();
			trace(resType,resNum,prop,object[prop]);
			switch (resType) {
				case "AI": if (resNum<=AI.length-1) {processAI(AI[resNum]); publishAI(AI[resNum]); if (AI[resNum].pub==true) updateEngine=true; } break;
				case "DI": if (resNum<=DI.length-1) {processDI(DI[resNum]); publishDI(DI[resNum]); if (DI[resNum].pub==true) updateEngine=true; } break;
				case "DQ": if (resNum<=DQ.length-1) {processDQ(DQ[resNum]); publishDQ(DQ[resNum]); if (DQ[resNum].pub==true) updateEngine=true; } break;
			}
		}*/ else if (prop=="ping"){
			if (topic.indexOf("Kotel")>=0){
				var arr:Array=topic.split("/");
				for (var f4r:int=0; f4r<arr.length; f4r++){
					if (arr[f4r].indexOf("Kotel")>=0) break;
				}
				f4r=int(arr[f4r+1]);
				var kotelnaya:Kotelnaya=kotelnie[f4r];
				kotelnaya.ping=new Date().time; trace("Got ping for kotelnaya #"+kotelnaya.num,kotelnaya.ping);
				if (kotelnaya.err==1) {kotelnaya.err=0; for each(kotel in kotelnaya.Kotli) kotel.noConn=false; updateEngine=true;}
			}
		} else if (prop=="mode"){
			if (topic.indexOf("Kotel")>=0){
				arr=topic.split("/");
				for (f4r=0; f4r<arr.length; f4r++){
					if (arr[f4r].indexOf("Kotel")>=0) break;
				}
				f4r=int(arr[f4r+1]);
				kotelnaya=kotelnie[f4r];
				kotelnaya.ping=new Date().time; trace("Got ping for kotelnaya #"+kotelnaya.num,kotelnaya.ping);
				if (kotelnaya.err==1) {kotelnaya.err=0; for each(kotel in kotelnaya.Kotli) kotel.noConn=false; updateEngine=true;}
				if (kotelnaya.distReg!=object[prop]) {kotelnaya.distReg=object[prop]; for each(kotel in kotelnaya.Kotli) kotel.blocked=int(!kotelnaya.distReg); updateEngine=true; kotelnaya.pub=true;}
			}
		} else if (prop.indexOf("Kotel")>=0){
			
			arr=topic.split("/");
			for (f4r=0; f4r<arr.length; f4r++){
				if (arr[f4r].indexOf("Kotel")>=0) break;
			}
			f4r=int(arr[f4r+1]);
			kotelnaya=kotelnie[f4r];
			var st:String=prop;
			if (st.indexOf("_")>=0) {
				arr=st.split("_");
				st=arr[0];
				f4r=int(st.substring(5,st.length));
				st=arr[1];
				var kotel:Kotel=kotelnaya.Kotli[f4r];
				if (kotel[st]!=int(object[prop])) {kotel[st]=int(object[prop]); updateEngine=true;}
			}				
		} else if (topic.substr(topic.length-4,4)=="sets"){
			trace("Some settings aqquierd");
			if (topic.indexOf("Kotel")>=0){
				arr=topic.split("/");
				for (f4r=0; f4r<arr.length; f4r++){
					if (arr[f4r].indexOf("Kotel")>=0) break;
				}
				f4r=int(arr[f4r+1]);
				kotelnaya=kotelnie[f4r];
				if (prop=="mode") {
					if (kotelnaya.distReg!=object[prop]) {kotelnaya.distReg=object[prop]; for each(kotel in kotelnaya.Kotli) kotel.blocked=int(!kotelnaya.distReg); updateEngine=true; kotelnaya.pub=true;}
				}
				if (prop.substr(0,5)=="Kotel"){
					arr=prop.toString().split("_");
					f4r=int(arr[0].substring(5,arr[0].length));
					var param:String=arr[1];
					kotel=kotelnaya.Kotli[f4r];
					if (param=="A"){  if (Boolean(kotel.A==1)!=object[prop]) {kotel.A=int(object[prop]); updateEngine=true;}  }
					//if (kotel[param]!=int(object[prop])){  kotelnaya.pub=true; kotel[param]=int(object[prop]);  }
				}
				//manageKotelnaya(); if (kotelnie[f4r].pub==true) 
			}
		} else {
			trace("Got some unknown property "+prop,object[prop]);
		}
	}
	
	//if (updateEngine==false) return; //Если ничего нового не пришло, то нет смысла что-то обновлять
	
	//if (topic.indexOf("PLC/")>=0){resArr=topic.split("/"); resArr.reverse(); trace(resArr[1],resArr[0]);}

	for each(kotelnaya in kotelnie){
		kotelnaya.process=false;
		if (kotelnaya.algorithm.ai_SP!=undefined) {
			 if (kotelnaya.SP!=AI[kotelnaya.algorithm.ai_SP].fiz) { kotelnaya.SP=AI[kotelnaya.algorithm.ai_SP].fiz; kotelnaya.process=true;}
		}
		if (kotelnaya.algorithm.ai_DT!=undefined) { 
			if (kotelnaya.DT!=AI[kotelnaya.algorithm.ai_DT].fiz) { kotelnaya.DT=AI[kotelnaya.algorithm.ai_DT].fiz; kotelnaya.process=true;}
		}
		for each(kotel in kotelnaya.Kotli) processKotel(kotel); //обработка котла - занесение полученных данных из осточника данных в переменные котла
		processKotelnaya(kotelnaya); //алгоритм управления котельными
	}
	iter+=1;
	iter_txt.text=iter.toString();    
	updateClients();
}
//-----------------------------

function manageDiscretInput(action:String,params:Array):void{ //Функция обработки манипуляций с Дискретными входами
	if (params.length<2) return;
	//params[0 тип*,1 номер, 2 имя канала, 3 источник, 4 фильтрация];
	switch (action) {
		case "init": trace("Init DI process. Total now = "+DI.length); break;
		case "add": trace("Adding a new DI to all. Total now = "+DI.length); break;
		case "modify": trace("Modify an DI"); return; break;
		case "delete": trace("Delete DI"); return; break;
	}
	var discret:DiscretInput=new DiscretInput(); var nam:String="";
	discret.type=int(params[0]);
	if (params[1]>=0) discret.num=params[1] else discret.num=DI.length;
	nam=params[2];
	if (nam.length>0) discret.name=nam else discret.name="Дискретный сигнал №"+(discret.num).toString();
	discret.src=params[3];
	if (params[3].split(":").length>0){
		var srcArr:Array=params[3].split(":");
		discret.src=srcArr[0];
		discret.tag=srcArr[srcArr.length-1];
	} else {
		discret.tag="fiz";
	}
	discret.filtr=params[4];
	//trace("type="+params[0]);
	
	DI.push(discret);
	//trace(DI.length);
	if (params[1]>=0) true; else addToXML("di",discret);
}

function manageDiscretOutput(action:String,params:Array):void{ //Функция обработки манипуляций с Дискретными входами
	if (params.length<2) return;
	//params[0 тип*,1 номер, 2 имя канала, 3 источник, 4 назначение, 5 фильтрация];
	switch (action) {
		case "init": trace("Init DQ process. Total now = "+DQ.length); break;
		case "add": trace("Adding a new DQ to all. Total now = "+DQ.length); break;
		case "modify": trace("Modify an DQ"); return; break;
		case "delete": trace("Delete DQ"); return; break;
	}
	var discret:DiscretOutput=new DiscretOutput(); var nam:String="";
	discret.type=int(params[0]);
	if (params[1]>=0) discret.num=params[1] else discret.num=DQ.length;
	nam=params[2];
	if (nam.length>0) discret.name=nam else discret.name="Дискретный выход №"+(discret.num).toString();
	discret.src=params[3];
	if (params[3].split(":").length>0){
		var srcArr:Array=params[3].split(":");
		discret.src=srcArr[0];
		discret.tag=srcArr[srcArr.length-1];
	} else {
		discret.tag="fiz";
	}
	if (params[4]=="src" || params[4]==undefined) discret.dst=params[3] else discret.dst=params[4];
	discret.filtr=params[5];
	
	DQ.push(discret);
	//trace(DQ.length);
	if (params[1]>=0) true; else addToXML("dq",discret);
}

function manageAnalogInput(action:String,params:Array):void{ //Функция обработки манипуляций с Аналоговыми входами
	if (params.length<2) return;
	//params[0 тип*,1 номер, 2 имя канала, 3 источник cod, 4 инженерные единицы, 5 фильтрация, 6 мин_cod, 7 макс_cod, 8 мин_мА, 9 макс_мА, 10 мин_физ, 11 макс_физ];
	//			Если второй тип, то с шестой позиции идут отличия								6 преобразующее выражение ];
	switch (action) {
		case "init": trace("Init AI process. Total now = "+AI.length); break;
		case "add": trace("Adding a new AI to all. Total now = "+AI.length); break;
		case "modify": trace("Modify an AI"); return; break;
		case "delete": trace("Delete AI"); return; break;
	}
	var analog:AnalogInput=new AnalogInput(); var nam:String="";
	analog.type=int(params[0]);
	if (params[1]>=0) analog.num=params[1] else analog.num=AI.length;
	nam=params[2];
	if (nam.length>0) analog.name=nam else analog.name="Аналоговый сигнал №"+(analog.num).toString();
	analog.src=params[3];
	if (params[3].split(":").length>0){
		var srcArr:Array=params[3].split(":");
		analog.src=srcArr[0];
		analog.tag=srcArr[srcArr.length-1];
	} else {
		analog.tag="fiz";
	}
	analog.eu=params[4];
	analog.filtr=params[5];
	//trace("type="+params[0]);
	if (analog.type==0){
		analog.cod_min=params[6]; analog.cod_max=params[7]; analog.mA_min=params[8]; analog.mA_max=params[9]; analog.fiz_min=params[10]; analog.fiz_max=params[11];
		//trace(analog.type,analog.num,analog.name,analog.src,analog.tag,analog.filtr,analog.cod_min,analog.cod_max,analog.mA_min,analog.mA_max,analog.fiz_min,analog.fiz_max);
	} else {
		analog.mltp=params[6];
		//trace(analog.type,analog.num,analog.name,analog.src,analog.tag,analog.filtr,analog.mltp);
	}
	AI.push(analog);
	//trace(AI.length);
	if (params[1]>=0) true; else addToXML("ai",analog); 
}

function addToXML(action:String, obj:*):void{
	if (action=="ai"){
		var ai:XML= <ai/>;
		ai.@id=projectXML.PLC.children().length();
		ai.@type=obj.type;
		ai.@num=obj.num;
		ai.@name=obj.name;
		ai.@src=obj.src+":"+obj.tag;
		ai.@eu=obj.eu;
		ai.@filtr=obj.filtr;
		if (obj.type==1) {
			ai.@mltp=obj.mltp;
		} else {
			ai.@cod_min=obj.cod_min;ai.@cod_max=obj.cod_max;ai.@mA_min=obj.mA_min;ai.@mA_max=obj.mA_max; ai.@fiz_min=obj.fiz_min;ai.@fiz_max=obj.fiz_max;
		}
		trace(ai.toString());
		projectXML.PLC.appendChild(ai);
		toMessage("Attenstion!","   Right now i would normally overwrite the projectFile, but wont do it yet.\n   Saving can be done vai a save command, that is send to the server ether from clients, or by clicking saveProject or saveProjectAS buttons.\n   Right now i will try to send all changes via broker");
		publishChanges("PLC",ai);
	}
	if (action=="di"){
		var di:XML= <di/>;
		di.@id=projectXML.PLC.children().length();
		di.@type=obj.type;
		di.@num=obj.num;
		di.@name=obj.name;
		di.@src=obj.src+":"+obj.tag;
		di.@filtr=obj.filtr;
		trace(di.toString());
		projectXML.PLC.appendChild(di);
		toMessage("Attenstion!","   Right now i would normally overwrite the projectFile, but wont do it yet.\n   Saving can be done vai a save command, that is send to the server ether from clients, or by clicking saveProject or saveProjectAS buttons.\n   Right now i will try to send all changes via broker");
		publishChanges("PLC",di);
	}
	if (action=="dq"){
		var dq:XML= <dq/>;
		dq.@id=projectXML.PLC.children().length();
		dq.@type=obj.type;
		dq.@num=obj.num;
		dq.@name=obj.name;
		dq.@src=obj.src+":"+obj.tag;
		dq.@dst=obj.dst;
		dq.@filtr=obj.filtr;
		if (obj.dst) dq.@dst=obj.dst;
		trace(dq.toString());
		projectXML.PLC.appendChild(dq);
		toMessage("Attenstion!","   Right now i would normally overwrite the projectFile, but wont do it yet.\n   Saving can be done vai a save command, that is send to the server ether from clients, or by clicking saveProject or saveProjectAS buttons.\n   Right now i will try to send all changes via broker");
		publishChanges("PLC",dq);
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

var sig:String="";
function insertNumPad(pad:NumPad):void{
	trace("Inserting data directly into VPLC arrays "+pad.topic,pad.par,pad.val);
	if (pad.targ is FizAI) {
		AI[pad.targ.num].SP=pad.val; publishAI(AI[pad.targ.num]);//На этом этапе нужно осуществить отправку новых данных в брокер касательно объекта
		pad.targ.processData({"SP":pad.val});
	}
}

function insertPushBtn(btn:*):void{
	trace("Inserting data directly into VPLC arrays "+btn.numDQ);
	trace(btn.numDQ,btn.numDI);
	var sendDQ:Boolean=true;
	if (DQ[btn.numDQ].fiz==1) sendDQ=false;
	btn.Status=2;
	sendDataMQTT(DQ[btn.numDQ].dst,sendDQ);
}
function sendDataMQTT(topic:String, val:*):void{
	var pObj:Object=new Object();
	var arr:Array=topic.split(":");
	trace("Destenation array of PushBtn = "+arr);
	trace("Topic = "+arr[0]);
	if (arr.length>1){
		if (arr.length>2){
			var inObj:Object=new Object();
			inObj[arr[2]]=val;
			pObj[arr[1]]=inObj;
			trace("Dest data is infolded in parameter "+arr[1]+". the value is "+arr[2]+"="+val);
		} else {
			pObj[arr[1]]=val;
			trace("Dest data is "+arr[1]+"="+val);
		}
	}
	pObj.topic=arr[0];
	publishObj(false,pObj,0,"none");
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
function removeData():void{ //Очистка рабочего поля, и активных объектов. Работает перед распаковной нового проекта setUpProject()
	this.removeEventListener(Event.ENTER_FRAME, updateData);
	//set_btn.visible=true; //rem_btn.visible=false;
	container.removeChildren();
	activeObj=[]; activeOs.text="";
}

function updateFunc(object:Object):void {
	trace("Some update message initialized!!!");
	switch (object.f){
		case "AI": manageAnalogInput(object.a,(object.p).toString().split(",")); break;
	}
}

function addKotel(kotelnaya:XML,object:XML):Kotel{
	//trace("Need to add a Subscription on "+object.toXMLString());
	//<object id="5" type="Kotel0" x="500" y="500" size="1" num="0" auto="0" gor0="MASC/tags/DQ/0:fiz" gor1="MASC/tags/DQ/1:fiz" isOn="MASC/tags/DI/9:fiz" isFlame0="MASC/tags/DI/0:fiz" isFlame1="MASC/tags/DQ/0:fiz"/>
	var kotel:Kotel=new Kotel();
	kotel.type=int((object.@type).toString().substring(5,1));
	kotel.num=object.@num;
	if (kotelnaya.@num!=undefined) kotel.kotelnaya=kotelnaya.@num; else kotel.kotelnaya=0;
	kotel.src_blocked=kotelnaya.@mode;
	kotel.src_gor0=object.@gor0;
	kotel.src_gor0_v=object.@gor0_v;
	kotel.src_gor1=object.@gor1;
	kotel.src_gor1_v=object.@gor1_v;
	kotel.src_isOn=object.@isOn;
	kotel.src_isFlame0=object.@isFlame0;
	kotel.src_isFlame1=object.@isFlame1;
	kotel.src_mode=object.@mode;
	kotel.src_mode_v=object.@mode_v;
	//Kotli.push(kotel);
	trace("Added kotel to algorithm. Type="+ kotel.type+". Source for auto = "+kotel.src_mode+". Sources="+kotel.src_gor0,kotel.src_gor1,kotel.src_isOn,kotel.src_isFlame0,kotel.src_isFlame1);
	return kotel
}

//--------------------------------------Бутафорские функции, просто для того, чтоб в runtime.as был общий код и вызов функций-----------------------------------------//
function setSlMove(tar:*):void{}
//function setNumPad(obj:*):void{}