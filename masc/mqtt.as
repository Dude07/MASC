import flash.net.Socket;
import flash.utils.ByteArray;
import flash.utils.Timer;
import flash.events.TimerEvent;
import flash.text.TextField;
import flash.events.IOErrorEvent;
import masc.tags.AnalogInput;

const MAX_LEN_UUID:int=23; const MAX_LEN_TOPIC:int=7; const MAX_LEN_USERNAME:int=12;	
const TOPIC_LEVEL_SEPARATOR:String = "/"; //Topic level separator
const TOPIC_M_LEVEL_WILDCARD:String = "#";//Multi-level wildcard
const TOPIC_S_LEVEL_WILDCARD:String = "+";//Single-level wildcard
const MY_HOST:String="iot.eclipse.org"; //broker.hivemq.com //You'd better change it to your private ip address! //test.mosquitto.org//16.157.65.23(Ubuntu)//15.185.106.72(hp cs instance)
const MY_PORT:Number=1883; //Socket port.
const CONNECT:uint=0x10; const CONNACK:uint=0x20;
const PUBLISH:uint=0x30; const PUBACK:uint=0x40;
const PUBREC:uint=0x50; const PUBREL:uint=0x60;
const PUBCOMP:uint=0x70; const SUBSCRIBE:uint=0x80;
const SUBACK:uint=0x90; const UNSUBSCRIBE:uint=0xA0;
const UNSUBACK:uint=0xB0; const PINGREQ:uint=0xC0;
const PINGRESP:uint=0xD0; const DISCONNECT:uint=0xE0;

const ALPHA_CHAR_CODES:Array=[48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 65, 66, 67, 68, 69, 70];

var topicArr:Array=new Array();
//var mainData:Object=new Object();
var sendData:Object=new Object();
var mqttSocket:Socket;
var serverID:uint=0;
var serversNum:uint=0;
var bytes:ByteArray;
var will:Array=[1,0,1,"MASK","LastWillByUser"]; /* stores the will of the client {willFlag,willQos,willRetainFlag} */
var isWill:Boolean=false; /*another variant for will*/
var isAuth:Boolean=false;
var username:String; /* stores username */
var password:String; /* stores password */
var QoS:int=0; /* stores QoS level */
var cleanSession:Boolean=true;
var topicname:String="MASC/";
var keepalive:int=10; /* default keepalive timmer */
var keep_alive_timer:Timer=new Timer(10000); //Set to 10 seconds (0x000A).
var servicing:Boolean; /*service indicator*/
var _isConnect:Boolean=false; var connected:Boolean=false; //_isConnect потом заменю везде на connected
var connectMessage:*;
var host:String; var port:int;
var connectTimeOut:Timer=new Timer(10000);
var tx:TextField=new TextField();
var stayOnline:Boolean=false;

var waitForSub:Boolean=false;
var listSubID:int;
var listTar:*;
var waitTopic:String="";
var waitForTop,needTop:Boolean=false;

