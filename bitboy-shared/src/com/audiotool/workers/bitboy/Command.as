package com.audiotool.workers.bitboy
{
	/**
	 * @author Andre Michelle
	 */
	public final class Command
	{
		public static const Format: int = __++;
		public static const BufferSize: int = __++;
		public static const SamplingRateShift: int = __++;
		public static const Start: int = __++;
		public static const Stop: int = __++;
		public static const Pause: int = __++;
		public static const Volume: int = __++;
		public static const LoopMode: int = __++;
		public static const ChannelVolume: int = __++;
		public static const ChannelPanning: int = __++;
		public static const ChannelMute: int = __++;

		private static var __: int = -1;
	}
}