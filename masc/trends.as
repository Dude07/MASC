import flash.data.SQLConnection;
import flash.events.SQLErrorEvent;
import flash.events.SQLEvent;
import flash.filesystem.File;
import flash.errors.SQLError;
import flash.data.SQLStatement;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.utils.Timer;
import flash.events.TimerEvent;
import flash.data.SQLResult;

var conn:SQLConnection;
var folder:File;
var dbFile:File;
var newBD:Boolean=false;
var dbLoc:String="";
var dbName:String="";
var connBusy:Boolean=true;
var connArr:Array=[];
var dat:Date=new Date();
var trendAI:Array=[];

function setUpDB(loc:String=""):void{
	if (loc == "asProject") {
		trace("Located in project folder");
		loc=projectFile.nativePath;
		loc=loc.substring(0,loc.length-(projectFile.extension.length))+"bd";
	}
	dbFile= new File(loc); conn=new SQLConnection();
	if (dbFile.extension=="") dbFile.resolvePath(".bd");
	trace("SettingUp data base at position of "+loc+". БД существует = "+dbFile.exists); newBD=!Boolean(dbFile.exists); 
	connectDB2();
	return; //Это старый вариант разбора положения БД. Сейчас делаю это сразу одной строкой без раскидывания на кусочки...
	var arr:Array=loc.split("/");
	var nam:String=arr[arr.length-1].split(".")[0]; trace("DB name = "+nam);
	arr.pop();
	loc=arr.join("/"); trace(loc);
	dbLoc=loc; dbName=nam;
	connectDB();
}
function connectDB2():void{
	trace("---------------Connection to database--------------"); 
	conn.addEventListener(SQLErrorEvent.ERROR, errorSQL); conn.addEventListener(SQLEvent.OPEN, openSQL);
	conn.openAsync(dbFile);
	bd_txt.text=dbFile.nativePath;
}
function connectDB():void{
	if (dbLoc=="" || dbName=="") return;
	trace("---------------Connection to database--------------"); 
	conn.addEventListener(SQLErrorEvent.ERROR, errorSQL); conn.addEventListener(SQLEvent.OPEN, openSQL);
	folder = new File(dbLoc);
	dbFile = folder.resolvePath(dbName+".db");
	newBD=Boolean(dbFile.exists);
	conn.openAsync(dbFile);
}
function openSQL(e:SQLEvent):void{
	conn.removeEventListener(SQLEvent.OPEN, openSQL);
	if (newBD) trace("A new SQL database created and connected!") else trace("SQL database found, opened and connected!");
	checkCreateTable("CREATE TABLE IF NOT EXISTS ai(id INTEGER PRIMARY KEY AUTOINCREMENT, time TIME, num INTEGER, args STRING, vals STRING)");
	connBusy=false;
}
function checkCreateTable(str:String):void{
	var createStm:SQLStatement=new SQLStatement();
	createStm.text=str;
	createStm.sqlConnection=conn;
	function someError(e:SQLErrorEvent):void{
		trace("Some error "+e.error.message+e.error.details);
		createStm.removeEventListener(SQLEvent.RESULT, gotResult);
		createStm.removeEventListener(SQLErrorEvent.ERROR, someError);
		if (conn.inTransaction) {
			conn.addEventListener(SQLEvent.ROLLBACK, rollBack);
			conn.rollback();
		}
	}
	function rollBack(e:SQLEvent):void{
		conn.removeEventListener(SQLEvent.ROLLBACK, rollBack);
		trace("Rolled back after some error.....");
	}
	function gotResult(e:SQLEvent):void{
		trace("The database is initialized!");
		createStm.removeEventListener(SQLEvent.RESULT, gotResult);
		createStm.removeEventListener(SQLErrorEvent.ERROR, someError);
		if (conn.inTransaction) {conn.commit(); conn.addEventListener(SQLEvent.COMMIT, commitConn);}
	}
	function commitConn(e:SQLEvent):void{
		conn.removeEventListener(SQLEvent.COMMIT, commitConn);
	}
	
	createStm.addEventListener(SQLEvent.RESULT, gotResult);
	createStm.addEventListener(SQLErrorEvent.ERROR, someError);
	createStm.execute();
}
function errorSQL(e:SQLErrorEvent):void{
	trace("Some SQL connection error (");
	conn.removeEventListener(SQLErrorEvent.ERROR, errorSQL);
	conn.removeEventListener(SQLEvent.OPEN, openSQL)
}

function insertIntoDB(type:String,num:int,args:Array,vals:Array):void{
	trace("Data base connected = "+conn.connected+". Data base busy = "+connBusy);
	if (conn.connected==false) {connectDB(); return;}
	connArr.push([type,num,args,vals]);
	trace("connArr.length="+connArr.length);
	if (sendTm.running==false) {sendTm.start();}
}
var sendTm:Timer=new Timer(5);
sendTm.addEventListener(TimerEvent.TIMER,operateDB);

