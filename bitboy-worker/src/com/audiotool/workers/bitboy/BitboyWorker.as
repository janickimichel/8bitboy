package com.audiotool.workers.bitboy
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.MessageChannel;
	import flash.system.Worker;

	/**
	 * @author Andre Michelle
	 */
	[SWF(width='1',height='1',backgroundColor='0x000000',frameRate='60',scriptTimeLimit='10')]
	public final class BitboyWorker extends Sprite
	{
		private var player: Player;
		private var backChannel: MessageChannel;
		private var commandChannel: MessageChannel;

		public function BitboyWorker()
		{
			player = new Player();

			backChannel = Worker.current.getSharedProperty( SharedProperty.BackChannel ) as MessageChannel;

			commandChannel = Worker.current.getSharedProperty( SharedProperty.CommandChannel ) as MessageChannel;
			commandChannel.addEventListener( Event.CHANNEL_MESSAGE, onCommandReceived );
		}

		private function onCommandReceived( event: Event ): void
		{
			const receive: * = commandChannel.receive();

			if( receive is Array )
				executeCommand( receive as Array );
			else
				send( Events.Error, receive );
		}

		private function executeCommand( command: Array ): void
		{
			const op: int = command[0];
			const arguments: Array = command.slice(1);

			switch( op )
			{
				case Command.BufferSize:
					player.setBufferSize( arguments[0] );
					break;

				case Command.SamplingRateShift:
					player.setSamplingRateShift( arguments[0] );
					break;

				case Command.Format:
					player.setFormat( arguments[0] );
					if( null != player.formatInfo )
						send( Events.FormatInfo, JSON.stringify( player.formatInfo.toJSON() ) );
					break;

				case Command.Start:
					player.start();
					break;

				case Command.Stop:
					player.stop();
					break;

				case Command.Pause:
					player.setPause( arguments[0] );
					break;

				case Command.Volume:
					player.setVolume( arguments[0] );
					break;

				case Command.LoopMode:
					player.setLoopMode( arguments[0] );
					break;

				case Command.ChannelVolume:
					player.setChannelVolume( arguments[0], arguments[1] );
					break;

				case Command.ChannelPanning:
					player.setChannelPanning( arguments[0], arguments[1] );
					break;

				case Command.ChannelMute:
					player.setChannelMute( arguments[0], arguments[1] );
					break;

				default:
					send( Events.Error, op );
					break;
			}
		}

		private function send( op: int, ...arguments ): void
		{
			arguments.unshift( op );

			backChannel.send( arguments );
		}
	}
}