package com.audiotool.workers.bitboy
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	internal final class Format
	{
		//-- define some positions in the file
		private static const P_FORMAT: uint = 0x438;
		private static const P_LENGTH: uint = 0x3b6;
		private static const P_SEQUENCE: uint = 0x3b8;
		private static const P_PATTERNS: uint = 0x43c;

		static public function decode( stream: ByteArray ): Format
		{
			return new Format().parse( stream );
		}

		public var type: String;
		public var sequence: Vector.<uint>;
		public var sequenceLength: uint;
		public var title: String;
		public var numPatterns: uint;
		public var patterns: Vector.<Vector.<Vector.<Step>>>;
		public var samples: Vector.<Sample>;
		public var credits: Array;

		public function Format() {}

		public function getStepAt( patternIndex: uint, rowIndex: uint, channelIndex: uint ): Step
		{
			return patterns[ patternIndex ][ rowIndex ][ channelIndex ];
		}

		public function getSequenceAt( sequenceIndex: uint ): uint
		{
			return sequence[ sequenceIndex ];
		}

		public function getPatternLength( patternIndex: uint ): uint
		{
			return patterns[ patternIndex ].length;
		}
		
		private function parse( stream: ByteArray ): Format
		{
			stream.endian = Endian.LITTLE_ENDIAN;

			type = readFormat( stream );

			if( 'm.k.' != type.toLocaleLowerCase() )
				throw new Error( 'Unsupported MOD format' );

			title = readTitle( stream );
			sequenceLength = readSequenceLength( stream );
			samples = readSamples( stream );
			numPatterns = readSequence( stream, sequence = new Vector.<uint>( sequenceLength, true ) );
			patterns = readPatterns( stream, numPatterns, samples );
			credits = new Array();

			for( var i: int = 1 ; i <= 31 ; ++i )
			{
				const sample: Sample = samples[ i ];
				sample.loadWaveform( stream );

				if( sample.length != 0 && sample.title != '' )
					credits.push( sample.title );
			}

			return this;
		}

		private static function readFormat( stream: ByteArray ): String
		{
			stream.position = P_FORMAT;

			return  String.fromCharCode( stream.readByte() ) +
					String.fromCharCode( stream.readByte() ) +
					String.fromCharCode( stream.readByte() ) +
					String.fromCharCode( stream.readByte() );
		}

		private static function readTitle( stream: ByteArray ): String
		{
			stream.position = 0;

			var s: String = '';

			for( var i: int = 0; i < 20; ++i )
			{
				const c: uint = stream.readUnsignedByte();

				if( 0 == c )
					break;

				s += String.fromCharCode( c );
			}

			return s;
		}

		private static function readSequenceLength( stream: ByteArray ): uint
		{
			stream.position = P_LENGTH;

			return stream.readUnsignedByte();
		}

		private static function readSequence( stream: ByteArray, sequence: Vector.<uint> ): uint
		{
			stream.position = P_SEQUENCE;

			var patternNum: uint = 0;

			const n: int = sequence.length;

			for( var i: int = 0; i < n ; ++i )
			{
				sequence[ i ] = stream.readUnsignedByte();

				patternNum = Math.max( patternNum, sequence[ i ] );
			}

			return patternNum;
		}

		private static function readSamples( stream: ByteArray ): Vector.<Sample>
		{
			const samples: Vector.<Sample> = new Vector.<Sample>( 32, true );

			const bytes: ByteArray = new ByteArray();

        	for( var i: int = 1 ; i <= 31 ; ++i )
        	{
            	stream.position = ( i - 1 ) * 0x1e + 0x14;
				bytes.position = 0;
				stream.readBytes( bytes, 0, 30 );

				samples[ i ] = new Sample( bytes );
	        }

			return samples;
		}

		private static function readPatterns( stream: ByteArray, numPatterns: int, samples: Vector.<Sample> ): Vector.<Vector.<Vector.<Step>>>
		{
			const patterns: Vector.<Vector.<Vector.<Step>>> =
					new Vector.<Vector.<Vector.<Step>>>( numPatterns + 1, true );

			for( var i: int = 0 ; i <= numPatterns ; ++i )
			{
				stream.position = P_PATTERNS + i * 0x400; // 4bytes * 4channels * 64rows = 0x400bytes

				const rows: Vector.<Vector.<Step>> = new Vector.<Vector.<Step>>( 64, true );

				for ( var j: int = 0; j < 64 ; ++j )
				{
					const channels: Vector.<Step> = new Vector.<Step>( 4, true );

					for ( var k: int = 0; k < 4 ; ++k )
					{
						const trigger: Step = new Step( stream );

						trigger.sample = samples[ trigger.sampleIndex ];

						channels[k] = trigger;
					}

					rows[j] = channels;
				}

				patterns[i] = rows;
			}

			return patterns;
		}
	}
}