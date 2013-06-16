package com.audiotool.workers.bitboy
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.system.WorkerDomain;
	import flash.system.WorkerState;
	import flash.utils.ByteArray;

	public final class Bitboy implements PlayerCommands
	{
		private var owner: BitboyOwner;

		private var worker: Worker;
		private var commandChannel: MessageChannel;
		private var backChannel: MessageChannel;

		public function Bitboy( owner: BitboyOwner )
		{
			this.owner = owner;
		}

		public function loadWorkerSWF( request: URLRequest ): void
		{
			const loader: URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			registerListeners( loader );

			try
			{
				loader.load( request );
			}
			catch( error: Error )
			{
				owner.onBitboyError( error );
			}
		}

		public function isReady(): Boolean
		{
			return worker.state == WorkerState.RUNNING;
		}

		public function setBufferSize( length: int ): void
		{
			send( Command.BufferSize, length );
		}

		public function setSamplingRateShift( shift: int ): void
		{
			send( Command.SamplingRateShift, shift );
		}

		public function setFormat( bytes: ByteArray ): void
		{
			send( Command.Format, bytes );
		}

		public function start(): void
		{
			send( Command.Start );
		}

		public function stop(): void
		{
			send( Command.Stop );
		}

		public function setPause( value: Boolean ): void
		{
			send( Command.Pause, value );
		}

		public function setVolume( value: Number ): void
		{
			send( Command.Volume, value );
		}

		public function setLoopMode( value: Boolean ): void
		{
			send( Command.LoopMode, value );
		}

		public function setChannelVolume( index: int, volume: Number ): void
		{
			send( Command.ChannelVolume, index, volume );
		}

		public function setChannelPanning( index: int, panning: Number ): void
		{
			send( Command.ChannelPanning, index, panning );
		}

		public function setChannelMute( index: int, mute: Boolean ): void
		{
			send( Command.ChannelMute, index, mute );
		}

		private function onWorkerState( event: Event ): void
		{
			if( isReady() )
			{
				owner.onBitboyReady();
			}
		}

		private function onWorkerToMain( event: Event ): void
		{
			const receive: * = backChannel.receive();

			if( receive is Array )
				processEvent( receive as Array );
		}

		private function processEvent( event: Array ): void
		{
			const op: int = event[0];
			const arguments: Array = event.slice(1);

			switch( op )
			{
				case Events.Error:
					owner.onBitboyError( new Error( arguments[0] ) );
					break;

				case Events.FormatInfo:
					owner.onBitboyFormatInfo( FormatInfo.fromJSON( arguments[0] ) );
					break;
			}
		}

		private function send( op: int, ...arguments ): void
		{
			arguments.unshift( op );

			commandChannel.send( arguments );
		}

		private function onLoaderError( event: ErrorEvent ): void
		{
			unregisterListeners( URLLoader( event.target ) );

			owner.onBitboyError( new Error( event.text, event.errorID ) );
		}

		private function onLoaderComplete( event: Event ): void
		{
			unregisterListeners( URLLoader( event.target ) );

			const loader: URLLoader = URLLoader( event.target );

			worker = WorkerDomain.current.createWorker( loader.data );
			worker.addEventListener( Event.WORKER_STATE, onWorkerState );

			backChannel = worker.createMessageChannel( Worker.current );
			backChannel.addEventListener( Event.CHANNEL_MESSAGE, onWorkerToMain );

			commandChannel = Worker.current.createMessageChannel( worker );

			worker.setSharedProperty( SharedProperty.BackChannel, backChannel );
			worker.setSharedProperty( SharedProperty.CommandChannel, commandChannel );
			worker.start();
		}

		private function registerListeners( loader: URLLoader ): void
		{
			loader.addEventListener( Event.COMPLETE, onLoaderComplete );
			loader.addEventListener( IOErrorEvent.IO_ERROR, onLoaderError );
			loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onLoaderError );
		}

		private function unregisterListeners( loader: URLLoader ): void
		{
			loader.removeEventListener( Event.COMPLETE, onLoaderComplete );
			loader.removeEventListener( IOErrorEvent.IO_ERROR, onLoaderError );
			loader.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, onLoaderError );
		}
	}
}