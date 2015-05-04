package 
{
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	import fl.events.SliderEvent;
	import fl.controls.Slider;

	// The  manager  serves as a document class
	// for our this world

	public class Manager extends MovieClip
	{
		private var _fogArray:Array;
		private var _pirateArray:Array;
		private var _navyArray:Array;
		private var _cargoArray:Array;
		private var _blockArray:Array;
		private var _dockArray:Array;
		private var _lastTime:Number;
		private var _curTime:Number;
		private var _dt:Number;
		private var _howMany:Number = 36;

		private var _path:Array;
		private var segmentIn:Segment;
		private var segmentOut:Segment;

		private var buoyIn:Shape;
		private var buoyOut:Shape;

		public function get fogArray( ):Array
		{
			return _fogArray;
		}
		public function get pirateArray( ):Array
		{
			return _pirateArray;
		}
		public function get navyArray( ):Array
		{
			return _navyArray;
		}
		public function get cargoArray( ):Array
		{
			return _cargoArray;
		}
		public function get blockArray( ):Array
		{
			return _blockArray;
		}
		public function get dockArray( ):Array
		{
			return _dockArray;
		}
		public function get path( ):Array
		{
			return _path;
		}
		public function get time( ):Number
		{
			return _dt;
		}

		public function Manager( )
		{
			_fogArray = new Array();
			_pirateArray = new Array();
			_navyArray = new Array();
			_cargoArray = new Array();
			_blockArray = new Array();
			_dockArray = new Array();
			this.buildWorld( );
			//event listener for to drive frame loop
			addEventListener(Event.ENTER_FRAME, frameLoop);
			/*tether.addEventListener(Event.CHANGE, updateTether);
			wander.addEventListener(Event.CHANGE, updateWander);
			align.addEventListener(Event.CHANGE, updateAlign);
			cohesion.addEventListener(Event.CHANGE, updateCohesion);
			separation.addEventListener(Event.CHANGE, updateSeparation);
			collision.addEventListener(Event.CHANGE, updateCollision);*/
		}

		/*private function updateTether(e:SliderEvent)
		{
		Flocker.tetherWeight = e.target.value;
		}
		private function updateWander(e:SliderEvent)
		{
		Flocker.wanderWeight = e.target.value;
		}
		private function updateAlign(e:SliderEvent)
		{
		Flocker.alignWeight = e.target.value;
		}
		private function updateCohesion(e:SliderEvent)
		{
		Flocker.cohesionWeight = e.target.value;
		}
		private function updateSeparation(e:SliderEvent)
		{
		Flocker.separationWeight = e.target.value;
		}
		private function updateCollision(e:SliderEvent)
		{
		Flocker.collideWeight = e.target.value;
		}*/

		private function buildWorld( ):void
		{
			_lastTime = getTimer();

			var block:Block;
			for (var j:int = 0; j < 10; j++)
			{
				block = new Block(this,(Math.random() * (stage.stageWidth-100))+50,(Math.random() * (stage.stageHeight/2)+50),30);
				addChild(block);
				_blockArray.push(block);
			}

			var dock:Dock;
			for (var k:int = 0; k < 10; k++)
			{
				dock = new Dock(((stage.stageWidth/20)*k)+(stage.stageWidth/4), stage.stageHeight-10);
				addChild(dock);
				_dockArray.push(dock);
			}

			graphics.lineStyle(20, 0xEDC9AF, 1);
			graphics.moveTo(0,(stage.stageHeight/4)*3);
			graphics.moveTo((stage.stageWidth/2)-35, (stage.stageHeight/4)*3);
			graphics.curveTo(0,(stage.stageHeight/4)*3, 50, stage.stageHeight);
			graphics.moveTo((stage.stageWidth/2)+35, (stage.stageHeight/4)*3);
			graphics.curveTo((stage.stageWidth/4)*3, (stage.stageHeight/4)*3, stage.stageWidth, (stage.stageHeight/3)*2);
			graphics.lineStyle(10,0x111111, 1);
			graphics.moveTo((stage.stageWidth/2)-30, ((stage.stageHeight/4)*3)+20);
			graphics.lineTo((stage.stageWidth/2)-30, ((stage.stageHeight/3)*2)-30);
			graphics.moveTo((stage.stageWidth/2)+30, ((stage.stageHeight/4)*3)+20);
			graphics.lineTo((stage.stageWidth/2)+30, ((stage.stageHeight/3)*2)-30);

			//visual aids
			/*graphics.lineStyle(1, 0x000000, .5);
			graphics.beginFill(0xff0000, .2);
			graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight/3*2);
			graphics.drawRect(450,400,100,200);
			graphics.drawCircle(500,200,5);
			graphics.drawCircle(450,400,5);
			graphics.drawCircle(450,600,5);
			graphics.drawCircle(550,600,5);
			graphics.drawCircle(550,400,5);*/

			segmentOut = new Segment(new Vector2(stage.stageWidth/2+15,((stage.stageHeight/4)*3)+20),new Vector2(stage.stageWidth/2,((stage.stageHeight/3)*2)-30));
			segmentIn = new Segment(new Vector2(stage.stageWidth/2-15,((stage.stageHeight/3)*2)-30),new Vector2(stage.stageWidth/2,((stage.stageHeight/4)*3)+20));
			_path = new Array();
			_path.push(segmentIn);
			_path.push(segmentOut);

			buoyIn = new Shape();
			buoyOut = new Shape();
			buoyIn.graphics.drawCircle(segmentIn.startPt.x, segmentIn.startPt.y, 15);
			addChild(buoyIn);
			buoyOut.graphics.drawCircle(segmentOut.startPt.x, segmentOut.startPt.y, 15);
			addChild(buoyOut);

			var temp:Cargo;
			for (var i : int = 0; i < 6; i++)
			{
				temp = new Cargo(this,200 + (50 * i),0,1,i);
				temp.turnLeft(i * 360/10);
				_cargoArray.push(temp);
			}
			var temp2:Pirate;
			for (var l : int = 0; l < 3; l++)
			{
				temp2 = new Pirate(this, Math.random()*stage.stageWidth, (Math.random()/2)*stage.stageHeight, 1, l);
				_pirateArray.push(temp2);
			}
			var temp3:Navy;
			for (var n:int = 0; n < 2; n++)
			{
				temp3 = new Navy(this, 500, 500-(100*n), 1, n);
				_navyArray.push(temp3);
			}
			var fog:Fog;
			for (var m:int = 0; m < 3; m++)
			{
				fog = new Fog(this, Math.random()*stage.stageWidth, Math.random()*(stage.stageHeight/3)*2, 1);
				_fogArray.push(fog);
			}
		}

		//This frameloop sends an update message to each turtle in the turtleArray
		private function frameLoop(e: Event ):void
		{
			//manage dt: change in time
			_curTime = getTimer();
			_dt = (_curTime - _lastTime) / 1000;
			_lastTime = _curTime;

			//tell the sprites to do their update
			for (var i:int = 0; i < _cargoArray.length; i++)
			{
				var o:int = 0;
				for(var n:int = 0; n < _fogArray.length; n++)
				{
					if(_cargoArray[i].position.distance(_fogArray[n].position) < 100)
						o++;
				}
				if (o > 0)
					_cargoArray[i].hidden = true;
				else
					_cargoArray[i].hidden = false;
				if (_cargoArray[i].hitTestObject(buoyIn) && _cargoArray[i].cargo == false && _cargoArray[i].channel == false)
				{
					_cargoArray[i].channel = true;
					//trace("entering harbor");
				}
				if (_cargoArray[i].hitTestObject(buoyOut) && _cargoArray[i].cargo == true && _cargoArray[i].channel == false)
				{
					_cargoArray[i].channel = true;
					//trace("leaving harbor");
				}
				if (_cargoArray[i].hitTestObject(buoyIn) && _cargoArray[i].cargo == true && _cargoArray[i].channel == true)
				{
					_cargoArray[i].channel = false;
					_cargoArray[i].safe = false;
					//trace("harbor left");
				}
				if (_cargoArray[i].hitTestObject(buoyOut) && _cargoArray[i].cargo == false && _cargoArray[i].channel == true)
				{
					_cargoArray[i].channel = false;
					_cargoArray[i].safe = true;
					//trace("harbor entered");
				}
				_cargoArray[i].update(_dt);
				for (var l:int = 0; l < _pirateArray.length; l++)
				{
					if (_cargoArray[i].hitTestObject(_pirateArray[l]))
						_cargoArray[i].lootBoat();
				}
			}
			for (var j:int = 0; j < _pirateArray.length; j++)
			{
				var q:int = 0;
				for(var r:int = 0; r < _fogArray.length; r++)
				{
					if(_pirateArray[j].position.distance(_fogArray[r].position) < 80)
						q++;
				}
				if (q > 0)
					_pirateArray[j].hidden = true;
				else
					_pirateArray[j].hidden = false;
				_pirateArray[j].update(_dt);
				for (var p:int = 0; p < _navyArray.length; p++)
				{
					if(_pirateArray[j].hitTestObject(_navyArray[p]))
					   _pirateArray[j].lootBoat();
				}
			}
			for (var m:int = 0; m < _navyArray.length; m++)
			{
				_navyArray[m].update(_dt);
			}
			for (var k:int = 0; k < _fogArray.length; k++)
			{
				_fogArray[k].update(_dt);
			}
		}

		public function addFwd():Vector2
		{
			var sumX:Number = 0;
			var sumY:Number = 0;
			for (var i:Number = 0; i < _cargoArray.length; i++)
			{
				sumX +=  _cargoArray[i].fwd.x;
				sumY +=  _cargoArray[i].fwd.y;
			}
			var vectorSum:Vector2 = new Vector2(sumX,sumY);
			return vectorSum.getNormalized();
		}

		public function findCentroid():Vector2
		{
			var sumX:Number = 0;
			var sumY:Number = 0;
			for (var i:Number = 0; i < _cargoArray.length; i++)
			{
				sumX +=  _cargoArray[i].position.x;
				sumY +=  _cargoArray[i].position.y;
			}
			var vectorSum:Vector2 = new Vector2(sumX,sumY);
			return vectorSum.divide(_cargoArray.length);
		}
	}
}