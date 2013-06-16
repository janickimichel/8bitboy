package com.audiotool.workers.bitboy
{
	/**
	 * @author Andre Michelle
	 */
	internal final class Buffer
	{
		public static function create( n: int ): Buffer
		{
			var first: Buffer;
			var last: Buffer = first = new Buffer();

			for( var i: int = 1 ; i < n; ++i )
				last = last.next = new Buffer();

			return first;
		}

		public var l: Number = 0.0;
		public var r: Number = 0.0;
		public var next: Buffer;
	}
}