//stage.addEventListener(Event.ENTER_FRAME, operateDB);
function operateDB(e:TimerEvent):void{
	if (connBusy) return;
	if (connArr.length==0) {sendTm.stop(); return;}
	var ind:int=connArr.length-1; connBusy=true;
	processInsert(connArr[ind][0],connArr[ind][1],connArr[ind][2],connArr[ind][3]);
}
function processInsert(type:String,num:int,args:Array,vals:Array):void{
	conn.addEventListener(SQLEvent.BEGIN, beginSQL);
	conn.begin();
	var insertData:SQLStatement = new SQLStatement(); var i:int; var pnam:String="";
	function beginSQL(e:SQLEvent):void{
		conn.removeEventListener(SQLEvent.BEGIN, beginSQL);
		insertData.sqlConnection=conn;
		switch (type){
			case "ai": 
				insertData.text = "INSERT INTO ai (time, num, args, vals) VALUES (:time, :num, :args, :vals)"; trace(insertData.text);
				insertData.parameters[":num"]=num;
				insertData.parameters[":time"]=(new Date().time);
				insertData.parameters[":args"]=args.join(";");
				insertData.parameters[":vals"]=vals.join(";");
			break;
		}
		trace(insertData.text.length);
		if (insertData.text.length==0) {
			trace("No content in sql. Aborting work"); conn.commit(); return;
		}
		insertData.addEventListener(SQLEvent.RESULT, gotResult);
		insertData.addEventListener(SQLErrorEvent.ERROR, someError);
		insertData.execute();
	}
	function someError(e:SQLErrorEvent):void{
		trace("Some error "+e.error.message+e.error.details);
		insertData.removeEventListener(SQLEvent.RESULT, gotResult);
		insertData.removeEventListener(SQLErrorEvent.ERROR, someError);
		if (conn.inTransaction) {
			conn.addEventListener(SQLEvent.ROLLBACK, rollBack);
			conn.rollback(); return;
		}
		connBusy=false; 
	}
	function rollBack(e:SQLEvent):void{
		conn.removeEventListener(SQLEvent.ROLLBACK, rollBack);
		trace("Rolled back after some error.....");
		connBusy=false; 
	}
	function gotResult(e:SQLEvent):void{
		trace("data send");
		insertData.removeEventListener(SQLEvent.RESULT, gotResult);
		insertData.removeEventListener(SQLErrorEvent.ERROR, someError);
		conn.addEventListener(SQLEvent.COMMIT, commitConn);
		conn.commit();
	}
	function commitConn(e:SQLEvent):void{
		conn.removeEventListener(SQLEvent.COMMIT, commitConn);
		connBusy=false; connArr.pop();
		trace(connArr.length);
	}
}

function showTrends(per:Number=360000):void{
	if (dbFile.exists==false) return;
	trace("Opening trend data");
	conn.addEventListener(SQLEvent.BEGIN, beginSQL);
	conn.begin();
	var getData:SQLStatement = new SQLStatement(); var i:int; var pnam:String="";
	function beginSQL(e:SQLEvent):void{
		conn.removeEventListener(SQLEvent.BEGIN, beginSQL);
		getData.sqlConnection=conn;
		var now:Number=new Date().time;
		var prev:Number=now-per;
		getData.text = "SELECT * FROM ai ";// getData.text = "SELECT * FROM * WHERE time>"+prev+" AND time<"+now; trace(getData.text);
		trace(getData.text.length);
		if (getData.text.length==0) {
			trace("No content in sql. Aborting work"); conn.commit(); return;
		}
		getData.addEventListener(SQLEvent.RESULT, gotResult);
		getData.addEventListener(SQLErrorEvent.ERROR, someError);
		getData.execute();
	}
	function someError(e:SQLErrorEvent):void{
		trace("Some error "+e.error.message+e.error.details);
		getData.removeEventListener(SQLEvent.RESULT, gotResult);
		getData.removeEventListener(SQLErrorEvent.ERROR, someError);
		if (conn.inTransaction) {
			conn.addEventListener(SQLEvent.ROLLBACK, rollBack);
			conn.rollback(); return;
		}
		connBusy=false; 
	}
	function rollBack(e:SQLEvent):void{
		conn.removeEventListener(SQLEvent.ROLLBACK, rollBack);
		trace("Rolled back after some error.....");
		connBusy=false; 
	}
	function gotResult(e:SQLEvent):void{
		trace("------------------Got Data Results---------------------");
		getData.removeEventListener(SQLEvent.RESULT, gotResult);
		getData.removeEventListener(SQLErrorEvent.ERROR, someError);
		var result:SQLResult = getData.getResult();
		var arr:Array=result.data;
		var numResults:int = arr.length;
		trace("numResults="+numResults);
		if (result != null) {
			for (var i:int = 0; i < numResults; i++){
				trace(result.data[i]);
				var row:Object = result.data[i];
				for (var par in row){
					trace(par+":"+row[par]);
				}
			}
			showTrendWin();
		}
		conn.addEventListener(SQLEvent.COMMIT, commitConn);
		conn.commit();
	}
	function commitConn(e:SQLEvent):void{
		conn.removeEventListener(SQLEvent.COMMIT, commitConn);
		connBusy=false; connArr.pop();
		trace(connArr.length);
	}
}

function showTrendWin():void{
	
}