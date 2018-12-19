import fl.data.DataProvider;
import flash.events.Event;
import flash.display.MovieClip;

var tar:*;
var cTar:Array=[];
var projectXML:XML=new XML();
var sources:DataProvider=new DataProvider();
var variables:DataProvider=new DataProvider();
cancelChanges_btn.visible=false;

function updateTar(e:Event):void{
	//trace("changeing something");
	switch (e.target){
		case stW_x: tar.x=stW_x.value; break;
		case stW_y: tar.y=stW_y.value; break;
		case stW_scale: tar.scaleX=tar.scaleY=stW_scale.value; break;
		case stW_source: tar.reqSource=stW_source.selectedIndex; break;
		case stW_var: tar.reqVar=stW_var.selectedItem.data; tar.path=stW_var.selectedItem.path; break;
		case stW_units: tar.units=stW_units.selectedItem.label; tar.val.text="## "+tar.units; break;
		case stW_colorT: tar.val.textColor=stW_colorT.selectedColor; break;
		case stW_enabled: tar.edited=stW_enabled.selected; break;
	}
}
	
function init():void{
	updateData(true);
	stW_x.addEventListener(Event.CHANGE, updateTar);
	stW_y.addEventListener(Event.CHANGE, updateTar);
	stW_enabled.addEventListener(Event.CHANGE, updateTar);
	stW_scale.addEventListener(Event.CHANGE, updateTar);
	stW_source.addEventListener(Event.CHANGE, updateTar);
	stW_var.addEventListener(Event.CHANGE, updateTar);
	stW_colorT.addEventListener(Event.CHANGE, updateTar);
	stW_units.addEventListener(Event.CHANGE, updateTar);
}

function deInit():void{
	stW_x.removeEventListener(Event.CHANGE, updateTar);
	stW_y.removeEventListener(Event.CHANGE, updateTar);
	stW_enabled.removeEventListener(Event.CHANGE, updateTar);
	stW_scale.removeEventListener(Event.CHANGE, updateTar);
	stW_source.removeEventListener(Event.CHANGE, updateTar);
	stW_var.removeEventListener(Event.CHANGE, updateTar);
	stW_colorT.removeEventListener(Event.CHANGE, updateTar);
	stW_units.removeEventListener(Event.CHANGE, updateTar);
	tar=null; cTar=null;
}
function cancelChanges(close:Boolean=false):void{
	//cTar=[tar.x,tar.y,tar.scaleX,tar.edited,tar.val.textColor,tar.reqSource,tar.reqVal]
	trace("Trying to cancel changes "+cTar);
	tar.x=cTar[0]; tar.y=cTar[1];
	tar.scaleX=tar.scaleY=cTar[2];
	if (cTar[3]) tar.edited=cTar[3];
	tar.val.textColor=cTar[4];
	if (cTar[5]) tar.reqSource=cTar[5];
	if (cTar[6]) tar.reqVal=cTar[6];
	if (close) deInit();
}
function updateData(all:Boolean=false):void{
	stW_x.value=tar.x; stW_y.value=tar.y;
	if (all==false) return;
	if (tar.edited) stW_enabled.selected=tar.edited;
	//trace(tar.reqSource,tar.reqVal);
	stW_scale.value=tar.scaleX;
	stW_colorT.selectedColor=tar.val.textColor;
	stW_source.dataProvider=sources;
	if (tar.reqSource) {stW_source.selectedItem=int(tar.reqSource);} else {stW_source.selectedItem=0;}
	stW_var.dataProvider=getVariables(stW_source.selectedItem,["AI","AO"]);
	if (tar.reqVar) {
		trace(tar.reqVar);
		for each (var varr in stW_var.dataProvider.toArray()){
			trace(varr.label,varr.data)
			if (varr.data==tar.reqVar)	stW_var.selectedItem=varr;
		}
	}
	if (tar.units) {
		for each (var item in stW_units.dataProvider.toArray()){
			if (item.label==tar.units) stW_units.selectedItem=item;
		}
	}
	//trace("stW_units.dataProvider="+stW_units.dataProvider);
	//var dt:DataProvider=new DataProvider(); dt.getItemIndex();
	
	
	cTar=[tar.x,tar.y,tar.scaleX,tar.edited,tar.val.textColor,tar.reqSource,tar.reqVal,tar.units];
	/*if (tar){
		if (tar.x) cTar.xX=tar.x;
		if (tar.y) cTar.yY=tar.y;
		if (tar.edited) cTar.edited=tar.edited;
		if (tar.scaleX) cTar.scale=tar.scaleX;
		if (tar.val.textColor) cTar.colorT=tar.val.textColor;
		if (tar.reqSource) cTar.reqSource=tar.reqSource else cTar.reqSource=0;
		if (tar.reqVal) cTar.reqVal=tar.reqVal;
	}*/
}

function getVariables(src:*,types:Array):DataProvider{
	variables=new DataProvider();
	var ns=projectXML.namespace();
	var sourcesXml=projectXML..ns::Sources..ns::source;
	var sourceXml:XML = new XML(); var varsXml:XML;
	for each (var source in projectXML..ns::Sources..ns::source) {//trace(source.attribute("id"),source.attribute("name"));
		if (int(source.attribute("id"))==int(src)) {//trace("Found sourse, now to modules");
			sourceXml=source; break;
		};
	}
	if (int(sourceXml.length())<5) {sourceXml=sourcesXml[0]}
	for each (var module in sourceXml..ns::module) {
		//trace(module.@type);
		var st:String=module.@type; var stLen:int=st.length;
		for (var f4r:int=0; f4r<types.length; f4r++){
			st=st.split(types[f4r]).join("");
		}
		if (stLen!=st.length){//trace("found data neened: "+module.@id, module.@manufacturer, module.@name, module.@type);
			for each (var vare in module.children()) {
				//trace(vare.localName(),vare.@id, vare.@name);
				variables.addItem({label: vare.localName()+vare.@id+" "+vare.@name, data: vare.localName()+vare.@id, path: vare.@path});
			}
		}
	}
	return variables;
}