function createUID():String{ //Функция генерирует случайных код устройства
	var uid:Array=new Array(36);
	var index:int=0;

	var i:int;
	var j:int;
	for (i=0; i < 8; i++){
		uid[index++]=ALPHA_CHAR_CODES[Math.floor(Math.random() * 16)];
	}
	for (i=0; i < 3; i++){
		uid[index++]=45; // charCode for "-"
		for (j=0; j < 4; j++){
			uid[index++]=ALPHA_CHAR_CODES[Math.floor(Math.random() * 16)];
		}
	}
	uid[index++]=45; // charCode for "-"

	//        var time:Number = new Date().getTime();
	var time:Number=new Date().time;
	// Note: time is the number of milliseconds since 1970, which is currently more than one trillion.
	// We use the low 8 hex digits of this number in the UID. Just in case the system clock has been reset to
	//Jan 1-4, 1970 (in which case this number could have only 1-7 hex digits), we pad on the left with 7 zeros
	// before taking the low digits.
	var timeString:String=("0000000" + time.toString(16).toUpperCase()).substr(-8);

	for (i=0; i < 8; i++){
		uid[index++]=timeString.charCodeAt(i);
	}
	for (i=0; i < 4; i++){
		uid[index++]=ALPHA_CHAR_CODES[Math.floor(Math.random() * 16)];
	}
	return String.fromCharCode.apply(null, uid);
} //createUID():String
function noConnection(e:TimerEvent):void{ //Если по какой-то причине после подключения к брокеру он не вернул подтверждение о подключении
	connectTimeOut.stop();
	connectTimeOut.removeEventListener(TimerEvent.TIMER, noConnection);
	tryDisconnect(true);
}
function tryConnect():void{ //Запуск подключения к MQTT брокеру. Методом перебора доступных серверов в соответствии с основным типом проекта
	var ns=projectXML.namespace(); var found:Boolean=false;
	var tempArr:Array=[]; serversNum=0;
	for each (var server in projectXML..ns::Servers..ns::server) {
		serversNum++;
		if (uint(server.@id)==serverID && server.@type==projectXML.projectType){ //if (uint(server.@id)==serverID && server.@type=="local") - проверял чтоб cервер был локальным, но это каcается типа проекта
			trace("Connceting to "+server.@type+" server:"+server.@id,server.@name,server.@ip, server.@port);
			mqttSocket = new Socket((server.@ip).toString(),int(server.@port)); found=true;
		}
	}
	if (found==false){
		serverID=0; //serverID++; if (serverID>=serversNum) serverID=0;
		tryConnect();
	} else {
		mqttSocket.addEventListener(Event.CONNECT, isConnected);
		mqttSocket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
		mqttSocket.addEventListener(Event.CLOSE, isClosed);
		mqttSocket.addEventListener(IOErrorEvent.IO_ERROR,noSocketConnection);
	}
}
function noSocketConnection(e:IOErrorEvent):void{ //Когда никто не ответил на запрос. Выводим сообщение и начинаем заново
	if (serverID>=serversNum) {serverID=0; toMessage("Внимание!", "Ни один из сконфигурированных брокеров не ответил на запрос о подключении. Проверьте соединения п попробуйте снова.")} else{ serverID++; tryConnect();}
}
function isConnected(e:Event):void{ //При успешном подключении к сокету брокера отправляем ему запрос на подключение. Запускаем таймер ожидания в noConnection
	trace("MQTT byte order:{0}", mqttSocket.endian);
	if (mqttSocket.endian != Endian.BIG_ENDIAN){ trace("Endian failed!"); return;}
	trace("Connection to server estableshed. Sending request to connect");
	mc_connecting.gotoAndPlay(2);
	connectTimeOut.reset();
	connectTimeOut.addEventListener(TimerEvent.TIMER, noConnection);
	connectTimeOut.start();
	bytes=new ByteArray();
	//------------------------VARIABLE HEADER------------------------//
	bytes.writeByte(0x00); //0 MSB
	bytes.writeByte(0x04); //4 LSB
	bytes.writeByte(0x4d); //M
	bytes.writeByte(0x51); //Q
	bytes.writeByte(0x54); //T
	bytes.writeByte(0x54); //T
	bytes.writeByte(0x04); //Protocol version = 4 for MQTT V3.1
	
	/*var type:int=0; //00000000//
	if (cleanSession) {type+=2};  //+00000010
		//Will flag is set (1), Will QoS field is 1, Will RETAIN flag is clear (0)	
		//(willFlag,willQos,willRetain)
	if (isWill){
		type+=4; //+00000100
		type+=will[1] << 3;//000**000 - пишется число  из will[1] и смещается на три позиции, потом добавляется к type
		if (will[2]) {type+=32;} //00100000 - добавляем значение retrain для will
	} 
		
	if (name_txt.text!="" && isAuth){
		type+=128; //10000000 - добавляем значение user flag
		if (password){type+=64;} //01000000 - добавляем значение password flag
	}
		
	bytes.writeByte(type); //add header info to CONNECT Message
	//Keep Alive timer
	bytes.writeByte(keepalive >> 8); //Keepalive MSB
	bytes.writeByte(keepalive & 0xff); //Keepaliave LSB = 60
	if (!clientid) {clientid=createUID().substr(0, MAX_LEN_UUID); userID_txt.text=clientid;}
	writeString(bytes, clientid);
			
	if (isWill){
		writeString(bytes, will[3]); //write will topic
		writeString(bytes, will[4]); //write will message
	}
			
	if (name_txt.text!="" && isAuth){
		writeString(bytes, username ? username : "");
		if (password){writeString(bytes, password ? password : "");}
	}*/ 
	//То что выше, нужно будет сделать, пока только CleanSession
	
	bytes.writeByte(0x02); //Ничего кроме CleanSession
	
	bytes.writeByte(keepalive >> 8); //Keepalive MSB
	bytes.writeByte(keepalive & 0xff); //Keepaliave LSB = 60
			
	var userID:String=createUID().substr(0,23); trace(userID,userID.length);
	writeString(userID);	

	mqttSocket.writeByte(CONNECT); // - protocol type (0x10)
	mqttSocket.writeByte(bytes.length);// - remaining length
	mqttSocket.writeBytes(bytes, 0, bytes.length);// - write data
	mqttSocket.flush();
	trace("Connect message send");
}//после соединения с сервером отправляем сообщение на подключение

