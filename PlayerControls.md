
```
	public interface PlayerCommands
	{
		/**
		 * Parses and sets a mod format.
		 *
		 * @param bytes The bytes containing the mod format.
		 */
		function setFormat( bytes: ByteArray ): void;

		/**
		 * Starts the sound object.
		 */
		function start(): void;

		/**
		 * Stops the sound object.
		 */
		function stop(): void;


		/**
		 * Sets the pause state.
		 */
		function setPause( value: Boolean ): void;

		/**
		 * Sets the buffer size. Default value is 2048 samples to aim the lowest latency.
		 *
		 * @param size The number of samples to be written in the buffer.
		 */
		function setBufferSize( size: int ): void;

		/**
		 * Allows to set a lower samplingRate starting with the Flash samplingRate.
		 *
		 * @param shift Pass 0 for 44.1KHz, 1 for 22.05KHz (Original Amiga), and so on.
		 */
		function setSamplingRateShift( shift: int ): void;

		/**
		 * Sets the volume of the player.
		 *
		 * @param value The value between zero and one.
		 */
		function setVolume( value: Number ): void;

		/**
		 * Allows to set the loop mode. Already looped mod-songs are unaffected.
		 *
		 * @param value True, if the song should be looped.
		 */
		function setLoopMode( value: Boolean ): void;

		/**
		 * Sets the volume of one of the four channels.
		 *
		 * @param index The index of the channel.
		 * @param volume The value between zero and one.
		 */
		function setChannelVolume( index: int, volume: Number ): void;

		/**
		 * Sets the panning of one of the four channels.
		 *
		 * @param index The index of the channel.
		 * @param panning The value between minus one (left) and one (right).
		 */
		function setChannelPanning( index: int, panning: Number ): void;

		/**
		 * Mutes one of the four channels.
		 *
		 * @param index The index of the channel.
		 * @param mute If muted, the channel will not be audible.
		 */
		function setChannelMute( index: int, mute: Boolean ): void;
	}
```