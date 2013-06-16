package com.audiotool.workers.bitboy
{
	import flash.events.SampleDataEvent;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.utils.ByteArray;

	internal final class Player implements PlayerCommands
	{
		internal static const DefaultBufferSize: int = 2048;
		internal static const FlashSamplingRate: int = 44100;
		internal static const BpmRatio: Number = 2.5;
		internal static const NumChannels: int = 4;
		internal static const DefaultBpm: int = 125;
		internal static const DefaultSpeed: int = 6;

		private var _buffer: Buffer;
		private var _bufferSize: int = DefaultBufferSize;

		private var _samplingRateShift: int = 0;

		private var _state: PlayerState;
		private var _channels: Vector.<Channel>;

		private var _sound: Sound;
		private var _soundChannel: SoundChannel;

		private var _pause: Boolean = false;
		private var _volume: Number = 1.0;

		private var _formatInfo: FormatInfo;

		private var _tickPosition: int; // samples
		private var _position: Number; // seconds

		public function Player()
		{
			_state = new PlayerState();

			_channels = new Vector.<Channel>( 4 );
			_channels[0] = new Channel( this, _state.channelStates[0] );
			_channels[1] = new Channel( this, _state.channelStates[1] );
			_channels[2] = new Channel( this, _state.channelStates[2] );
			_channels[3] = new Channel( this, _state.channelStates[3] );

			// Original Amiga
			_channels[0].panning = -1.0;
			_channels[1].panning =  1.0;
			_channels[2].panning =  1.0;
			_channels[3].panning = -1.0;
		}

		public function get formatInfo(): FormatInfo
		{
			return _formatInfo;
		}

		public function setFormat( bytes: ByteArray ): void
		{
			var format: Format = null;

			try
			{
				format = Format.decode( bytes );
			}
			catch( error: Error ) {}

			if( null == format )
				return;

			_position = 0.0;
			_tickPosition = 0;

			const wasPause: Boolean = _pause;
			const wasLoopMode: Boolean = _state.loopMode;

			_state.reset();
			_state.format = format;
			_state.loopMode = false;
			_pause = false;

			const seconds: Number = analyse();
			_formatInfo = new FormatInfo( format.title, format.credits, seconds );

			_state.reset();
			_state.loopMode = wasLoopMode;
			_pause = wasPause;
		}

		public function start(): void
		{
			if( null != _soundChannel )
				return;

			_sound = new Sound();
			_sound.addEventListener( SampleDataEvent.SAMPLE_DATA, onSampleData );
			_soundChannel = _sound.play();
		}

		public function stop(): void
		{
			if( null == _soundChannel )
				return;

			_soundChannel.stop();
			_soundChannel = null;
			_sound.removeEventListener( SampleDataEvent.SAMPLE_DATA, onSampleData );
			_sound = null;
		}

		public function setPause( value: Boolean ): void
		{
			_pause = value;
		}

		public function setBufferSize( size: int ): void
		{
			if( _bufferSize == size )
				return;

			_bufferSize = size;
			_buffer = null;
		}

		public function setSamplingRateShift( shift: int ): void
		{
			if( _samplingRateShift == shift )
				return;

			_samplingRateShift = shift;
			_buffer = null;
		}

		public function setVolume( value: Number ): void
		{
			_volume = value;
		}

		public function setLoopMode( value: Boolean ): void
		{
			_state.loopMode = value;
		}

		public function setChannelVolume( index: int, volume: Number ): void
		{
			_channels[index].volume = volume;
		}

		public function setChannelPanning( index: int, panning: Number ): void
		{
			_channels[index].panning = panning;
		}

		public function setChannelMute( index: int, mute: Boolean ): void
		{
			_channels[index].mute = mute;
		}

		public function get position(): Number
		{
			return _position;
		}

		internal function get samplingRate(): Number
		{
			return FlashSamplingRate >> _samplingRateShift;
		}

		private function onSampleData( event: SampleDataEvent ): void
		{
			if( !_state.running || _pause )
			{
				event.data.length = _bufferSize << 3;
				return;
			}

			const n: int = _bufferSize >> _samplingRateShift;

			if( null == _buffer )
				_buffer = Buffer.create( n );

			const data: ByteArray = event.data;

			const samplesPerTick: int = samplingRate * BpmRatio / _state.bpm;

			var pointer: Buffer = _buffer;

			for( var bufferIndex: int = 0 ; bufferIndex < n ; )
			{
				var process: int = Math.min( n - bufferIndex, samplesPerTick - _tickPosition );

				for( var ci: int = 0 ; ci < NumChannels ; ++ci )
					_channels[ci].processAudio( pointer, process );

				bufferIndex += process;
				_tickPosition += process;
				_position += process / FlashSamplingRate; // Flash SamplingRate

				while( -1 < --process )
				{
					const l: Number = _volume * pointer.l;
					const r: Number = _volume * pointer.r;

					var si: int = 1 << _samplingRateShift;

					while( si-- )
					{
						data.writeFloat( l );
						data.writeFloat( r );
					}

					pointer.l = 0.0;
					pointer.r = 0.0;
					pointer = pointer.next;
				}

				if( _tickPosition >= samplesPerTick )
				{
					_tickPosition = 0;
					_state.processTick();
				}

				if( !_state.running )
				{
					event.data.length = _bufferSize << 3;
					break;
				}
			}
		}

		private function analyse(): Number
		{
			var seconds: Number = 0.0;

			while( true )
			{
				_state.nextStep();

				if( _state.loop )
				{
					seconds = -1.0;
					break;
				}

				seconds += ( Player.BpmRatio / _state.bpm ) * _state.speed;

				if( _state.lastRow )
					break;
			}

			return seconds;
		}
	}
}