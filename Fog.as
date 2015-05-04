package 
{

	import flash.display.MovieClip;


	public class Fog extends SteeringVehicle
	{

		public function Fog(aMan:Manager, aX:Number=0, aY:Number=0, aSpeed:Number=0)
		{
			super(aMan, aX, aY, aSpeed);
			aMan.addChild(this);
			x = aX;
			y = aY;
			graphics.moveTo(0,0);
			graphics.beginFill(0xCCCCCC, 0.6);
			graphics.drawCircle(0,0,80);
			_center = new Vector2(500,400);
			maxSpeed = 4;
		}

		override protected function calcSteeringForce( ):Vector2
		{
			var steeringForce:Vector2 = new Vector2( );
			steeringForce = steeringForce.add(wander());
			steeringForce = steeringForce.add(tether());
			return steeringForce;
		}
	}
}