import flash.text.TextField;
import flash.text.TextFormat;

function setPage(pageNum:uint):void{
	if (activePage==pageNum) return;
	activePage==pageNum;
	var reqVal:String="";
	var ns=projectXML.namespace();
	try {container.removeChildren();} catch (Error:*) {trace("Error while cleaning container")}
	activeObj=[];
	for each (var page in projectXML..ns::Page) {
		if (uint(page.@id)==pageNum){
			trace(page.@name,page.@icon);
			break;
		}
	}
	//trace(page);
	var add:Boolean=true; var obj:*; var enable:Boolean=true;
	for each (var object in page..ns::object){//trace(object.attribute("id"),object.attribute("type")); var types:String=object.attribute("type");
		add=enable=true;
		switch (String(object.@type)){
			case "Kotel0": obj=new Kotel0(); break;
			case "TextData": obj=new TextData(); break;
			case "KlapanA": obj=new KlapanA(); break;
			//case "KlapanD": obj=new KlapanD();; break;
			//case "PumpD": obj=new PumpD();; break;
			//case "Slider": placeSlider(object); break;
			case "PushBtn": obj=new PushBtn(); break;
			case "SlideBtn": obj=new SlideBtn(); break;
			case "LampDI": obj=new LampDI(); break;
			case "FizAI": obj=new FizAI(); break;

			case "Tube": obj=new Tube(); trace("Tube"); break;
			//case "Fitting1": placeFitting(object,1); break;
			//case "Fitting2": placeFitting(object,2); break;
			//case "Fitting3": placeFitting(object,3); break;
			//case "Warn": placeWarn(object); break;
			//case "Ico_StreetT": placeIco_StreetT(object); break;
			default: trace("Some unhandled object: "+object.@type); add=false; break;
		}
		//var _class:Object = getDefinitionByName(String(object.@type)); var _obj = new _class(); trace("------------------------------Собирается новый объект типа: "+_obj+"------------------------------");
		
		if (add) {
			trace("Adding object "+object.@type+" to page. Object type is "+obj); 
			try{
				obj.initObj(object);
			} catch (Error:*) {trace("Some error while initializing object via initObj...")} 
			try {
				if (object.@type=="FizAI") obj.eu=getAIeu(object.@num);
			} catch (Error:*) {trace("Some error while getting EU for AI...")} 
			container.addChild(obj);
			try {if (object[enable]==false) enable=false} catch (Error:*) {enable=true;}
			if (enable) activeObj.push(obj);
			updateWindowObject(obj); //Когда мы запускаем клиента из под виртуального контроллера этот вызов уходит в объект VPLC.fla в ClietWin, а оттуда вызывается родительская функция с таким же именем.
		}
	}
	trace("Page setUp finished");
	updateClients();
}

function getAIeu(num:int):String{
	var eu:String="";
	var ns=projectXML.namespace();
	for each (var ai in projectXML..ns::PLC..ns::ai) {
		if (ai.@num==num)  {eu=ai.@eu; trace("Got eu for object "+ eu);} break;
	}
	return eu;
}

function placeIco_StreetT(object:*):void{
	trace("Placing icon Ico_StreetT");
	var pb:Ico_StreetT=new Ico_StreetT;
	pb.x=int(object.@x); pb.y=int(object.@y);
	pb.scaleX=pb.scaleY=Number(object.@size);
	container.addChild(pb);
}

function getVarName(_source:uint, _module:uint,_var:uint):String{
	var retStr:String="";
	var ns=projectXML.namespace(); 
	for each (var source_ in projectXML..ns::Sources..ns::source){
		if (source_.@id ==_source){
			for each (var module_ in source_..ns::module){
				if (int(module_.@id) == _module){
					for each (var var_ in module_.children()){
						if (int(var_.@id)==_var){
							trace("Variable path found"); 
							return (var_.@name).toString();
						}
					}
				}
			}
		}
	}
	return "";
}