function onSocketData(event:ProgressEvent):void{ //Если пришли данные от сокет сервера
	dataExp.text=(int(dataExp.text)+1).toString();
	var len:uint=mqttSocket.bytesAvailable;
	var byteArr:ByteArray=new ByteArray();
	mqttSocket.readBytes(byteArr,0,len);
	
	//trace("Got some data! + "+ byteArr.bytesAvailable); 
	btsAv.text=(byteArr.bytesAvailable).toString();

	var type:uint=byteArr.readUnsignedByte() & 0xF0; //trace("Тип полученных данных: "+type.toString(2)+". Hex data = "+type.toString(16));
	//var type:uint=mqttSocket.readUnsignedByte(); trace("Тип полученных данных: "+type.toString(2)); //Смысл сильно не меняется, странно, зачем добавление & 0xF0 к данным, наверное чтоб смещение было нормальное...
	switch (type){
		case 0: ping_mc.gotoAndPlay(3); break;
		case CONNACK: onConnack(byteArr); break;
		case PUBLISH: onPublish(byteArr); break;
		case PUBACK: /*onPuback();*/ trace("Publish acknowledgment"); break;
		//case PUBREC: onPubrec(result); trace("Assured publish received(part1)"); break;
		//case PUBREL: onPubrel(result); trace("Assured publish release(part2)"); break;
		case PUBCOMP: onPubcomp(byteArr); trace("Assured publish complete"); break;
		//case SUBSCRIBE: onSubscribe(result); trace("Subscribe to named topics"); break;
		case SUBACK: onSuback(byteArr); break;
		//case UNSUBSCRIBE: onUnsubscribe(result); trace("Subscription acknowledgement"); break;
		case UNSUBACK: onUnsuback(byteArr); break;
		//case PINGREQ: onPingreq(result); trace("PING request"); break;
		case PINGRESP: onPingresp(); break;
		/*case DISCONNECT: onDisconnect(result); trace("Client is Disconnecting"); break;
		*/
		default: trace("Reserved " + type); break;
	}
}

function onPubcomp(byteArr:ByteArray):void{
	onErrorMessage(byteArr);
}
function onErrorMessage(byteArr:ByteArray):void{
	var mL:int=byteArr.bytesAvailable;
	trace("Message onPubcomp length = "+mL);
	try {
		var mS:String=byteArr.readUTFBytes(mL);
	} catch (Error:*) {
		trace("Some error while handling message")
	}
	if (mS.length>0){
		trace("Error Handler message = "+mS);
	}
}

function getListElements(tar:*, topic:String):void{ //Запускает запрос на получение данных о содержании тегов в топике. Запускает функцию processList у объекта запроса, либо ждёт разовую подписку
	listTar=tar; waitTopic=topic; waitForTop=needTop=waitForSub=false;
	trace("Taking out data in topic"+topic+"for target="+tar+". Current topic array.length="+topicArr.length);
	for each(var top in topicArr) {
		trace(top)
		if (topic==top) {
			trace(topic+"=="+top+"?.....Found matching data in topic array? "+mainData[top]);
			needTop=true; 
			waitForTop=true; 
			if (mainData[topic]!=undefined) {
				waitForTop=false;
				trace("Got the requeted data in mainData")
				try {listTar.processList(mainData[topic]);} catch (Error:*) {trace("Object "+listTar+" doesn't have a processList function")}
			}
			return;
		}
	}
	waitForSub=true;
	trySubscribe(topic);
}

