# Setup #

Compile the sources or download [bitboy-1.0.swc](http://8bitboy.popforge.de/worker/bitboy-1.0.swc) and include it in your project.

The following code should work instantly.

```
package
{
	import com.audiotool.workers.bitboy.Bitboy;
	import com.audiotool.workers.bitboy.BitboyOwner;
	import com.audiotool.workers.bitboy.FormatInfo;

	import flash.display.Sprite;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;

	/**
	 * @author Andre Michelle
	 */
	public final class MyApp extends Sprite implements BitboyOwner
	{
		private var bitboy: Bitboy;

		public function WorkerApp()
		{
			bitboy = new Bitboy( this );
			bitboy.loadWorkerSWF( new URLRequest( "http://8bitboy.popforge.de/worker/bitboy-worker-1.0.swf" ) );
		}

		public function onBitboyReady(): void
		{
			loadMod();
		}

		public function onBitboyFormatInfo( formatInfo: FormatInfo ): void
		{
			trace( formatInfo );
		}

		public function onBitboyError( error: Error ): void
		{
			throw error;
		}

		private function loadMod(): void
		{
			const loader: URLLoader = new URLLoader();
			addListeners( loader );

			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.load( new URLRequest( "http://8bitboy.popforge.de/mod/emax-delicate_oooz!.mod" ) );
		}

		private function onLoaderComplete( event: Event ): void
		{
			const loader: URLLoader = URLLoader( event.target );
			removeListeners( loader );

			bitboy.setBufferSize( 2048 );
			bitboy.setSamplingRateShift( 0 );
			bitboy.setLoopMode( true );
			bitboy.setChannelPanning( 0, -0.5 );
			bitboy.setChannelPanning( 1,  0.5 );
			bitboy.setChannelPanning( 2,  0.5 );
			bitboy.setChannelPanning( 3, -0.5 );
			bitboy.setFormat( loader.data );
			bitboy.start();
		}

		private function onLoaderError( event: ErrorEvent ): void
		{
			const loader: URLLoader = URLLoader( event.target );
			removeListeners( loader );

			trace( event );
		}

		private function addListeners( loader: URLLoader ): void
		{
			loader.addEventListener( Event.COMPLETE, onLoaderComplete );
			loader.addEventListener( IOErrorEvent.IO_ERROR, onLoaderError );
			loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onLoaderError );
		}

		private function removeListeners( loader: URLLoader ): void
		{
			loader.removeEventListener( Event.COMPLETE, onLoaderComplete );
			loader.removeEventListener( IOErrorEvent.IO_ERROR, onLoaderError );
			loader.removeEventListener( SecurityErrorEvent.SECURITY_ERROR, onLoaderError );
		}
	}
}
```