function placeFitting(object:*,num:uint=2):void{
	trace("Placing Fitting  "+int(object.@x),int(object.@y),Number(object.@size),int(object.@min),int(object.@max),object.@value);
	var pb;
	switch (num){
		case 1: pb=new Fitting1(); break;
		case 2: pb=new Fitting2(); break;
		case 3: pb=new Fitting3(); break;
		default: return; break;
	}
	pb.x=int(object.@x);
	pb.y=int(object.@y);
	pb.scaleX=pb.scaleY=Number(object.@size);
	pb.rotation=int(object.@rotation);
	pb.val.gotoAndStop(uint(object.@color));
	pb.enable=Boolean((object.@trigger).toString()=="true");
	if (pb.enable){
		var tArr:Array=(object.@value).split(",");
		pb.src=tArr[0]//int(object.@source);
		pb.mdl=tArr[1]//int(object.@moduleID);
		pb.pin=tArr[2]//int(object.@val);
		activeObj.push(pb);
	}
	pb.mouseEnabled=pb.mouseChildren=false;
	container.addChild(pb);
}

function placeSlideBtn(object:*):void{
	trace("Placing SlideBtn "+int(object.@x),int(object.@y),Number(object.@size),int(object.@min),int(object.@max),object.@value);
	var pb:SlideBtn=new SlideBtn();
	pb.x=int(object.@x);
	pb.y=int(object.@y);
	pb.scaleX=pb.scaleY=Number(object.@size);
	//pb.val.textColor=object.@color;
	pb.valL=int(object.@min);				//нижнее значение
	pb.valH=int(object.@max);
	var tArr:Array=(object.@value).split(",");
	pb.src=tArr[0]//int(object.@source);
	pb.mdl=tArr[1]//int(object.@moduleID);
	pb.pin=tArr[2]//int(object.@val);
	pb.val.gotoAndStop(uint(object.@color));
	pb.mouseChildren=false;
	container.addChild(pb);
	activeObj.push(pb);
}

function placeSlider(object:*):void{
	var sl:SliderVD=new SliderVD();
	sl.vect=(object.@vect).toString();					//вектор слайдера
	trace("Placing Slider   "+int(object.@x),int(object.@y),Number(object.@size),int(object.@dimY),object.@value);
	switch(sl.vect){
		case "VD": break;
		case "VU": sl.rotation=180; break;//sl.val.y=sl.val.y+sl.height/2+sl.val.height/2; sl.inputVal.x=15; break;
		case "HR": sl.rotation=-90; sl.val.rotation=-90; sl.inputVal.rotation=-90; break;
		case "HL": sl.scaleY=-1; sl.val.scaleY=-1; sl.inputVal.scaleY=-1; sl.val.y=sl.val.y+sl.height/2+sl.val.height/2; sl.inputVal.x=15; break;
	}
	object.@type="Slider";
	sl.id=object.@id;						//where sl from ID - это так же и слой
	sl.inputVal.visible=false;							//элемент отображения значения ввода
	sl.inputVal.mouseEnabled=false;						//он скрыт и не кликабелен
	sl.val.mouseEnabled=false;							//собственно отображение основное заблочено
	sl.maxX=int(object.@dimX);				//рамки перемещения слайдера по X
	sl.maxY=int(object.@dimY);				//рамки перемещения слайдера по Y
	sl.valL=int(object.@min);				//нижнее значение
	sl.valH=int(object.@max);				//верхнее значение
	sl.x=int(object.@x);					//положение X
	sl.y=int(object.@y);					//положение Y
	sl.scaleX=sl.scaleY=Number(object.@size);	//Размер
	sl.enable=true;										//выбираемое
	var tArr:Array=(object.@value).split(",");
	sl.src=tArr[0]//int(object.@source);
	sl.mdl=tArr[1]//int(object.@moduleID);
	sl.pin=tArr[2]//int(object.@val);
	container.addChild(sl);
	activeObj.push(sl);
}