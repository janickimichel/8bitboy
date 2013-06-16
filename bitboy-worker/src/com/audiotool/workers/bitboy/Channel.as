package com.audiotool.workers.bitboy
{
	/**
	 * @author Andre Michelle
	 */
	internal final class Channel
	{
		internal var mute: Boolean;

		private var _player: Player;
		private var _state: ChannelState;

		private var _volume: Number;
		private var _panning: Number;

		private var _gainL: Number;
		private var _gainR: Number;

		private var _position: int = 0;
		private var _cycleComplete: Boolean;

		public function Channel( player: Player, state: ChannelState )
		{
			_player = player;
			_state = state;

			_volume = 1.0;
			_panning = 0.0;

			updateStereo();
		}

		public function get volume(): Number
		{
			return _volume;
		}

		public function set volume( value: Number ): void
		{
			if( _volume == value )
				return;

			_volume = value;

			updateStereo();
		}

		public function get panning(): Number
		{
			return _panning;
		}

		public function set panning( value: Number ): void
		{
			if( _panning == value )
				return;

			_panning = value;

			updateStereo();
		}

		private function updateStereo(): void
		{
			_gainL = Math.sqrt( ( 1.0 - _panning ) * 0.5 ) * _volume;
			_gainR = Math.sqrt( ( _panning + 1.0 ) * 0.5 ) * _volume;
		}

		public function processAudio( buffer: Buffer, numSamples: int ): void
		{
			if( null == _state.waveForm || mute )
				return;

			for( _position = 0 ; _position < numSamples ; )
			{
				buffer = processCycle( buffer, numSamples - _position );

				if( _cycleComplete )
				{
					_state.processCycleComplete();

					_cycleComplete = false;

					if( null == _state.waveForm )
						return;
				}
			}
		}

		private function processCycle( buffer: Buffer, n: int ): Buffer
		{
			const rate: Number = _state.waveSpeed / _player.samplingRate;
			const form: Vector.<Number> = _state.waveForm;
			const start: int = _state.waveStart;
			const length: int = _state.waveLength;

			const gain: Number = _state.gain;
			const multL: Number = _gainL * gain;
			const multR: Number = _gainR * gain;

			for( var i: int = 0 ; i < n ; ++i )
			{
				const amp: Number = form[ int( start + _state.wavePhase ) ];

				buffer.l += amp * multL;
				buffer.r += amp * multR;
				buffer = buffer.next;

				++_position;
				_state.wavePhase += rate;

				if( _state.wavePhase > length )
				{
					_cycleComplete = true;
					return buffer;
				}
			}

			return buffer;
		}
	}
}