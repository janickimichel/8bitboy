package com.audiotool.workers.bitboy
{
	import flash.utils.ByteArray;

	internal final class Step
	{
		public var effect: int;
		public var effectParam: int;
		public var period: int;
		public var sampleIndex: int;
		public var sample: Sample;
		
		public function Step( stream: ByteArray )
		{
			/*
			 Byte 0    Byte 1   Byte 2   Byte 3
			 aaaaBBBB CCCCCCCCC DDDDeeee FFFFFFFFF
			
			 aaaaDDDD     = sample number
			 BBBBCCCCCCCC = sample period value
			 eeee         = effect number
			 FFFFFFFF     = effect parameters
			*/

			const b0: int = stream.readUnsignedByte();
			const b1: int = stream.readUnsignedByte();
			const b2: int = stream.readUnsignedByte();
			const b3: int = stream.readUnsignedByte();
			
			sampleIndex = ( b0 & 0xf0 ) | ( b2 >> 4 );
			period = ( ( b0 & 0x0f ) << 8 ) | b1;
			effect = b2 & 0x0F;
			effectParam = b3;
		}
		
		public function toString(): String
		{
			return '[Step'
				+ ' sampleIndex: '+ sampleIndex
				+ ', period: ' + period
				+ ', effect: ' + effect
				+ ', effectParam: ' + effectParam
				+ ']';
		}
	}
}