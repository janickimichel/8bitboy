package com.audiotool.workers.bitboy
{
	/**
	 * @author Andre Michelle
	 */
	internal final class EffectType
	{
		public static const ARPEGGIO: int = 0x0;
		public static const PORTAMENTO_UP: int = 0x1;
		public static const PORTAMENTO_DN: int = 0x2;
		public static const TONE_PORTAMENTO: int = 0x3;
		public static const VIBRATO: int = 0x4;
		public static const TONE_PORTAMENTO_VOLUME_SLIDE: int = 0x5;
		public static const VIBRATO_VOLUME_SLIDE: int = 0x6;
		public static const TREMOLO: int = 0x7;
		public static const SET_PANNING: int = 0x8;
		public static const SAMPLE_OFFSET: int = 0x9;
		public static const VOLUME_SLIDE: int = 0xa;
		public static const POSITION_JUMP: int = 0xb;
		public static const SET_VOLUME: int = 0xc;
		public static const PATTERN_BREAK: int = 0xd;
		public static const EXTENDED_EFFECTS: int = 0xe;
		public static const SET_SPEED: int = 0xf;
	}
}