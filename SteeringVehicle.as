package  
{
	public class SteeringVehicle extends VectorTurtle
	{
		protected var _maxSpeed: Number = 40;
		protected var _maxForce: Number = 40;
		protected var _mass: Number = 0.5;
	
		protected var _wanderRad:Number = 2;
		protected var _wanderAng :Number = 0;
		protected var _wanderDist :Number = 10;
		protected var _wanderMax :Number = 1;
		protected var _center : Vector2;
		protected var _tether: Number = 150;
	
		public function SteeringVehicle(aMan:Manager, aX:Number = 0, 
								aY:Number = 0, aSpeed:Number = 0) 
		{
			super(aMan, aX, aY, aSpeed);
			// initialize velocity to zero so movement results from applied force
			_velocity = new Vector2( );
		}
		
		public function set maxSpeed(s:Number)		{_maxSpeed = s;	}
		public function set maxForce(f:Number)		{_maxForce = f;	}
		public function get maxSpeed( )		{ return _maxSpeed;	}
		public function get maxForce( )		{ return _maxForce; }
		public function get right( )		{ return fwd.perpRight( ); }

		protected function calcSteeringForce( ):Vector2
		{
			//override in subclasses
			return new Vector2( );
		}

			
		private function clampSteeringForce(force: Vector2 ): Vector2
		{
			var mag:Number = force.magnitude();
			if(mag > _maxForce)
			{
				force = force.divide(mag);
				force = force.multiply(_maxForce);
			}
			return force;
		}
		
			
		protected function seek(targPos : Vector2) : Vector2
		{
			// set desVel equal desired velocity
			var desVel:Vector2 = targPos.subtract(position);

			// scale desired velocity to max speed
			desVel.normalize( );
			desVel = desVel.multiply(_maxSpeed);

			// subtract current velocity from desired velocity to get steering force		
			// return steering force
			return desVel.subtract(_velocity);
		}
		
		protected function flee(targPos : Vector2) : Vector2
		{
			// set desVel equal desired velocity
			var desVel:Vector2 = position.subtract(targPos);

			// scale desired velocity to max speed
			desVel.normalize( );
			desVel = desVel.multiply(_maxSpeed);

			// subtract current velocity from desired velocity
			// to get steering force
			var steeringForce:Vector2 = desVel.subtract(_velocity);
			return steeringForce;
			//return steering force
		}
		
				//tether keeps vehicles from wandering too far from center
		protected function tether() :Vector2
		{
			if ((x > 10 && x < 990 && y > 10 && y < (stage.stageHeight/3*2)-10) && (x > 550 || x < 450 || y > 600 || y < 400))
				return new Vector2(); //no steering required
			else
			{
				return seek(_center);
			}
		}
		protected function tetherFog(findex:int) :Vector2
		{
			if (_manager.fogArray[findex].position.distance(position) > 75)
				return new Vector2(); //no steering required
			else
			{
				return seek(_manager.fogArray[findex].position);
			}
		}

		//wander is an implementation of the Reynolds wander behavior
		protected function wander() :Vector2
		{
			_wanderAng += (Math.random()*_wanderMax *2 - _wanderMax);
			var redDot :Vector2 = position.add(fwd.multiply(_wanderDist));
			var offset :Vector2 = fwd.multiply(_wanderRad);
			offset.rotate(_wanderAng);
			redDot = redDot.add(offset);
			return seek(redDot);
		}

		protected function avoid(obstaclePos:Vector2, obstacleRadius:Number, safeDistance:Number): Vector2 
		{
			var desVel: Vector2; //desired velocity
			var vectorToObstacleCenter: Vector2 = obstaclePos.subtract(position);
			var distance: Number = vectorToObstacleCenter.magnitude();
			
			//if vectorToCenter - obstacleRadius longer than safe return zero vector
			if (distance - obstacleRadius > safeDistance)
				return new Vector2();
				
			// if object behind me return zero vector
			if (vectorToObstacleCenter.dot(fwd) < 0)
				return new Vector2();
			
			var rightDotVTOC:Number = vectorToObstacleCenter.dot(right);
			
			// if sum of radii < dot of vectorToCenter with right return zero vector
			if(obstacleRadius+radius < Math.abs(rightDotVTOC))
				return new Vector2();
			
			if ( rightDotVTOC < 0)
				//move to the right
				desVel = right.multiply(maxSpeed + safeDistance/distance); 
			else															
				//move to the left 
				desVel = right.multiply(-maxSpeed + safeDistance/distance);
				
			return desVel.subtract(_velocity);
		}
		
		protected function followPath(index:int, path:Array, radius:Number, dt:Number) : Vector2
		{
			var closestPoint: Vector2;
			var futurePosition:Vector2;
			futurePosition = position.add(fwd.multiply(_speed * dt))
			var vecToFP:Vector2 = futurePosition.subtract(path[index].startPt);
			
			var projection:Number = path[index].unitVec.dot(vecToFP);
			closestPoint = path[index].startPt.add(path[index].unitVec.multiply(projection));
			var dist:Number = futurePosition.distance(closestPoint);
			if(dist<radius)
				return new Vector2;
			else
				return seek(closestPoint);
		}
		
		protected function arrive(targPos:Vector2, slowingDistance:Number, stoppingDistance:Number): Vector2
		{
			var targOffset:Vector2 = targPos.subtract(position);
			var distance:Number = targOffset.magnitude();
			var rampedSpeed:Number = maxSpeed*(distance / slowingDistance);
			var clippedSpeed:Number = maxSpeed;
			if(rampedSpeed < maxSpeed)
			{
				clippedSpeed = rampedSpeed;
			}
			if(distance < stoppingDistance)
			{
				clippedSpeed = 0;
			}
			//trace(clippedSpeed);
			var desVel:Vector2 = targOffset.multiply(clippedSpeed/distance);
			return desVel.subtract(_velocity);
		}
		
		protected function followLeader(leader:SteeringVehicle): Vector2
		{
			var pastPosition:Vector2 = leader.position.subtract(leader.velocity.multiply(_manager.time * 5));
			return arrive(pastPosition, 100, 10);
		}
		
		protected function evasion(threatPos:Vector2, threatVel:Vector2, threatMax:Number): Vector2
		{
			var futurePosition:Vector2 = threatPos.add(threatVel.multiply(_manager.time * 5));

			return flee(futurePosition);
		}
		
		protected function pursuit(targetPos:Vector2, targetVel:Vector2, targetMax:Number): Vector2
		{
			var futurePosition:Vector2 = targetPos.add(targetVel.multiply(_manager.time * 5));

			return seek(futurePosition);
		}
		
		protected function separation(space:Number, clan:Array):Vector2
		{
			var tempDistance:Number = 0;
			var closestDistance:Number = Number.MAX_VALUE;
			var chump = -1;
			for(var i:Number = 0; i < clan.length; i++)
			{
				tempDistance = this.position.distance(clan[i].position);
				if (tempDistance > 0 && tempDistance < closestDistance && tempDistance < space)
				{
					closestDistance = tempDistance;
					chump = i;
				}
			}
			if(chump > -1)
			{
				return evasion(clan[chump].position, clan[chump].velocity, clan[chump].maxSpeed);
			}
			else
			{
				return new Vector2();
			}
		}
		
		override public function update(dt:Number): void
		{
			var steeringForce:Vector2 = calcSteeringForce( ); 
			steeringForce = clampSteeringForce(steeringForce);
			var acceleration:Vector2 = steeringForce.divide(_mass);
			_velocity = _velocity.add(acceleration.multiply(dt));
			_speed = _velocity.magnitude( );
			fwd = _velocity;
			if (_speed > _maxSpeed)
			{
				_velocity = _velocity.divide(_speed);
				_velocity = _velocity.multiply(_maxSpeed);
				_speed = _maxSpeed;
			}
			// call move with velocity adjusted for time step
			move( _velocity.multiply(dt));
		}
	}
}