function onPublish(byteArr:ByteArray):void{ //Если прилетели данные от брокера
	//trace("Incoming Publish message");
	//trace("my ByteArray data length = "+byteArr.bytesAvailable);
	
	mqttRecieved.play();
	var pL:uint=getLen(byteArr);
	var tL:int=byteArr.readUnsignedShort(); //trace(tL.toString(2)); 
	tL=doLength(tL)
	var tS:String=byteArr.readUTFBytes(tL);	//trace("Topic string: <"+tS+">");
	var mL:int=byteArr.bytesAvailable;
	var mS:String=byteArr.readUTFBytes(mL);
	if (tS=="") {
		var pos:int=mS.search("{");
		tS=mS.substr(0,pos).split("").join("");
		mS=mS.substring(pos,mS.length);
	}
	
	/*
	mqttRecieved.play();
	var pL:uint=getLen(mqttSocket);
	//trace("Packet length: "+pL);
	var tL:int=mqttSocket.readUnsignedShort(); //trace(tL.toString(2)); 
	tL=doLength(tL)
	//trace("Topic Length = "+tL);
	var tS:String=mqttSocket.readUTFBytes(tL);	//trace("Topic string: <"+tS+">");
	var mL:int=mqttSocket.bytesAvailable;
	//trace("Message length = "+mL);
	var mS:String=mqttSocket.readUTFBytes(mL);
	if (tS=="") {
		var pos:int=mS.search("{");
		tS=mS.substr(0,pos).split("").join("");
		mS=mS.substring(pos,mS.length);
		//trace("Topic actual string: <"+tS+">");
	}
	//trace("Mesage string: <" +mS+">");
	
	*/
	parseJSON(tS,mS);
}//onPublish - recieveng a message

function parseJSON(topic:String,messag:String):void{ //Разбираем присланное сообщение от брокера в объект 
	//trace(topic);
	//trace(messag);
	var object:Object;
	try {object=JSON.parse(messag);} catch (Error:*){return}
	if (object["ts"]!=undefined){
		var ts:Number=object["ts"];
		var nn:int=myPubs.indexOf(ts);
		if (nn>=0){
			myPubs.splice(nn,1);
			trace("Got my own publish event. Canceling this.");
			return;
		}
	}
	if (vplc) {
		if (topic=="MASC/tags/update" || topic=="MASC/sets/update") {trace("Update message!!!!"); updateFunc(object); return; }
	}
	if (waitForTop){
		trace("I am waiting for topic "+waitTopic+". Got topic"+topic);
		if (waitTopic==topic) {
			trace("got requested topic data"); waitForTop=false;
			try {
				if (object.d==undefined) listTar.processList(object); else listTar.processList(object.d);
			} catch (Error:*) {trace("Object "+listTar+" doesn't have a processList function")}
			if (!needTop) {tryUnSubscribe(waitTopic);}
			
			return;
		}
	}
	if (object.d==undefined) {
		if (mainData[topic]!=object) {mainData[topic] = object; if (vplc && cycleTrigger=="MASC") searchData(topic,object);}
	} else {
		//trace("Got a WEINTEK data ")
		if (mainData[topic]!=object.d){
			mainData[topic]=object.d;
			if (vplc && cycleTrigger=="MASC") searchData(topic,object.d);
		}
	}
	if (vplc==false || cycleTrigger=="onMQTT") {updateData();}
}

function onConnack(byteArr:ByteArray):void{
	trace("Acknowledge connection request");
	var pL:int=byteArr.readUnsignedByte();
	trace("Packet length: "+pL);
	if (pL>20) {
		trace("Some weird data...process Error Message");
		onErrorMessage(byteArr);
		return;
	}
	trace("Packet flags: "+byteArr.readUnsignedByte());
	var res:uint=byteArr.readUnsignedByte();
	switch (res){
		case 0x00: trace("Socket connected"); startClient(); break;
		case 0x01: trace("Connection Refused: unacceptable protocol version"); break;
		case 0x02: trace("Connection Refused: identifier rejected"); break;
		case 0x03: trace("Connection Refused: server unavailable"); break;
		case 0x04: trace("Connection Refused: bad user name or password"); break;
		case 0x05: trace("Connection Refused: not authorized"); break;
		default: trace("Reserved for future use"); break;
	}
}//The CONNACK message is the message sent by the server in response to a CONNECT request from a client.

