import masc.tags.DiscretInput;

function processDI(di:DiscretInput):void{
	//trace("Processing DI "+di.num)
	var obj:Object
	var errOld:int;
	var tag:String="";
	var value:int=0;
	//trace(di.src);
	di.args=[]; di.vals=[]; 
	errOld=di.err; //Это чтоб не тащить значение ошибки, так как его не будет всё-равно
	obj=mainData[di.src];
	tag="fiz";
	if (di.tag.length>0) tag=di.tag;
	if (obj) {} else {di.noSub=checkSubscription(di.src, di.noSub); return;}

	//trace("Need data: "+di.src+":"+tag); trace("Got data " +tag+"="+obj[tag]);

	if (obj[tag]!=undefined) { //trace(obj[tag],obj[tag]==true,obj[tag]==false)
		if (Boolean(obj[tag])==true) value=1 else value=0; //trace("Old value="+di.fiz+". New value="+value+". Values match="+Boolean(value==di.fiz));
		if (value==di.fiz) di.pub=false; else {
			di.fiz=value; //trace("Дискретный вход №"+di.num+". "+di.name+". Значение сигнала = "+di.fiz); 
			di.pub=true; di.args=["fiz"]; di.vals=[(di.fiz).toString()]
		}
	} else {
		processError("У поставщика информации "+(di.src).toString()+" нет параметра "+tag+" для DI"+(di.num).toString());
	}
	return;
	//Гду-то тут нужен обработчик состояний, а именно смены значения по фильтру. Можно использовать параметр time, но думаю в этом нет смысла, так как значения и так ленивые
	if (errOld!=di.err) {di.args.push("err"); di.vals.push(di.err);}
}