package  {
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	import flash.events.Event;

	public class Cargo extends SteeringVehicle
	{ 
		// tweak these value to tune behavior
		public static var pursuitWeight: Number = 1;
		public static var collideWeight: Number = 10;
		public static var pathWeight: Number = 3;
		public static var fleeWeight: Number = 5;
		public static var tetherWeight: Number = 10;
		public static var separationWeight: Number = 1;
		
		private var _index: Number = -1;
		private var _pursuer: Number = -1;
		private var dockTarget: Number = -1;
		private var fogTarget: Number = -1;
		
		private var _cargo: Boolean = false;
		private var _isSafe: Boolean = false;
		private var _isChanneling: Boolean = false;
		private var _isVoyaging: Boolean = false;
		private var _isEvading: Boolean = false;
		private var _isHidden: Boolean = false;
		
		private var channel1:Vector2;
		private var channel2:Vector2;
		private var destination:Vector2;
		
		private var loadTimer:Timer;
		private var returnTimer:Timer;
		private var trips:int = 0;

		public function get index() {return _index; }
		public function get safe() { return _isSafe; }
		public function get cargo() { return _cargo; }
		public function get channel() { return _isChanneling; }
		public function get voyage() { return _isVoyaging; }
		public function get hidden() { return _isHidden; }
		public function get evade() { return _isEvading; }
		public function get pursuer() { return _pursuer; }
		
		public function set safe(s:Boolean) { _isSafe=s; }
		public function set cargo(s:Boolean) { _cargo=s; }
		public function set channel(s:Boolean) { _isChanneling=s; }
		public function set voyage(s:Boolean) { _isVoyaging=s; }
		public function set hidden(s:Boolean) { _isHidden=s; }
		public function set evade(s:Boolean) { _isEvading=s; }
		public function set pursuer(n:Number) { _pursuer=n; }

		public function Cargo(aMan:Manager, aX:Number=0, aY:Number=0, aSpeed:Number=0, aIndex:Number=-1 )
		{
			super(aMan, aX, aY, aSpeed);
			aMan.addChild(this);
			this.scaleX = .5;
			this.scaleY = .5;
			this.gotoAndStop(1);
			maxSpeed = 20;
			_index = aIndex;
			loadTimer = new Timer(5000, 1);
			loadTimer.addEventListener(TimerEvent.TIMER, loadCargo);
			returnTimer = new Timer(15000, 1);
			returnTimer.addEventListener(TimerEvent.TIMER, recycleBoat);
			channel2 = new Vector2(stage.stageWidth/2,((stage.stageHeight/3)*2)-30);
			channel1 = new Vector2(stage.stageWidth/2,((stage.stageHeight/4)*3)+20);
		}	
			
		//this calcSteeringForce combines two forces: tether and wander
		//arbitration can be contolled by changing the weights
		override protected function calcSteeringForce( ):Vector2
		{
			if(pursuer != -1 && _manager.pirateArray[pursuer].target == index)
				_isEvading = true;
			if(trips > 0)
				hireEscort();
			
			var steeringForce:Vector2 = new Vector2( );
			if(_isVoyaging == true)
			{
				if(returnTimer.running == false)
				{
					fireEscort();
					trips++;
					returnTimer.start();
				}
			}
			else if(_isEvading == true)
			{
				switch(findSafety()) {
					case 1:
					if(_isHidden == true)
						steeringForce = steeringForce.add(tetherFog(fogTarget).multiply(tetherWeight));
					else if(_isHidden == false)
						steeringForce = steeringForce.add(arrive(_manager.fogArray[fogTarget].position, 80, 10).multiply(pursuitWeight));
					break;
					case 2:
					steeringForce = steeringForce.add(arrive(channel2, 50, 10).multiply(pursuitWeight));
					break;
					case 3:
					steeringForce = steeringForce.add(seek(destination).multiply(pursuitWeight));
					break;
					case -1:
					break;
				}
				//steeringForce = steeringForce.add(evasion(_manager.pirateArray[pursuer].position, _manager.pirateArray[pursuer].velocity, _manager.pirateArray[pursuer].maxSpeed).multiply(fleeWeight));
				if(position.distance(_manager.pirateArray[pursuer].position) > 150 && _manager.pirateArray[pursuer].target != index)
				{
					_isEvading = false;
					pursuer = -1;
				}
			}
			else if(_cargo == false && _isSafe == true && _isChanneling == false)
			{
				var temp:Vector2 = arrive(_manager.dockArray[findDock(_manager.dockArray)].position, 100, 5);
				steeringForce = steeringForce.add(temp).multiply(pursuitWeight);
				/*if(this.currentFrame !=4)
				{
					this.gotoAndStop(3);
				}*/
				if(temp.x < .01 && temp.y < .01 && temp.x > -.01 && temp.y > -.01 && loadTimer.running == false)
				{
					loadTimer.start();
				}
			}
			else if(_cargo == false && _isSafe == false && _isChanneling == false)
			{
				steeringForce = steeringForce.add(seek(channel2)).multiply(pursuitWeight);
			}
			else if(_cargo == true && _isSafe == true && _isChanneling == false)
			{
				steeringForce = steeringForce.add(seek(channel1)).multiply(pursuitWeight);
			}
			else if(_cargo == true && _isSafe == false && _isChanneling == false)
			{
				steeringForce = steeringForce.add(seek(destination)).multiply(pursuitWeight);
				if(this.y < 0 && this.cargo == true)
				{
					voyage = true;
				}
			}
			else if(_cargo == false && _isSafe == false && _isChanneling == true)
			{
				fireEscort();
				steeringForce = steeringForce.add(followPath(0, _manager.path, 10, _manager.time)).multiply(pathWeight);
				steeringForce = steeringForce.add(seek(channel1)).multiply(pursuitWeight);
			}
			else if(_cargo == true && _isSafe == true && _isChanneling == true)
			{
				steeringForce = steeringForce.add(followPath(1, _manager.path, 10, _manager.time)).multiply(pathWeight);
				steeringForce = steeringForce.add(seek(channel2)).multiply(pursuitWeight);
			}
			
			steeringForce = steeringForce.add(separation(20, _manager.cargoArray).multiply(separationWeight));
			for each(var obs:Block in _manager.blockArray)
				steeringForce = steeringForce.add(avoid(obs.position, obs.radius, 5).multiply(collideWeight));				
			return steeringForce;
		}
		
		private function findDock(docks:Array) : Number
		{
			//loop through docks, find the nearest unoccupied dock to the cargo vessel
			var tempDistance:Number = 0, closestDistance:Number = Number.MAX_VALUE;
			for(var i:Number = 0; i < docks.length; i++)
			{
				tempDistance = position.distanceSqr(docks[i].position);
				if (tempDistance < closestDistance && (docks[i].occupied == false || docks[i].claim == index))
				{
					if( dockTarget > -1 && docks[dockTarget].claim == index && dockTarget != i)
					{
						_manager.dockArray[dockTarget].occupied = false;
						_manager.dockArray[dockTarget].claim = -1;
						_manager.dockArray[dockTarget].gotoAndStop(1);
						//trace("dock canceled");
					}
					closestDistance = tempDistance;
					dockTarget = i;
				}
			}				
			//return 1;
			if(_manager.dockArray[dockTarget].occupied == false)
			{
				_manager.dockArray[dockTarget].gotoAndStop(2);
				_manager.dockArray[dockTarget].occupied = true;
				_manager.dockArray[dockTarget].claim = index;
				//trace("dock reserved");
			}
			return dockTarget;
		}
		
		private function findSafety() : Number
		{
			var type:Number = -1;
			var closest:Number = Number.MAX_VALUE;
			var distance:Number = -1;

			distance = position.distance(channel2);
			if(distance < closest)
			{
				type = 2;
				closest = distance;
			}
			if(destination != null && position.distance(destination) < closest)
			{
				closest = position.distance(destination);
				type = 3;
			}
			for(var a:int = 0; a < _manager.fogArray.length; a++)
			{
				distance = position.distance(_manager.fogArray[a].position);
				if(distance < closest)
				{
					closest = distance;
					fogTarget = a;
					type = 1;
				}
			}
			return type;
		}

		private function loadCargo(e:TimerEvent) : void
		{
			//trace("cargo loaded");
			_cargo = true;
			this.gotoAndStop(2);
			_manager.dockArray[dockTarget].occupied = false;
			_manager.dockArray[dockTarget].claim = -1;
			_manager.dockArray[dockTarget].gotoAndStop(1);
			//trace("dock released");
			//determine where the cargo needs to go
			destination = new Vector2(Math.random()*stage.stageWidth,-10);
		}
		
		private function recycleBoat(e:TimerEvent) : void
		{
			this.gotoAndStop(1);
			switch(Math.round(Math.random()*2)) {
				case 0:
				position.x = Math.random()*stage.stageWidth;
				position.y = -10;
				break;
				case 1:
				position.x = -10;
				position.y = Math.random()*stage.stageHeight/2;
				break;
				case 2:
				position.x = 1010;
				position.y = Math.random()*stage.stageHeight/2;
				break;
			}
			cargo = false;
			safe = false;
			voyage = false;
			evade = false;
			hidden = false;
			channel = false;
			destination = null;
			dockTarget = -1;
			fogTarget = -1;
			_pursuer = -1;
			//trace("boat #"+index+" has returned");
		}
		
		public function lootBoat():void
		{
			this.gotoAndStop(1);
			position.x = Math.random()*stage.stageWidth;
			position.y = -10;
			cargo = false;
			safe = false;
			voyage = false;
			hidden = false;
			evade = false;
			channel = false;
			destination = null;
			dockTarget = -1;
			fogTarget = -1;
			_pursuer = -1;
			trips = 0;
		}
		
		public function hireEscort():void
		{
			var hired:Boolean = false;
			trips--;
			for(var i:int = 0; i < _manager.navyArray.length; i++)
			{
				if(hired==false && _manager.navyArray[i].targetC == -1 && _manager.navyArray[i].escort == false)
				{
					hired = true;
					_manager.navyArray[i].targetC = index;
					_manager.navyArray[i].escort = true;
				}
			}
		}
		
		public function fireEscort():void
		{
			for(var i:int = 0; i < _manager.navyArray.length; i++)
			{
				if(_manager.navyArray[i].targetC == index && _manager.navyArray[i].escort == true)
				{
					_manager.navyArray[i].targetC = -1;
					_manager.navyArray[i].escort = false;
				}
			}
		}
	}
}
