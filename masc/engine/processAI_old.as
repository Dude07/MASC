import masc.tags.AnalogInput;
var obj:Object
var errOld:int;
var tag:String="";
var value:Number=0;

function processAI(ai:AnalogInput):void{
	//trace(ai.src);
	ai.args=[]; ai.vals=[];
	obj=mainData[ai.src];
	tag="fiz";
	if (ai.tag.length>0) tag=ai.tag;
	if (obj) {} else {ai.noSub=checkSubscription(ai.src, ai.noSub); return;}
	//trace(obj.cod, obj.fiz);
	//trace("Got data " +tag+"="+obj[tag],ai.type,obj[tag],ai.fiz,Number(obj[tag])==ai.fiz);
	if (ai.type==1) {
		if (obj[tag]) {
			value=obj[tag];
			if (value==ai.fiz) ai.pub=false; else {ai.fiz=value; trace("Аналоговый вход №"+ai.num+". "+ai.name+". Значение сигнала = "+ai.fiz); ai.pub=true; ai.args=["fiz"]; ai.vals=[(ai.fiz).toString()]}
		} else {
			processError("У поставщика информации "+(ai.src).toString()+" нет параметра "+tag+" для AI"+(ai.num).toString());
		}
		return;
	}
	var cod:int=0;
	if (obj[tag]) cod=obj[tag]; else {
		if (obj.fiz) cod=obj.fiz; else {processError("У поставщика информации "+(ai.src).toString()+" нет параметра fiz для AI"+(ai.num).toString()); return}
		processError("У поставщика информации "+(ai.src).toString()+" нет параметра "+tag+" для AI"+(ai.num).toString()+". Был найден парамерт fiz, использую как cod");
	}
	if (cod==ai.cod) {ai.pub=false; return;}
	trace(Math.abs(cod-ai.cod),(ai.cod_max-ai.cod_min)/100);
	if (Math.abs(cod-ai.cod)>(ai.cod_max-ai.cod_min)/100) ai.args=["fiz","mA"] else ai.args=[];
	ai.cod=cod; ai.pub=true; errOld=ai.err;
	//----------------тут вставляется код обработки кодов аналогового сигнала-------------------------//
	//код хранится в переменной cod. Все присвоения и данные mA и кодов соответственно находятся в объекте ai.*
	
	ai.mA=(ai.cod-ai.cod_min)*(ai.mA_max-ai.mA_min)/(ai.cod_max-ai.cod_min)+ai.mA_min;
    if (ai.mA_max != ai.mA_min) { 	
      ai.fiz_notF= (ai.mA - ai.mA_min) / (ai.mA_max - ai.mA_min); 
    }  else ai.fiz_notF=0;
	
	//if (ai.fiz_notF<0) ai.fiz_notF=0; ai.fiz=0; return; //Это можно раскоментарить в будущем, чтоб если данные прилетели отрицательные - не выполнять вычислений, а сразу присвоить в ноль...

	ai.fiz_notF = ai.fiz_notF * (ai.fiz_max - ai.fiz_min) + ai.fiz_min;
	
	ai.fiz_notF=Math.round(ai.fiz_notF * 1000)/1000; //Откинуть дальше третьего знака от запятой...
	
    ai.err=0;	
	
    if (ai.fiz_max > ai.fiz_min) {
      if (ai.fiz_notF>ai.fiz_max) {
       ai.fiz_notF=ai.fiz_max;
       ai.err=1;
      } else {
        if (ai.fiz_notF<ai.fiz_min) {
         ai.fiz_notF=ai.fiz_min;
         ai.err=1;
        }
      }  
    }  
    if (ai.fiz_max<ai.fiz_min) {
      if (ai.fiz_notF<ai.fiz_max) {
       ai.fiz_notF=ai.fiz_max;
       ai.err=1;
      } else {
        if (ai.fiz_notF>ai.fiz_min) {
         ai.fiz_notF=ai.fiz_min;
         ai.err=1;
        }
      }  
    }  
    if (ai.fiz_max==ai.fiz_min) ai.fiz_notF=ai.fiz_min;

    if (ai.filtr > 0) {
      ai.fiz=(ai.filtr * ai.fiz + ai.fiz_notF)/(ai.filtr + 1); 
    } else ai.fiz = ai.fiz_notF;
	if (ai.args.length>0) ai.vals=[ai.fiz,ai.mA];
	if (errOld!=ai.err) {ai.args.push("err"); ai.vals.push(ai.err);}
	 //ai.cod=ai.fiz=cod;//это временное присвоение, без свяких там операций...
	trace(ai.args,ai.vals);
	
	cod=undefined;
	//---------------------------------------------***------------------------------------------------//
	//trace("Аналоговый вход №"+ai.num+". "+ai.name+". Значение сигнала = "+ai.fiz+"; mA="+ai.mA);
}