import masc.tags.Kotel;

function processKotel(kotel:Kotel):void{
	//trace(dq.src);
	var obj:Object
	var errOld:int;
	var src:String="";  var srcArr:Array=[]
	var tag:String="";
	var value:int=0;
	var tagName:String="";
	var kotArr:Array=[kotel.src_gor0_v,kotel.src_gor1_v,kotel.src_isOn,kotel.src_isFlame0,kotel.src_isFlame1];
	var kotTag:Array=["gor0","gor1","isOn","isFlame0","isFlame1"];

	kotel.args=[]; kotel.vals=[]; 	
	kotel.pub=false;
	
	//trace("Processing Kotel №"+kotel.num+" in kotelnaya №"+kotel.kotelnaya+". Tags="+kotTag+". kotArr="+kotArr);
	
	while (kotArr.length>0){ 
		//trace("We are initializing serach of object "+src,src.split(":").length);
		tagName=kotTag[0]; src=kotArr[0];
		if (src.split(":").length>0){
			srcArr=src.split(":");
			src=srcArr[0];
			tag=srcArr[srcArr.length-1];
		} else {
			tag="fiz";
		}
		if (tag=="RAW"){
			if (mainData[src]) {value=int(mainData[src]);} else {kotel.noSub=checkSubscription(src, kotel.noSub); return;}
			//trace("Found RAW data in "+src,value,kotel[tagName]);
			if (int(kotel[tagName])!=value){
				kotel[tagName]=value;
				//trace("Found prop kotel."+tagName+" = "+value);
				kotel.pub=true;
				kotel.args.push(tagName);
				kotel.vals.push(value.toString());
			}
		} else {
			obj=mainData[src];
			if (tag.length==0) tag="fiz";
			if (obj) {} else {kotel.noSub=checkSubscription(src, kotel.noSub); return;}
		
			if (obj[tag]!=undefined) {
				//trace("Found data = "+src,tag,mainData[src],kotel[tagName],int(obj[tag]));
				if (int(kotel[tagName])!=int(obj[tag])){
					kotel[tagName]=int(obj[tag]);
					//trace("Found prop kotel."+kotTag[0]+" = "+int(obj[tag]));
					kotel.pub=true;
					kotel.args.push(kotTag[0]);
					kotel.vals.push(int(obj[tag]).toString());
				}
			} else {
				processError("У поставщика информации "+(src).toString()+" нет параметра "+tag+" для Kotla"+(kotel.num).toString());
			}
		}
		
		kotArr.shift(); kotTag.shift();
	}
	//trace("Processed kotel"+kotel.isOn,kotel.isFlame0,kotel.isFlame1,kotel.gor0,kotel.gor1);
	return;
	//Гду-то тут нужен обработчик состояний, а именно смены значения по фильтру. Можно использовать параметр time, но думаю в этом нет смысла, так как значения и так ленивые
	if (errOld!=dq.err) {dq.args.push("err"); dq.vals.push(dq.err);}
}