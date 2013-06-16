package com.audiotool.workers.bitboy
{
	/**
	 * @author Andre Michelle
	 */
	public interface BitboyOwner
	{
		function onBitboyReady(): void;

		function onBitboyFormatInfo( formatInfo: FormatInfo ): void;

		function onBitboyError( error: Error ): void;
	}
}