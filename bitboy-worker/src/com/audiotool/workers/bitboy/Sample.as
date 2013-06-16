package com.audiotool.workers.bitboy
{
	import flash.utils.ByteArray;

	internal final class Sample
	{
		public var title: String;
		public var length: int;
		public var tone: int;
		public var volume: int;
		public var repeatStart: int;
		public var repeatLength: int;
		public var wave: Vector.<Number>;
		
		public function Sample( stream: ByteArray )
		{
			parse( stream );
		}
		
		public function loadWaveform( stream: ByteArray ): void
		{
			if( 0 == length )
				return;

			wave = new Vector.<Number>( length, true );

			var value: Number;
			var min: Number = 1;
			var max: Number = -1;
			
			var i: int;
			
			for( i = 0 ; i < length ; i++ )
			{
				value = ( stream.readByte() + 0.5 ) / 127.5;
				
				if( value < min ) min = value;
				if( value > max ) max = value;
				
				wave[i] = value;
			}
			
			const base: Number = ( min + max ) * 0.5;

			for( i = 0 ; i < length ; i++ )
				wave[i] -= base;
		}
		
		private function parse( stream: ByteArray ): void
		{
			stream.position = 0;			

			// read 22 chars into the title
			// we do not break if we reach the NUL char cause this would turn
			// the stream.position wrong

			title = '';

			for ( var i: int = 0 ; i < 22 ; ++i )
			{
				const c: uint = uint( stream.readByte() );

				if ( 0 != c )
					title += String.fromCharCode( c );
			}

			length = stream.readUnsignedShort();
			tone = stream.readUnsignedByte(); //everytime 0
			volume = stream.readUnsignedByte();
			repeatStart = stream.readUnsignedShort();
			repeatLength = stream.readUnsignedShort();

			//-- turn it into bytes
			length <<= 1;
			repeatStart <<= 1;
			repeatLength <<= 1;
		}
		
		public function toString(): String
		{
			return '[Sample'
				+ ' title: '+ title
				+ ', length: ' + length
				+ ', tone: ' + tone
				+ ', volume: ' + volume
				+ ', repeatStart: ' + repeatStart
				+ ', repeatLength: ' + repeatLength
				+ ']';
		}
	}
}