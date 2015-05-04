package 
{
	import flash.display.MovieClip;

	public class Block extends MovieClip
	{

		protected var _manager:Manager;
		protected var _position:Vector2;
		protected var _radius = 100;

		public function Block(aMan:Manager, xPos:Number = 0, yPos:Number = 0, r:Number = 100)
		{
			init(aMan, xPos, yPos, r);
		}

		public function init(aMan:Manager, xPos:Number, yPos:Number, r:Number):void
		{
			_manager = aMan;
			x = xPos;
			y = yPos;
			_radius = r;
			width = r * 2;
			height = r * 2;
			_position = new Vector2(x,y);
		}

		//accessors
		public function get position( ):Vector2
		{
			return _position;
		}
		public function get radius( ):Number
		{
			return _radius;
		}
	}

}