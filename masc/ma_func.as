import flash.events.Event;

function updateData(e:Event):void{
	if (servicing==false){
		connect_mc.gotoAndStop(3); //trace("No connection!");
		return;
	}
	var trg:*;
	var reqVal:String="";
	activeOs.text=(activeObj.length).toString();
	
	for (var f4r:Number=0; f4r<activeObj.length; f4r++){
		trg=activeObj[f4r];
		reqVal=trg.path; //trace(activeObj[f4r].reqVal,mainData[reqVal]);
		trace("Object is searching for "+reqVal);
		if (mainData[reqVal]){
			//trace(activeObj[f4r],reqVal,mainData[reqVal]);
			if (trg.enable && trg.val.text!=mainData[reqVal]) {
				trg.val.text=mainData[reqVal];
				if (trg is InputT){
					trg.val.appendText(" "+trg.units);
				}
				if (trg is SliderVD){
					var num:Number=int(mainData[reqVal]);
					//trace(num,trg.valH,trg.valL,num/trg.valH);
					num=((num-trg.valL)/(trg.valH-trg.valL))*100;
					trg.headSl.y=int(num);
					//trg.val.appendText(" "+trg.units);
				}
			}
		}
	}
}


function addServer(nam:String,host:String,port:String="1883",main:Boolean=false):void{
	if (nam=="" || host=="") {
		trace("Внимание! Сервер не добавлен"); return;
	} else {
		trace("Добавляю сервер "+nam,host,port,main);
		//serverArr.push([serverArr.length,nam,host,port,main]);
		servers.addItem({label:nam, host:host, port:port, main:main});
	}
}
function remServer(nam:String,host:String,port:String,main:Boolean=false):void{
	if (nam=="" || host=="") {
		trace("Внимание! Сервер не удалён"); return;
	} else {
		//serverArr.push([serverArr.length,nam,host,port,main]);
		servers.removeItem({label:nam,data:host});
	}
}

function setServer(e:Event):void{
	var host:String=settWin.servers_cbx.selectedItem.host;
	trace(settWin.servers_cbx.selectedItem.label,host);
	var serArr:Array=servers.toArray();
	trace("serArr="+serArr);
	for each(var server in serArr){
		trace(server.host,host);
		if (server.host==host){
			settWin.nameSr_txt.text=server.label;
			settWin.host_txt.text=server.host;
			settWin.port_txt.text=server.port;
			settWin.mainSrv_ckb.selected=server.main;
			break;
		}
	}
}

