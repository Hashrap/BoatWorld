package  {
	
	public class Pirate extends SteeringVehicle
	{ 
		// tweak these value to tune behavior
		public static var tetherWeight: Number = 6;
		public static var wanderWeight: Number = 2;
		public static var pursuitWeight: Number = 1;
		public static var collideWeight: Number = 10;
		public static var fleeWeight: Number = 4;
		
		private var _lineOfSight = 150;
		
		private var _index = -1;
		private var _pursuer = -1;
		private var _targetC = -1;
		private var _targetF = -1;
		
		private var _isEvading: Boolean = false;
		private var _isHidden: Boolean = false;
		
		public function get index() {return _index; }
		public function get target() { return _targetC; }
		public function get hidden() { return _isHidden; }
		public function get evade() { return _isEvading; }
		public function get pursuer() { return _pursuer; }
		
		public function set hidden(s:Boolean) { _isHidden=s; }
		public function set evade(s:Boolean) { _isEvading=s; }
		public function set pursuer(n:Number) { _pursuer=n; }

		public function Pirate(aMan:Manager, aX:Number=0, aY:Number=0, aSpeed:Number=0, aIndex:Number=-1)
		{
			super(aMan, aX, aY, aSpeed);
			aMan.addChild(this);
			scaleX = .4;
			scaleY = .4;
			_index = aIndex;
			_center = new Vector2(500, 200);
			maxSpeed = 30;
		}	
			
		//this calcSteeringForce combines two forces: tether and wander
		//arbitration can be contolled by changing the weights
		override protected function calcSteeringForce( ):Vector2
		{
			if(pursuer != -1 && _manager.navyArray[pursuer].targetP == index)
				_isEvading = true;
				
			var steeringForce:Vector2 = new Vector2( );
			_targetC = findTarget();
			
			if(_isEvading == true && pursuer != -1)
			{
				var n:int = findSafety();
				steeringForce = steeringForce.add(evasion(_manager.navyArray[pursuer].position, _manager.navyArray[pursuer].velocity, _manager.navyArray[pursuer].maxSpeed).multiply(fleeWeight));
				if(_isHidden == true)
					steeringForce = steeringForce.add(tetherFog(n).multiply(tetherWeight));
				else
					steeringForce = steeringForce.add(seek(_manager.fogArray[n].position).multiply(pursuitWeight));
				if(position.distance(_manager.navyArray[pursuer].position) > 150 && _manager.navyArray[pursuer].targetP != index)
				{
					_isEvading = false;
					pursuer = -1;
				}
			}
			else if(_targetC == -1)
			{
				steeringForce = steeringForce.add(wander().multiply(wanderWeight));
			}
			else if(evade == false && _targetC != -1)
			{
				steeringForce = steeringForce.add(pursuit(_manager.cargoArray[_targetC].position, _manager.cargoArray[_targetC].velocity, _manager.cargoArray[_targetC].maxSpeed).multiply(pursuitWeight));
			}
			steeringForce = steeringForce.add(tether().multiply(tetherWeight));
			for each(var obs:Block in _manager.blockArray)
				steeringForce = steeringForce.add(avoid(obs.position, obs.radius, obs.radius).multiply(collideWeight));
			return steeringForce;
		}
		
		private function findTarget():Number
		{
			_targetC = -1;
			var closest:Number = Number.MAX_VALUE;
			for(var i:int = 0; i < _manager.cargoArray.length; i++)
			{
				var distance:Number = position.distance(_manager.cargoArray[i].position);
				if(_manager.cargoArray[i].hidden == false && distance < _lineOfSight && _manager.cargoArray[i].y > 0 && _manager.cargoArray[i].x > 0 && _manager.cargoArray[i].x < 1000)
				{
					if(distance < closest)
					{
						_targetC = i;
						closest = distance;
					}
					_manager.cargoArray[i].evade = true;
					_manager.cargoArray[i].pursuer = _index;
				}
			}
			return target;
		}
				
		private function findSafety() : Number
		{
			var findex:Number = -1;
			var closest:Number = Number.MAX_VALUE;
			var distance:Number = -1;
			
			for(var a:int = 0; a < _manager.fogArray.length; a++)
			{
				distance = position.distanceSqr(_manager.fogArray[a].position);
				if(distance < closest)
				{
					closest = distance;
					findex = a;
				}
			}
			return findex;
		}
		
		public function lootBoat():void
		{
			//this.gotoAndStop(4);
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
			hidden = false;
			evade = false;
			_targetF = -1;
			_pursuer = -1;
			_targetC = -1;
		}
	}
}