function startClient():void{
	connectTimeOut.stop();
	connectTimeOut.removeEventListener(TimerEvent.TIMER, noConnection);
	keep_alive_timer.addEventListener(TimerEvent.TIMER, checkPing);
	keep_alive_timer.start(); stayOnline=true;
	servicing=true; mc_connecting.gotoAndStop(15);
	connect_mc.gotoAndStop(2);
	//set_btn.visible=true;
	//rem_btn.visible=false;
	if (vplc) {
		trace("sourceArr="+sourceArr);
		trace("Subscribing to VLPC tags, sets update and all of the sources"); 
		trySubscribe("MASC/tags/update");
		trySubscribe("MASC/sets/update");
		for each (var srs in sourceArr)	{ //На будущее можно продумать соединение по требованию. Возникла необходимость - отправили запрос и подключились.
			trace(srs[3].toString());
			trySubscribe(srs[3].toString());
		}
		if (cycleTrigger=="ENTER_FRAME") stage.addEventListener(Event.ENTER_FRAME, updateData);
		sendVPLC();
		return;
	}
	trace("Starting a regular Client")
	var tArr:Array=[];
	for each (var obj in activeObj){
		if (obj is KlapanA){ trace("Get connection for KlapanA"); tArr.push("MASC/tags/PLC/DA/"+obj.num);}
		if (obj is FizAI) {trace("GetSource by AI number"); tArr.push("MASC/tags/PLC/AI/"+obj.num);}
		if (obj is TextData) {trace("GetSource for TextData"); tArr.push(obj.src);}
		trace(tArr.length-1);
	}
	if (tArr.length>0) trySubscribeArr(tArr);
	//stage.addEventListener(Event.ENTER_FRAME, updateData);
} //startClient() - запустить таймер keepAlive для PingREQ, установить servicing в true.

function checkPing(e:TimerEvent):void{
	//trace("Sending PingREQ");
	ping_mc.gotoAndStop(2);
	mqttSocket.writeByte(PINGREQ); // - protocol type
	mqttSocket.writeByte(0);// remainig length
	mqttSocket.flush();
}
function onPingresp():void{
	//trace("PING response");
	ping_mc.gotoAndPlay(3);
}// Ping check

function isClosed(e:Event=null):void{
	trace("Connection to server closed");
	stage.removeEventListener(Event.ENTER_FRAME, updateData);
	servicing=false; mc_connecting.gotoAndStop(1);
	try {
		mqttSocket.removeEventListener(Event.CONNECT, isConnected);
		mqttSocket.removeEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
		mqttSocket.removeEventListener(Event.CLOSE, isClosed);
		keep_alive_timer.removeEventListener(TimerEvent.TIMER, checkPing);
		keep_alive_timer.stop();
		keep_alive_timer.reset();
	} catch (Error:*) {}
	connect_mc.gotoAndStop(1);
	
	if (stayOnline==true) tryConnect();
}
function tryDisconnect(reconnect:Boolean=false):void{
	for each (var topic:String in topicArr) tryUnSubscribe(topic);
	while (topicArr.length>0) topicArr.pop();
	trace("Disconnecting from server..."); stayOnline=false;
	if (servicing) {
		bytes=new ByteArray();
		mqttSocket.writeByte(DISCONNECT); // - protocol type
		mqttSocket.writeByte(0);// remainig length
		mqttSocket.flush();
		mc_connecting.gotoAndStop(1);
	}
	keep_alive_timer.removeEventListener(TimerEvent.TIMER, checkPing);
	keep_alive_timer.stop();
	keep_alive_timer.reset();
	servicing=false;
	if (mqttSocket.connected){
		mqttSocket.removeEventListener(Event.CONNECT, isConnected);
		mqttSocket.removeEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
		mqttSocket.removeEventListener(Event.CLOSE, isClosed);
		mqttSocket.close();
	}
	trace("Disconnected");
	if (cycleTrigger=="ENTER_FRAME") stage.removeEventListener(Event.ENTER_FRAME, updateData);
	connect_mc.gotoAndStop(1);
	if (reconnect) tryConnect();
}//tryDisconnect() and isClosed - when server closed the connection