function saveProject():void{
	//if (projectName=""){return}
	ff = new File();
	ff.save(projectXML,projectName);
}
function loadFileData(e:Event):void{
	ff.removeEventListener(Event.SELECT, loadFileData);
	ff.removeEventListener(Event.CANCEL, cancelFileData);
	ff.addEventListener(Event.COMPLETE, loadedData);
	ff.load();
}
function loadedData(e:Event):void{
	ff.removeEventListener(Event.COMPLETE, loadedData);
	projectXML=XML(ff.data); //trace("Data loaded "+ff.data)
	projectName=ff.name;
	save_btn.visible=true; //trace(projectXML);
	setUpProject();
}
function cancelFileData(e:Event):void{
	ff.removeEventListener(Event.CANCEL, cancelFileData);
	ff.removeEventListener(Event.SELECT, loadFileData);
}
function loadProject():void{
	ff=new File();
	ff.addEventListener(Event.CANCEL, cancelFileData);
	ff.addEventListener(Event.SELECT, loadFileData);
	ff.browse([macsFiles]);
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
function setUpProject():void{ //распаковка нового проекта
	sourceArr=[]; sources = new DataProvider(); var tempArr:Array=[]; 
	var ns=projectXML.namespace();
	for each (var source in projectXML..ns::Sources..ns::source) {
		if (String(source.@enabled)=="true"){
			trace(source.@id,source.@name,source.@path,source.@enabled);
			tempArr[0]=source.@id; tempArr[1]=source.@name; tempArr[2]=source.@path;
			sourceArr[source.@id]=tempArr;
			sources.addItem( { label: tempArr[1], data: tempArr[0]} );
		}
	}
	for each (var object in projectXML..ns::Objects..ns::object) {
		//trace(object.attribute("id"),object.attribute("type")); var types:String=object.attribute("type");
		switch (String(object.@type)){
			case "InputT": placeInputT(object); break;
			case "Slider": placeSlider(object); break;
			default: trace("Some unhandled object: "+object.@type); break;
		}
	}
}
function placeInputT(object:*):void{
	var txt:InputT=new InputT();
	txt.id=object.@id; //where txt from ID
	txt.enable=true;
	txt.units=object.@units;
	txt.inputVal.visible=false;
	txt.val.mouseEnabled=false;
	txt.x=int(object.@x);
	txt.y=int(object.@y);
	txt.scaleX=txt.scaleY=int(object.@size);
	txt.val.textColor=object.@color;
	txt.module=int(object.@module);
	txt.reqVal=String(object.@val);
	txt.reqSource=object.@source;
	txt.path=getPath(txt,txt.reqSource,txt.module,txt.reqVal);
	container.addChild(txt);
	activeObj.push(txt);
}
function getPath(targ:*, _source:int, _module:int, _varName:String):String{
	var ns=projectXML.namespace(); 
	var varType:String=_varName.substr(0,2); 
	var varNum:int=int(_varName.substring(2,_varName.length));
	var varNam:String="";
	for each (var source_ in projectXML..ns::Sources..ns::source){
		if (source_.@id==_source){
			for each (var module_ in source_..ns::module){
				if (int(module_.@id) == _module){
					for each (var var_ in module_.children()){
						varNam=var_.localName();
						if ((varNam==varType)&&(int(var_.@id)==varNum)){
							trace("Variable path found"); 
							targ.units=var_.@units;
							return var_.@path;
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
function showInsIT(tar:InputT):void{
	var iTSetW:ITSetW = new ITSetW(); for (var f4r:Number=0; f4r<insWindArr.length; f4r++){ if (insWindArr[f4r].tar==tar) {iTSetW=insWindArr[f4r]; break;}}
	iTSetW.x=tar.x+tar.width; if (iTSetW.x+iTSetW.width>1920) iTSetW.x=tar.x-iTSetW.width; iTSetW.y=tar.y; if (iTSetW.y+iTSetW.height>1080) iTSetW.x=1080-iTSetW.height;
	iTSetW.tar=tar;
	tar.setWin=iTSetW;
	iTSetW.sources=sources;
	iTSetW.projectXML=projectXML;
	iTSetW.init(); insWindArr.push(iTSetW);
	stage.addChild(iTSetW); 
}
function getVariables(src:*,types:Array):DataProvider{
	variables=new DataProvider();
	var ns=projectXML.namespace();
	var sourcesXml=projectXML..ns::Sources..ns::source;
	var sourceXml:XML = new XML(); var varsXml:XML;
	for each (var source in projectXML..ns::Sources..ns::source) {
		trace(source.attribute("id"),source.attribute("name"));
		if (int(source.attribute("id"))==int(src)) {
			trace("Found sourse, now to modules");
			sourceXml=source; break;
		};
	}
	if (int(sourceXml.length())<5) {sourceXml=sourcesXml[0]}
	//var modules = sourceXml..ns::module;
	for each (var module in sourceXml..ns::module) {
		trace(module.@type);
		var st:String=module.@type; var stLen:int=st.length;
		for (var f4r:int=0; f4r<types.length; f4r++){
			st=st.split(types[f4r]).join("");
		}
		if (stLen!=st.length){
			trace("found data neened: "+module.@id, module.@manufacturer, module.@name, module.@type);
			
			//varsXml = module; var vars:*=varsXml.children();
			for each (var vare in module.children()) {
				trace(vare.localName(),vare.@id, vare.@name);
				variables.addItem({label: vare.localName()+vare.@id+" "+vare.@name, data: vare.localName()+vare.@id});
			}
		}
	}
	return variables;
}
function placeSlider(object:*):void{
	var sl:SliderVD=new SliderVD();
	switch((object.@vect).toString()){
		case "VD": trace(sl.vect); sl.scaleY=-1; sl.val.scaleY=-1; sl.inputVal.scaleY=-1; sl.val.y=sl.val.y+sl.height/2+sl.val.height/2; sl.inputVal.x=15; break;
		case "VU": trace(sl.vect); sl.rotation=180; break;//sl.val.y=sl.val.y+sl.height/2+sl.val.height/2; sl.inputVal.x=15; break;
		case "HR": trace(sl.vect); sl.rotation=-90; sl.val.rotation=-90; sl.inputVal.rotation=-90; break;
		case "HL":
	}
	object.@type="Slider";
	sl.id=object.attribute("id");						//where sl from ID - это так же и слой
	sl.inputVal.visible=false;							//элемент отображения значения ввода
	sl.inputVal.mouseEnabled=false;						//он скрыт и не кликабелен
	sl.val.mouseEnabled=false;							//собственно отображение основное заблочено
	sl.maxX=int(object.attribute("dimX"));				//рамки перемещения слайдера по X
	sl.maxY=int(object.attribute("dimY"));				//рамки перемещения слайдера по Y
	sl.valL=int(object.attribute("min"));				//нижнее значение
	sl.valH=int(object.attribute("max"));				//верхнее значение
	sl.x=int(object.attribute("x"));					//положение X
	sl.y=int(object.attribute("y"));					//положение Y
	sl.scaleX=sl.scaleY=int(object.attribute("size"));	//Размер
	sl.enable=true;										//выбираемое
	sl.vect=(object.@vect).toString();					//вектор слайдера
	switch (sl.vect) {
		//case "VU": trace(sl.vect); sl.scaleY=-1; sl.val.scaleY=-1; sl.inputVal.scaleY=-1; sl.val.y=sl.val.y+sl.height/2+sl.val.height/2; sl.inputVal.x=15; break;
		case "VU": trace(sl.vect); sl.rotation=180; break;//sl.val.y=sl.val.y+sl.height/2+sl.val.height/2; sl.inputVal.x=15; break;
		case "HR": trace(sl.vect); sl.rotation=-90; sl.val.rotation=-90; sl.inputVal.rotation=-90; break;
		case "HL": trace(sl.vect); sl.rotation=90; sl.val.rotation=90; sl.inputVal.rotation=90; sl.val.y=-80; sl.inputVal.y=15; break;
	}
	container.addChild(sl);
	activeObj.push(sl);
}
function showInsSL(tar:*):void{
	
}