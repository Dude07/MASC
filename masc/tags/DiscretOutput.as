/*
MASC 2018. DiscretOutput
топик для публикации данных выглядит так:	MASC/tags/PLC/DQ/num	{"fiz":###}
					 настроек сигнала:		MASC/sets/PLC/DQ/num	{"name":@}

dq:DiscretOutput
  {
	  fiz:int				Фактичесоке (публикуемое) значение сигнала
	  fizOld:int			Для хранения прежнего значения(может потребоваться)
	  cod:int				Для записи фактического значения от модуля
	  
	  num:int				Номер аналогово входа в системе
	  err:int				Для хранения ошибок по сигналу
	  filtr:int				Указанное фильтрация сигнала (время осле кторого значение можно считать принятым) //Пока не реализуем
	  noSub:int				Накопительная для счётчика отсутствия значения от брокера. При обращении к mainData если в течении 500 повторов нет данных, выводится сообщение в ошибку и повторный запрос на подписку отправляется принудительно
	  type:int				Тип сигнала 0 - прямой	1 - обратный
	  name:String			Строковая переменная для хранения имени сигнала
	  src:String			Строковая переменная для хранения "топика" (источника) сигнала
	  tag:String			Строковая переменная с именем тега в сообщении топика
	  dst:String			Переменная с топиком куда писать значение
	  teg:String			Имя переменной для записи в dst
	  
	  args:Array String		Список значений к архивированию (заполняется в случае изменения значения)
	  vals:Array String		Значения к архивированию (заполняется в случае изменения значения)
	  
	  pub:Boolean			Флаг, который ставим при смене значения для публикации и архивирования.
	  
	  function DiscretOutput 		Функция которая выполняется при инициализации сигнала.
	  function dropDQ()				Функция сброса сигнала и его значений
	  function dropErr()			Функция сброса ошибок сигнала
	  function addProp(String,*)	Функция вносит значение по имени в элемент структуры
	  function getSrc(String)		Закрытая функция разбирает строку на составляющие src и tag
	  function getDst(String)		Закрытая функция разбирает строку на составляющие dst и teg
	  function getProp(String):*	Функция возвращает значение по имени элемента структуры
  }
*/

package masc.tags {
	
	public class DiscretOutput {
		public var fiz,fizOld,cod,num,err,filtr,noSub:int;
		public var type:int;
		public var src,dst,tag,teg,name:String="Дискретный выход"
		public var pub:Boolean=false;
		public var args,vals:Array;
		public var regs:Array;
		
		public function DiscretOutput() {
			trace("New DQ created")// constructor code
			dropDQ();
		}
		public function dropDQ():void{
			fiz=fizOld=noSub=err=filtr=0;
			args=vals=[];
			src=tag=dst=teg="";
		}
		public function dropErr():void{
			err=0;
		}
		public function addProp(nam:String,val:*):void{
			switch (nam){
				case "fiz": fiz=int(Number(val)>0); break;
				case "type": type=int(val); break;
				case "num": num=int(val); break;
				case "src": getSrc(val.toString()); break;
				case "dst": getDst(val.toString()); break;
				case "filtr": filtr=int(val); break;
				default: trace("Свойство DQ."+nam+" не назначено. Нет в перечне функции addProp");  break;
			}
		}
		private function getSrc(st:String):void{
			var arr:Array=st.split(":");
			src=arr[0];
			if (arr.length>1) {
				tag=arr[arr.length-1];
			} else {
				tag="RAW";
			}
		}
		private function getDst(st:String):void{
			var arr:Array=st.split(":");
			dst=arr[0];
			if (arr.length>1) {
				teg=arr[arr.length-1];
			} else {
				teg="RAW";
			}
		}
		public function getProp(nam:String):*{
			switch (nam){
				case "fiz": return fiz; break;
				case "type": return type; break;
				case "num": return num; break;
				case "src": return src; break;
				case "dst": return dst; break;
				case "filtr": return filtr; break;
				default: trace("Свойство DQ."+nam+" не возвращено. Нет в перечне функции getProp"); return null; break;
			}
			return null;
		}
	}
}