function trySubscribe(topic:String=""):void{   //trySubscribe(child:MovieClip,topic:String)
	if (!servicing) return;
	if (topic=="") return;
	if (waitForSub==false) topicArr.push(topic);
	trace("Subtopic= "+topic);
	bytes=new ByteArray();
	//---------------------Packet ID combines with child that needs the responce message------------------------// 
	var packID:Number=Math.floor(Math.random()*65535);
	if (waitForSub) listSubID=packID;
	//child.packID = packID; //Assign the ID if subscription to the child
	/*var msb:Number=packID >> 8; var lsb:Number=packID % 256;
	bytes.writeByte(packID >> 8); bytes.writeByte(packID % 256); //write Packet ID*/
	bytes.writeShort(packID);
	if (topic.length>0) writeString(topic)//Write topic
	bytes.writeByte(0x0)//Write topic QoS - No QoS for now
	mqttSocket.writeByte(SUBSCRIBE+0x2); //10 - protocol type (0x80+2)
	mqttSocket.writeByte(bytes.length);// remainig length
	mqttSocket.writeBytes(bytes, 0, bytes.length);
	mqttSocket.flush();
	//trace("Subscribe message: <"+topic+"> send packID = "+packID);
}//trySubscribe()
function trySubscribeArr(topics:Array):void{   //trySubscribe(child:MovieClip,topic:String)
	for each (var topic:String in topics) trySubscribe(topic);
	return;
	//trace("Subscribing for multiple topics "+topics)
	bytes=new ByteArray();
	//---------------------Packet ID combines with child that needs the responce message------------------------// 
	var packID:Number=Math.floor(Math.random()*65535);
	//child.packID = packID; //Assign the ID if subscription to the child
	/*var msb:Number=packID >> 8; var lsb:Number=packID % 256;
	bytes.writeByte(packID >> 8); bytes.writeByte(packID % 256); //write Packet ID*/
	bytes.writeShort(packID);
	for each (var topik:String in topics) {
		if (topik.length>0) {
			writeString(topik)//Write topic
			bytes.writeByte(0x0)//Write topic QoS - No QoS for now
		}
	}
	
	mqttSocket.writeByte(SUBSCRIBE+0x2); //10 - protocol type (0x80+2)
	mqttSocket.writeByte(bytes.length);// remainig length
	mqttSocket.writeBytes(bytes, 0, bytes.length);
	mqttSocket.flush();
	//trace("Subscribe message send packID = "+packID);
}//trySubscribeArr()
function onSuback(byteArr:ByteArray):void{
	//trace("Subscription acknowledgement"); 
	//trace("Suback length: "+byteArr.readUnsignedByte());
	//Next data is for packetidentifyer
	var packID:int=byteArr.readUnsignedShort();
	//trace("Packet Identifier = "+packID); //trace("Packet Identifier MSB: "+mqttSocket.readUnsignedByte()); trace("Packet Identifier LSB: "+mqttSocket.readUnsignedByte());
	var retCode:int=byteArr.readUnsignedByte();
	switch (retCode){
		case 0: trace("Subscription is succesfull. QoS = 0"); break;
		case 1: trace("Subscription is succesfull. QoS = 1"); break;
		case 2: trace("Subscription is succesfull. QoS = 2"); break;
		case 128: trace("Subscription failed."); break;
	}
	if (waitForSub){
		if (retCode<=3 && listSubID==packID) {waitForTop=true; waitForSub=false;}
	}
}//onSuback() - subscribe responce
function tryUnSubscribe(topic:String=""):void{   //trySubscribe(child:MovieClip,topic:String)
	if (servicing==false) return;
	bytes=new ByteArray();
	//---------------------Packet ID combines with child that needs the responce message------------------------// 
	var packID:Number=Math.floor(Math.random()*65535);
	//child.packID = packID; //Assign the ID if subscription to the child
	bytes.writeShort(packID);
	if (topic.length>0) writeString(topic) else return;//Write topic
	mqttSocket.writeByte(UNSUBSCRIBE+0x2); // - protocol type (0xA0+2)
	mqttSocket.writeByte(bytes.length);// remainig length
	mqttSocket.writeBytes(bytes, 0, bytes.length);
	mqttSocket.flush();
	trace("Unsubscribe message send packID = "+packID);
}//tryUnSubscribe()
function onUnsuback(byteArr:ByteArray):void{
	trace("Unsubscribe acknowledgement");
	trace("Unsuback length: "+byteArr.readUnsignedByte());
	trace("Packet Identifier = "+byteArr.readUnsignedShort()); //read 2 bytes of data
	trace("Unsubscription is succesfull");
}//onUnsuback() - unsubscribe responce

function tryPublish(b:Boolean, arr:Array):void{
	if (!servicing) return;
	trace("tryPublish");
	bytes=new ByteArray();
	if (arr.length>0) {
		//trace("Sending data VIA button."+arr[0]+":"+arr[1]);
		var sourcePath:String=arr[0];
		sourcePath=sourcePath.substring(0,sourcePath.length-1);
		writeString(sourcePath);
		send_txt.text='{'+String.fromCharCode(13)+'"d" : {'+String.fromCharCode(13)+'"'+arr[1]+'":['+arr[2]+'],"value1":[210]'+String.fromCharCode(13)+'},'+String.fromCharCode(13)+'"ts" : "2018-01-18T20:50:48.365091"'+String.fromCharCode(13)+'}';
		trace(send_txt.text);
		
		/*send_txt.text=st;
		writeString(send_txt.text,false);*/
		//writeString(st);
		writeString(send_txt.text,false);
	} else {
		trace("Some error while publishing. Send array.length=0.");
		return;
	}
	mqttSocket.writeByte(PUBLISH); //10 - protocol type (0x30)
	mqttSocket.writeByte(bytes.length);//10 - remainig length
	mqttSocket.writeBytes(bytes, 0, bytes.length);
	mqttSocket.flush();
	trace("Publish message send");
}//tryPublish()

