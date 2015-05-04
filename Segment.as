package 
{

	public class Segment
	{
		public var length:Number;
		public var startPt:Vector2;
		public var endPt:Vector2;
		public var unitVec:Vector2;

		public function Segment(start:Vector2, end:Vector2)
		{
			startPt = start;
			endPt = end;
			var vector:Vector2 = end.subtract(start);
			unitVec = vector.getNormalized();
		}

	}

}