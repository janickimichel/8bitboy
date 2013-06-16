package com.audiotool.workers.bitboy
{
	/**
	 * @author Andre Michelle
	 */
	public final class FormatInfo
	{
		public static function fromJSON( json: String ): FormatInfo
		{
			const object: Object = JSON.parse( json );

			return new FormatInfo( object['title'], object['credits'], object['duration'] );
		}

		private var _title: String;
		private var _credits: Array;
		private var _duration: Number;

		public function FormatInfo( title: String, credits: Array, duration: Number )
		{
			_title = title;
			_credits = credits;
			_duration = duration;
		}

		public function get title(): String
		{
			return _title;
		}

		public function get credits(): Array
		{
			return _credits;
		}

		public function get duration(): Number
		{
			return _duration;
		}

		public function toJSON( index: int = 0 ): Object
		{
			return {
				"title": _title,
				"credits": _credits,
				"duration": _duration
			};
		}

		public function toString(): String
		{
			return '[FormatInfo' +
					' title: ' + _title +
					', credits: ' + _credits +
					', duration: ' + _duration.toFixed(1) +
					']';
		}
	}
}