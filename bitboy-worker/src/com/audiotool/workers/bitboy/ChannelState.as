package com.audiotool.workers.bitboy
{
	internal final class ChannelState
	{
		private var _state: PlayerState;
		private var _currentStep: Step;

		/* PITCH */
		private var _tone: int;
		private var _period: Number;

		/* EFFECT */
		private var _effect: int;
		private var _effectParam: int;

		internal var waveForm: Vector.<Number>;
		internal var wavePhase: Number;
		internal var waveStart: int;
		internal var waveLength: int;

		private var _firstRun: Boolean;
		private var _volume: int;
		
		private var _volumeSlide: int;
		private var _portamentoSpeed: int;
		private var _tonePortamentoSpeed: int = 0;
		private var _tonePortamentoPeriod: int;
		private var _vibratoSpeed: int;
		private var _vibratoDepth: int;
		private var _vibratoPosition: int;
		private var _vibratoOffset: int;
		private var _arpeggio1: int;
		private var _arpeggio2: int;

		//-- EXT EFFECT
		private var _patternFirstRun: Boolean;
		private var _patternFirstRunCount: int;
		private var _patternFirstRunPosition: int;

		public function ChannelState( state: PlayerState )
		{
			_state = state;
		}

		public function processCycleComplete(): void
		{
			if( _firstRun )
			{
				const sample: Sample = _currentStep.sample;

				if( null == sample || 0 == sample.repeatLength ) // one shot
				{
					waveForm = null;
					return;
				}

				waveStart = sample.repeatStart;
				waveLength = sample.repeatLength;
				_firstRun = false;
			}

			wavePhase %= waveLength;
		}

		public function get waveSpeed(): Number
		{
			// NTSC machine clock (Magic Number)
			return ( 7159090.5 * 0.5 ) / ( _period + _vibratoOffset );
		}

		public function get gain(): Number
		{
			return _volume / 128.0;
		}
		
		public function reset(): void
		{
			waveForm = null;
			wavePhase = 0.0;

			_firstRun = false;
			_volume = 0;
			_currentStep = null;
			
			_patternFirstRun = false;
			_patternFirstRunCount = 0;
			_patternFirstRunPosition = 0;
			
			_volumeSlide = 0;
			_portamentoSpeed = 0;
			_tonePortamentoSpeed = 0;
			_tonePortamentoPeriod = 0;
			_vibratoSpeed = 0.0;
			_vibratoDepth = 0.0;
			_vibratoPosition = 0.0;
			_vibratoOffset = 0.0;
			
			_effect = 0;
			_effectParam = 0;
		}
		
		public function processStep( step: Step ): void
		{
			_currentStep = step;

			updateWave();
			
			if( step.effect == EffectType.TONE_PORTAMENTO  )
			{
				initTonePortamento();
			}
			else
			if( step.period > 0 )
			{
				_period = step.period;
				_tone = Table.Tone.indexOf( _period );
				_tonePortamentoPeriod = _period; // fix for 'delicate.mod'
			}
			
			initEffect();
		}
		
		public function processTick( tick: int ): void
		{
			switch( _effect )
			{
				case EffectType.ARPEGGIO:
				
					updateArpeggio( tick % 3 );
					break;
				
				case EffectType.PORTAMENTO_UP:
				case EffectType.PORTAMENTO_DN:
				
					updatePortamento();
					break;
				
				case EffectType.TONE_PORTAMENTO:
				
					updateTonePortamento();
					break;
					
				case EffectType.TONE_PORTAMENTO_VOLUME_SLIDE:
					
					updateTonePortamento();
					updateVolumeSlide();
					break;
				
				case EffectType.VOLUME_SLIDE:
				
					updateVolumeSlide();
					break;
				
				case EffectType.VIBRATO:
					
					updateVibrato();
					break;
				
				case EffectType.VIBRATO_VOLUME_SLIDE:

					updateVibrato();
					updateVolumeSlide();
					break;
				
				case EffectType.EXTENDED_EFFECTS:

					var extEffect: int = _effectParam >> 4;
					var extParam: int = _effectParam & 0xf;
				
					switch ( extEffect )
					{
						case 0x9: //-- retrigger note
							if ( tick % extParam == 0 )
								wavePhase = 0.0;
							break;
						
						case 0xc: //-- cut note
							waveForm = null;
							break;
					}

					break;
			}
		}

		private function initEffect(): void
		{
			_effect = _currentStep.effect;
			_effectParam = _currentStep.effectParam;

			if( _effect != EffectType.VIBRATO && _effect != EffectType.VIBRATO_VOLUME_SLIDE )
				_vibratoOffset = 0;

			switch( _effect )
			{
				case EffectType.ARPEGGIO:
				
					if( _effectParam > 0 )
						initArpeggio();
					else
						_volumeSlide = 0; // no effect here, reset some values
					break;
				
				case EffectType.PORTAMENTO_UP:
				
					initPortamento( -_effectParam );
					break;
				
				case EffectType.PORTAMENTO_DN:
				
					initPortamento( _effectParam );
					break;
					
				case EffectType.TONE_PORTAMENTO:
					break;
				
				case EffectType.VIBRATO:
					if ( _currentStep.sample != null )
						_volume = _currentStep.sample.volume;
					initVibrato();
					break;

				case EffectType.VIBRATO_VOLUME_SLIDE:

					/*This is a combination of Vibrato (4xy), and volume slide (Axy).
					The parameter does not affect the vibrato, only the volume.
					If no parameter use the vibrato parameters used for that channel.*/
					initVolumeSlide();
					break;
			
				case EffectType.EXTENDED_EFFECTS:
				
					var extEffect: int = _effectParam >> 4;
					var extParam: int = _effectParam & 0xf;
				
					switch ( extEffect )
					{
						case 0x6: //-- pattern firstRun
							
								if( extParam == 0 )
									_patternFirstRunPosition = _state.stepIndex - 1;
								else
								{
									if( !_patternFirstRun )
									{
										_patternFirstRunCount = extParam;
										_patternFirstRun = true;
									}
									
									if( --_patternFirstRunCount >= 0 )
										_state.stepIndex = _patternFirstRunPosition;
									else
										_patternFirstRun = false;
								}
								break;
						
						case 0x9: //-- retrigger note

							wavePhase = 0.0;
							break;
						
						case 0xc: //-- cut note

							if( extParam == 0 )
								waveForm = null;
							break;
						
						default:
				
							trace( 'extended effect: ' + extEffect + ' is not defined.' );
							break;
					}

					break;
				
				case EffectType.TONE_PORTAMENTO_VOLUME_SLIDE:
				case EffectType.VOLUME_SLIDE:
				
					initVolumeSlide();
					break;
				
				case EffectType.SET_VOLUME:
				
					_volumeSlide = 0;
					_volume = _effectParam;
					break;

				case EffectType.POSITION_JUMP:
				
					_state.patternJump( _effectParam );
					break;

				case EffectType.PATTERN_BREAK:

					_state.patternBreak( parseInt( _effectParam.toString( 16 ) ) );
					break;

				case EffectType.SET_SPEED:
				
					if( _effectParam > 32 )
						_state.bpm = _effectParam;
					else
						_state.speed = _effectParam;
					break;
				
				default:
					trace( '_effect: ' + _effect + ' is not defined.' );
					break;
			}
		}
		
		private function updateWave(): void
		{
			const sample: Sample = _currentStep.sample;

			if( sample == null || _currentStep.period <= 0 )
				return;

			_volume = sample.volume;
			waveForm = sample.wave;
			waveStart = 0;
			waveLength = waveForm.length;
			wavePhase = 0.0;
			_firstRun = true;
		}

		private function initArpeggio(): void
		{
			_arpeggio1 = Table.Tone[ _tone + ( _effectParam >> 4 ) ];
			_arpeggio2 = Table.Tone[ _tone + ( _effectParam & 0xf ) ];
		}
		
		private function updateArpeggio( index: int ): void
		{
			if( 0 == _effectParam )
				return;

			if( index == 1 )
				_period = _arpeggio2;
			else
			if( index == 2 )
				_period = _arpeggio1;
		}
		
		private function initVolumeSlide(): void
		{
			if( null != _currentStep.sample )
				_volume = _currentStep.sample.volume;

			_volumeSlide =  _effectParam >> 4;
			_volumeSlide -= _effectParam & 0xf;
		}
		
		private function updateVolumeSlide(): void
		{
			const value: int = _volume + _volumeSlide;
			_volume = 0 > value ? 0 : 64 < value ? 64 : value;
		}
		
		private function initTonePortamento(): void
		{
			if( _currentStep.effectParam > 0 )
			{
				_tonePortamentoSpeed = _currentStep.effectParam;
				if( _currentStep.period > 0 )
					_tonePortamentoPeriod = _currentStep.period;
			}
		}
		
		private function updateTonePortamento(): void
		{
			if( _period > _tonePortamentoPeriod )
			{
				_period -= _tonePortamentoSpeed;
				if( _period < _tonePortamentoPeriod )
					_period = _tonePortamentoPeriod;
			}
			else
			if( _period < _tonePortamentoPeriod )
			{
				_period += _tonePortamentoSpeed;
				if( _period > _tonePortamentoPeriod )
					_period = _tonePortamentoPeriod;
			}
		}
		
		private function initPortamento( value: int ): void
		{
			_portamentoSpeed = value;
		}
		
		private function updatePortamento(): void
		{
			_period += _portamentoSpeed;
		}
		
		private function initVibrato(): void
		{
			if( 0 == _effectParam )
				return;

			_vibratoSpeed = _effectParam >> 4;
			_vibratoDepth = _effectParam & 0xf;
			_vibratoPosition = 0;
		}
		
		private function updateVibrato(): void
		{
			_vibratoPosition += _vibratoSpeed;
			_vibratoOffset = Math.floor( Table.Sine[ _vibratoPosition % Table.Sine.length ] * _vibratoDepth / 128 );
		}
	}
}