//---------------------NEW FUNCTION TO SEND OVER JSON--------------------------------//
function publishObj(sets:Boolean, obj:Object, ret:int=1,topicForm:String=""):void{
	if (!servicing) return;
	bytes=new ByteArray();
	var st:String="MASC/tags/";
	if (sets) st="MASC/sets/";
	if (topicForm=="none") {
		writeString(obj.topic);
		trace("Sending data to: "+obj.topic+". Message="+JSON.stringify(obj));
	} else {
		writeString(st+obj.topic);
		trace("Sending data to: "+st+obj.topic+". Message="+JSON.stringify(obj));
	}
	delete obj["topic"];
	//obj.ts=getTimeStamp();
	//myPubs.push(obj.ts);
	tx.text=JSON.stringify(obj);
	//var pObj:Object=new Object(); for each(var prop in obj){pObj[prop]=obj.prop}; tx.text=JSON.stringify(pObj);
	writeString(tx.text,false);
	if (retrain_chb.selected && ret) {
		mqttSocket.writeByte(PUBLISH+1); //10 - protocol type (0x30)
	} else {
		mqttSocket.writeByte(PUBLISH); //10 - protocol type (0x30)
	}
	//В этом моменте нужно пересмотреть варинат отправки общей длины.. Если сообщение больше 127 символов, то нужно задействовать ещё биты для уточнения всей длины сообщения...
	mqttSocket.writeByte(bytes.length);//10 - remainig length
	mqttSocket.writeBytes(bytes, 0, bytes.length);
	mqttSocket.flush();
}
function getTimeStamp():String{
	"2018-12-15T23:35:30.712534"
	var dat:Date=new Date();
	return (dat.fullYear+"-"+(dat.month+1)+"-"+dat.date+"T"+dat.hours+":"+dat.minutes+":"+dat.seconds);
}
function publishData(topic:String, message:String):void{
	if (!servicing) return;
	bytes=new ByteArray(); trace(topic+":  "+message);
	writeString(topic);
	var st:String="";
	var obj:Object=JSON.parse(message); var pObj:Object=new Object(); for (var prop in obj){pObj[prop]=obj.prop};  tx.text=JSON.stringify(pObj); writeString(tx.text,false);
	//tx.text=message; writeString(tx.text);
	//writeString(message);
	mqttSocket.writeByte(PUBLISH); //10 - protocol type (0x30)
	mqttSocket.writeByte(bytes.length);//10 - remainig length
	mqttSocket.writeBytes(bytes, 0, bytes.length);
	mqttSocket.flush();
}
function updateProp(sets:Boolean,values:String):void{
	if (!servicing) return;
	trace("updating Data");
	bytes=new ByteArray();
	var st:String="MASC/tags/update";
	if (sets) st="MASC/sets/update";
	writeString(st);
	var obj:Object=JSON.parse(values); var pObj:Object=new Object(); for each(var prop in obj){pObj[prop]=obj.prop}; st=JSON.stringify(pObj); writeString(st);
	mqttSocket.writeByte(PUBLISH); //10 - protocol type (0x30)
	mqttSocket.writeByte(bytes.length);//10 - remainig length
	mqttSocket.writeBytes(bytes, 0, bytes.length);
	mqttSocket.flush();
	trace("Publish message send");
}
function publishChanges(tree:String, node:XML):void{
	trace("Sending data regardless of the project. Adding data "+node.toXMLString()+" to "+tree);
	var obj:Object=new Object(); var pr:String="";
	var attributes:XMLList = node.attributes();
	for each (var prop:Object in attributes) {
        trace(prop.name() + " = " + prop); pr=prop.name(); var data:Object=prop;
		obj[pr]=prop.toString();
    }
	
	trace("------------------------------");
	
	//for (var ppp in obj){trace("Object propoerty "+ppp+"="+obj[ppp]);}
	
	//obj.topic="project" 
	obj.action="add";
	obj.tree=tree;
	
	if (!servicing) return;
	bytes=new ByteArray();
	writeString("MASC/sets/project");
	
	//tx.text=node.toXMLString();//JSON.stringify(obj);
	tx.text=JSON.stringify(obj);
	trace(tx.text);
	writeString(tx.text,false);
	if (retrain_chb.selected) {
		mqttSocket.writeByte(PUBLISH+1); //10 - protocol type (0x30)
	} else {
		mqttSocket.writeByte(PUBLISH); //10 - protocol type (0x30)
	}
	var packetLen:uint=bytes.length; trace(packetLen.toString(2));
	if (packetLen>127){
		var st:String=packetLen.toString(2);
		trace("Packet lenght is greater than 127!!! = "+st);
		var tSt:String="";
		trace(st.substring(st.length-7,st.length),st.substring(0,st.length-7));
		
		mqttSocket.writeByte(parseInt("1"+st.substring(st.length-7,st.length)));
		mqttSocket.writeByte(parseInt(st.substring(0,st.length-7)));
		
		//while (st.length>7){tSt=st.substring(st.length-7,st.length); st=st.substring(0,st.length-7); trace(st,tSt);packetLen=parseInt("1"+tSt);mqttSocket.writeByte(packetLen);}
		//var arr:Array=packetLen.toString(2).split("");
		//arr.splice(7,0,1);
		//while (arr.length<16) arr.unshift(0);
		//var tArr:Array=[arr[0],arr[1],arr[2],arr[3]arr[4]arr[5]arr[6]arr[7]];
		//packetLen=parseInt(st); mqttSocket.writeByte(packetLen);//10 - remainig length
		//if (arr.length > 16) {arr.splice(7,0,1);}
	} else {
		trace("Packet lenght is under 128");
		mqttSocket.writeByte(packetLen);//10 - remainig length
	}
	mqttSocket.writeBytes(bytes, 0, bytes.length);
	mqttSocket.flush();
}

			
//----------------------------------------------------------------------------------//
function doLength(tL:int):int {
	//trace("Income length bits = "+tL.toString(2));
	var arr:Array=tL.toString(2).split("");
	while (arr.length<16) arr.unshift(0);
	arr.splice(8,1);
	var newNumber=arr.join("");
	//trace("Made length bits = "+newNumber);
	return parseInt(newNumber,2);
}
function getLen(socket:*):uint{
	var getLen:Boolean=true;
	var pL:uint; var tmpArr,lenArr:Array=[];
	while(getLen){
		pL=socket.readUnsignedByte();
		//trace("Incoming message data length="+pL,pL.toString(2));
		tmpArr=pL.toString(2).split("");
		while (tmpArr.length<8) tmpArr.unshift(0);
		//trace(tmpArr);
		lenArr.unshift(tmpArr[1],tmpArr[2],tmpArr[3],tmpArr[4],tmpArr[5],tmpArr[6],tmpArr[7])
		if (tmpArr[0]==0){getLen=false;}
	}
	pL=parseInt(lenArr.join(""),2);
	return pL;
}
/*function getByteArrLen(socket:ByteArray):uint{
	var getLen:Boolean=true;
	var pL:uint; var tmpArr,lenArr:Array=[];
	while(getLen){
		pL=socket.readUnsignedByte();
		//trace("Incoming message data length="+pL,pL.toString(2));
		tmpArr=pL.toString(2).split("");
		while (tmpArr.length<8) tmpArr.unshift(0);
		//trace(tmpArr);
		lenArr.unshift(tmpArr[1],tmpArr[2],tmpArr[3],tmpArr[4],tmpArr[5],tmpArr[6],tmpArr[7])
		if (tmpArr[0]==0){getLen=false;}
	}
	pL=parseInt(lenArr.join(""),2);
	return pL;
}*/
function writeString(str:String,setLength:Boolean=true):void{
	if (setLength) {
		var len:int=str.length;
		var msb:int=len >> 8;
		var lsb:int=len % 256;
		bytes.writeByte(msb);
		bytes.writeByte(lsb);
	}
	bytes.writeUTFBytes(str);
	//bytes.writeMultiByte(str, 'utf-8');
}//writeString(byteArr, String):void

function checkSubscription(topic:String, trying:int=0):int{
	if (topicArr.indexOf(topic)==-1) {trySubscribe(topic); return 0;}
	if ((topicArr.indexOf(topic)>0) && trying>500) {
		//trySubscribe(topic); //Это на случай, когда данные не приходят в течении определённого времени осуществялется повторный запрос на данные
		return 0;
	} else {
		return trying+1;
	}
	return 0;
}