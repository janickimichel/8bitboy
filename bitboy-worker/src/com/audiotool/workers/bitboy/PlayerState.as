package com.audiotool.workers.bitboy
{
	internal final class PlayerState
	{
		private var _channelStates: Vector.<ChannelState>;
		private var _format: Format;

		private var _loopMode: Boolean;
		private var _bpm: Number;
		private var _speed: int;

		private var _tickIndex: int;
		private var _stepIndex: int;
		private var _patternIndex: int;
		private var _incrementPatternIndex: Boolean;

		private var _complete: Boolean;
		private var _lastRow: Boolean;
		private var _idle: Boolean;
		private var _loop: Boolean;

		public function PlayerState()
		{
			_channelStates = new Vector.<ChannelState>( Player.NumChannels, true );
			_channelStates[0] = new ChannelState( this );
			_channelStates[1] = new ChannelState( this );
			_channelStates[2] = new ChannelState( this );
			_channelStates[3] = new ChannelState( this );
		}

		public function set format( value: Format ): void
		{
			if( _format == value )
				return;

			if( null == value )
				return;

			_format = value;
		}

		public function get running(): Boolean
		{
			if( _complete )
				_idle = true;

			return !_idle;
		}

		public function set loopMode( value: Boolean ): void
		{
			_loopMode = value;
		}

		public function get loopMode(): Boolean
		{
			return _loopMode;
		}

		public function processTick(): void
		{
			if( --_tickIndex <= 0 )
			{
				if( _lastRow )
					_complete = true;
				else
					nextStep();
			}
			else
			{
				for each( var channel: ChannelState in _channelStates )
					channel.processTick( _tickIndex );
			}
		}

		public function reset(): void
		{
			bpm = Player.DefaultBpm;
			speed = Player.DefaultSpeed;

			_tickIndex = 0;
			_stepIndex = 0;
			_patternIndex = 0;

			_complete = false;
			_lastRow = false;
			_idle = false;
			_loop = false;
			_incrementPatternIndex = false;

			for each( var channel: ChannelState in _channelStates )
				channel.reset();
		}

		public function patternJump( index: int ): void
		{
			if( index <= _patternIndex )
				_loop = true;

			_patternIndex = index;

			_stepIndex = 0;
		}

		public function patternBreak( value: int ): void
		{
			_stepIndex = value;

			_incrementPatternIndex = true;
		}

		public function get stepIndex(): int
		{
			return _stepIndex;
		}

		public function set stepIndex( value: int ): void
		{
			_stepIndex = value;
		}

		public function set bpm( value: Number ): void
		{
			_bpm = value;
		}

		public function get bpm(): Number
		{
			return _bpm;
		}

		public function set speed( value: int ): void
		{
			_speed = value;
		}

		public function get channelStates(): Vector.<ChannelState>
		{
			return _channelStates;
		}

		public function get lastRow(): Boolean
		{
			return _lastRow;
		}

		public function get loop(): Boolean
		{
			return _loop;
		}

		public function get speed(): int
		{
			return _speed;
		}

		public function get complete(): Boolean
		{
			return _complete;
		}

		internal function nextStep(): void
		{
			const patternIndex: int = _patternIndex;
			const rowIndex: int = _stepIndex++;

			_incrementPatternIndex = false;

			for( var index: int = 0 ; index < Player.NumChannels ; ++index )
			{
				_channelStates[ index ].processStep(
					_format.getStepAt(
						_format.getSequenceAt( patternIndex ), rowIndex, index ) );
			}

			if( _incrementPatternIndex )
			{
				nextPattern();
			}
			else
			if( _stepIndex == _format.getPatternLength( _format.getSequenceAt( patternIndex ) ) )
			{
				_stepIndex = 0;
				nextPattern();
			}

			_tickIndex = _speed;
		}

		private function nextPattern(): void
		{
			if( ++_patternIndex == _format.sequenceLength )
			{
				if( _loopMode )
					_patternIndex = 0;
				else
					_lastRow = true;
			}
		}
	}
}