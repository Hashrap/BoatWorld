package 
{

	public class Navy extends SteeringVehicle
	{
		// tweak these value to tune behavior
		public static var pursuitWeight:Number = 1;
		public static var tetherWeight:Number = 3;
		public static var wanderWeight:Number = 7;
		public static var collideWeight:Number = 10;
		
		private var _targetP:Number = -1;
		private var _targetC:Number = -1;
		private var _index:Number = -1;
		
		private var _lineOfSight:Number = 150;
		
		private var _isEscort:Boolean = false;
		
		public function get targetC() { return _targetC; }
		public function get targetP() { return _targetP; }
		public function get index() { return _index; }
		public function get escort() { return _isEscort; }
		public function set escort(s:Boolean) { _isEscort = s; }
		public function set targetC(n:int) { _targetC = n; }

		public function Navy(aMan:Manager, aX:Number=0, aY:Number=0, aSpeed:Number=0, aIndex:Number=0)
		{
			super(aMan, aX, aY, aSpeed);
			aMan.addChild(this);
			scaleX = .5;
			scaleY = .5;
			_center = new Vector2(500,400);
			maxSpeed = 35;
			_index = aIndex;
		}

		override protected function calcSteeringForce( ):Vector2
		{
			var steeringForce:Vector2 = new Vector2( );
			if(findTarget() != -1)
				steeringForce = steeringForce.add(pursuit(_manager.pirateArray[_targetP].position, _manager.pirateArray[_targetP].velocity, _manager.pirateArray[_targetP].maxSpeed).multiply(pursuitWeight));
			else if(escort == true && targetC != -1)
			{
				steeringForce = steeringForce.add(followLeader(_manager.cargoArray[targetC]).multiply(pursuitWeight));
			}
			else if(findTarget() == -1 && escort == false)
			{
				steeringForce = steeringForce.add(wander().multiply(wanderWeight));
			}
			steeringForce = steeringForce.add(tether().multiply(tetherWeight));
			for each(var obs:Block in _manager.blockArray)
				steeringForce = steeringForce.add(avoid(obs.position, obs.radius, obs.radius).multiply(collideWeight));
			return steeringForce;
		}
		
		private function findTarget():Number
		{
			_targetP = -1;
			var closest:Number = Number.MAX_VALUE;
			for(var i:int = 0; i < _manager.pirateArray.length; i++)
			{
				var pirateOffset:Vector2 = _manager.pirateArray[i].position.subtract(this.position);
				var distance:Number = position.distance(_manager.pirateArray[i].position);
				if(_manager.pirateArray[i].hidden == false && distance < _lineOfSight && distance < closest)
				{
					_targetP = i;
					closest = distance;
					_manager.pirateArray[i].evade = true;
					_manager.pirateArray[i].pursuer = _index;
				}
			}
			return _targetP;
		}
	}
}