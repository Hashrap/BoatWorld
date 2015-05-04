package 
{
	import flash.display.MovieClip;

	public class Dock extends MovieClip
	{

		private var _position:Vector2;
		private var _occupied:Boolean;
		private var _claimedBy:Number;

		public function Dock(aX:Number, aY: Number)
		{
			x = aX;
			y = aY;
			_position = new Vector2(x,y);
			_occupied = new Boolean(false);
			_claimedBy = -1;
		}

		public function get position( ):Vector2
		{
			return _position;
		}
		public function get claim( ):Number
		{
			return _claimedBy;
		}
		public function set claim(n:Number)
		{
			_claimedBy = n;
		}
		public function get occupied( ):Boolean
		{
			return _occupied;
		}
		public function set occupied(o:Boolean)
		{
			_occupied = o;
		}
	}
}