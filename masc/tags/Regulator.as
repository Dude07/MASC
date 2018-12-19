/*
MASC 2018. Regulator
топик для публикации данных выглядит так:	MASC/tags/PLC/REG/num	{"A":###,"OUT":###,"OUT_off":#,"OPEN":###,"CLOSE":###,"errConfig":#,"errOUT_IN":#,"errOUT_R":#,"name":@}
					 настроек сигнала:		MASC/sets/PLC/REG/num	{"typeDA":###,"num":###,"R_active":#####,"R_num":#####[5],"IN":##,"OUT_min":##,"OUT_max":##,"srcIN":@,"srcOUT":@,"srcOPEN":@,"srcCLOSE":@,"eu":@}

reg:Regulator
  {
		<reg id="0" num="0" active="1" src_SP="table" multyp="1" multyp_in="MASC/tags/PLC/0/AI/3:fiz" table="0" table_in="MASC/tags/PLC/0/AI/3:fiz">
		
		num:int 			Номер регулятора (для порядка отображения)
		active:int 			1-Автомат/ 0-Ручное
		
		name:String			Имя регулятора (по желанию)
		src_SP:String		Источник задания сигнала (0 none, 1 table, 2 multyp). None - задание с ввода (от сигнала), table - задание с таблицы, тогда ещё нужны значения table="номер таблицы" table_in="топик - значение на вход", и multip - множитель multyp="значение множителя" multyp_in="топик - значение на вход"
		
		multyp:Number		Множитель для вычисленного значения задания
		src_multyp:String	Строка с топиком со значением 
		tag_multyp:String	Строка с названием перемнной содержащей значение
		table:int			Номер таблицы используемой для вычисления задания
		src_table:String	Строка с топиком со значением
		tag_table:String	Строка с названием перемнной содержащей значение
		
		cors:Vector			Массив (вектор) коррекций данного регулятора (<Correction>)
	  
		function Regulator    Функция которая выполняется при инициализации.
		function drop()		Функция сброса сигнала и его значений
  }
*/

package masc.tags {
	import masc.tags.Correction;
	public class Regulator{
		//public var reg:Vector.<Regulator>  //Создать классы
		public var cors:Vector.<Correction> //Создать
		public var multyp:Number;
		public var active,num,type,table:int;
		public var src_SP,name:String; 
		public var src_multyp,tag_multyp,src_table,tag_table:String;
		
		public function Regulator() {
			trace("New REG created")// constructor code
			drop();
		}
		public function drop():void{
			cors=new Vector.<Correction>();
			src_SP=""; num=-1; active=0;
			multyp=0;
			name="Регулятор";
		}
		
		public function addProp(nam:String,val:*):void{
			switch (nam){
				case "type": type=int(val); break;
				case "active": active=int(val); break;
				case "num": num=int(val); break;
				case "src_SP": src_SP=val; break;
				case "mutlyp":  multyp=Number(val); break;
				case "table": table=int(val); break;
				case "table_in": getSrcT(val.toString());break;
				case "multyp_in": getSrcM(val.toString());break;
			}
		}
		private function getSrcT(st:String):void{
			var arr:Array=st.split(":");
			src_table=arr[0];
			if (arr.length>1) {
				tag_table=arr[arr.length-1];
			} else {
				tag_table="RAW";
			}
		}
		private function getSrcM(st:String):void{
			var arr:Array=st.split(":");
			src_multyp=arr[0];
			if (arr.length>1) {
				tag_multyp=arr[arr.length-1];
			} else {
				tag_multyp="RAW";
			}
		}
	}
}
