import flash.net.Socket;
import flash.utils.ByteArray;
import flash.utils.Timer;
import flash.events.TimerEvent;
import flash.text.TextField;
import flash.events.IOErrorEvent;
import masc.modbus.*;

var emulatorArr:Array=[];
var mb_eth_arr:Array=[];
function startModBus():void{
	trace("Starting ModBus server!");
	var ns=projectXML.namespace();
	var ip:String=""; var port,getReg,setReg:int; var tArr:Array=[];
	modBusStop_btn.visible=true; modBusBr_btn.visible=false;
	for each (var source in projectXML..ns::Sources..ns::source) {
		trace(source.@id,source.@name,source.@type,source.@path,source.@adress);
		if (source.@type=="MB_Eth") {//tempArr[0]=source.@id; tempArr[1]=source.@name; tempArr[2]=source.@type; tempArr[3]=source.@path; tempArr[4]=source.@adress; //sourceArr[source.@id]=tempArr;
			trace("Got a ethernet modbus!"); //path="MASC/tags/MB_SIEMENS-SRD/t0" getAdr="192.168.34.251" getReg="100"
			tArr=(source.@address).split(":")
			ip=tArr[0]; if (tArr[1]) port=int(tArr[1]) else port=502;
			getReg=int(source.@getReg);
			if (source.@setReg!=undefined){
				mb_eth_arr.push([source.@path,ip,port,getReg,int(source.@setReg)]);
			} else {
				mb_eth_arr.push([source.@path,ip,port,getReg]);
			}
		} else {
			emulatorArr.push(source);
		}
	}
	trace(mb_eth_arr);
}

function stopModBus():void{
	trace("Stoping ModBus server!");
	modBusStop_btn.visible=false; modBusBr_btn.visible=true;
}