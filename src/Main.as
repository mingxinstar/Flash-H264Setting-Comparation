package 
{
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.media.Camera;
	import flash.media.H264Level;
	import flash.media.H264Profile;
	import flash.media.H264VideoStreamSettings;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import com.adobe.crypto.MD5;
	import flash.utils.Timer;

	
	[SWF( width="1680", height="880" )]
	public class Main extends Sprite
	{
		private var metaText:TextField = new TextField();
		private var vid_outDescription:TextField = new TextField();
		private var vid_inDescription:TextField = new TextField();
		private var metaTextTitle:TextField = new TextField();
		
		//Define a NetConnection variable nc
		private var nc:NetConnection;
		private var nc_in:NetConnection;
		//Define two NetStream variables, ns_in and ns_out
		private var ns_in:NetStream;
		private var ns_out:NetStream;
		//Define a Camera variable cam
		private var cam:Camera = Camera.getCamera("0");
		//Define a Video variable named vid_out
		private var vid_out:Video;
		//Define a Video variable named vid_in
		private var vid_in:Video;
		
		private var hexUrl:String = "an api to get hex time from server if needed";
		private var roomId:String = "111111";
		private var tkey:String = "secret key if needed";
		private var pushUrl:String = "your push url";
		private var pullUrl:String = "your pull url";
		private var currSteamName:String;
		
		// some default configs
		private var configs:Object = {
			config_1 : {
				bandWidth : 90000,
				quality : 90,
				width : 640,
				height : 480,
				fps : 15,
				keyInterval : 15,
				profile : H264Profile.BASELINE,
				level : H264Level.LEVEL_3_1
			},
			config_2 : {
				width:640, 
				height:480,
				quality :100,
				fps:15, 
				keyIntervalL:15,
				bandWidth:60000,
				profile : H264Profile.BASELINE,
				level : H264Level.LEVEL_3_1
			},
			config_3 : {
				bandWidth : 0,
				quality : 80,
				width : 640,
				height : 480,
				fps : 15,
				keyInterval : 15,
				profile : H264Profile.BASELINE,
				level : H264Level.LEVEL_3_1
			},
			config_4 : { 
				bandWidth : 0,
				quality : 85,
				width : 640,
				height : 480,
				fps : 60,
				keyInterval : 60,
				profile : H264Profile.MAIN,
				level : H264Level.LEVEL_5_1
			}
		};
		private var currVideoConfig:Object = configs.config_4;
		
		
		//Class constructor
		public function Main()
		{	
			trace(Camera.names, Camera.names[0]);
			getStreamName(initConnection);
		}
		
		private function ajax (url:String, callback:Function):void {
			var request:URLRequest = new URLRequest(url);
			var loader:URLLoader = new URLLoader(request);
			
			loader.addEventListener(Event.COMPLETE, function (event:Event):void {
				var data:Object = JSON.parse(event.target.data);
				
				if (typeof(callback) === "function") {
					callback(data);
				}
			});
		}
		
		private function getStreamName (callback:Function=null):void {
			ajax(hexUrl, function (data:Object):void {
				var hexTime:String = data.data;
				var videoName:String = roomId + "?k=" + MD5.hash(tkey + "/meme/" +roomId + hexTime) + "&t=" + hexTime;
				
				trace(videoName);
				
				currSteamName = videoName;
				
				if (callback !== null) {
					callback();
				}
			});
		}
		
		//Called from class constructor, this function establishes a new NetConnection and listens for its status
		private function initConnection():void
		{
			//Create a new NetConnection by instantiating nc
			nc = new NetConnection();
			//Add an EventListener to listen for onNetStatus()
			nc.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			//Connect to the live folder on the server
			nc.connect(pushUrl);
			//nc.connect("rtmp://YOUR_SERVER_URL/live");
			//Tell the NetConnection where the server should invoke callback methods
			nc.client = this;
			
			//Instantiate the vid_out variable, set its location in the UI, and add it to the stage
			vid_out = new Video();
			vid_out.width = currVideoConfig.width;
			vid_out.height = currVideoConfig.height;
			vid_out.x = 400; 
			vid_out.y = 10;
			addChild( vid_out );
			
			//Instantiate the vid_in variable, set its location in the UI, and add it to the stage
			vid_in = new Video();
			vid_in.x = vid_out.x + vid_out.width; 
			vid_in.y = vid_out.y;
			vid_in.width = vid_out.width;
			vid_in.height = vid_out.height;
			addChild( vid_in );
		}
		
		private function initInConnection():void {
			trace("init in connection");
			nc_in = new NetConnection();
			nc_in.addEventListener(NetStatusEvent.NET_STATUS, onNetInStatus);
			nc_in.connect(pullUrl);
			nc_in.client = this;
		}
		
		//It's a best practice to always check for a successful NetConnection
		protected function onNetStatus(event:NetStatusEvent):void
		{
			//Trace the value of event.info.code
			trace( event.info.code );
			/*Check for a successful NetConnection, and if successful
			call publishCamera(), displayPublishingVideo(), and displayPlaybackVideo()*/
			if( event.info.code == "NetConnection.Connect.Success" )
			{ 
				publishCamera(); 
				displayPublishingVideo(); 
				
				var connectInStreamTimer:Timer = new Timer(2000, 1);
				connectInStreamTimer.addEventListener(TimerEvent.TIMER, function (event:TimerEvent) {
					initInConnection();
				});
				connectInStreamTimer.start();
			}
		}
		
		protected function onNetInStatus(event:NetStatusEvent):void {
			trace("nc_in connection : ", event.info.code);
			
			if (event.info.code === "NetConnection.Connect.Success") {
				displayPlaybackVideo();
			}
		}
		
		public function onMetaData ():void {
			//trace("in onMetaData : ", JSON.stringify(data));
		}
		
		//The encoding settings are set on the publishing stream
		protected function publishCamera():void
		{
			//Instantiate the ns_out NetStream
			ns_out = new NetStream( nc );
			//Attach the camera to the outgoing NetStream
			ns_out.attachCamera( cam );
			//Define a local variable named h264Settings of type H264VideoStreamSettings
			var h264Settings:H264VideoStreamSettings = new H264VideoStreamSettings();
			//Set encoding profile and level on h264Settings
			h264Settings.setProfileLevel( currVideoConfig.profile, currVideoConfig.level);
			
			//Set the bitrate and quality settings on the Camera object
			trace('camera : ', cam.name);
			cam.setQuality( currVideoConfig.bandWidth, currVideoConfig.quality );
			//Set the video's height, width, fps, and whether it should maintain its capture size
			cam.setMode( currVideoConfig.width, currVideoConfig.height, currVideoConfig.fps, true);
			//Set the keyframe interval
			cam.setKeyFrameInterval( currVideoConfig.keyInterval );
			
			//Set the outgoing video's compression settings based on h264Settings
			ns_out.videoStreamSettings = h264Settings;
			//Set the outgoing strem listener
			ns_out.addEventListener(NetStatusEvent.NET_STATUS, handleStreamStatus);
			//Publish the outgoing stream
			ns_out.publish( currSteamName, "live" );
			
			//Declare the metadata variable
			var metaData:Object = new Object();
			//Give the metadata object properties to reflect the stream's metadata
			metaData.codec = ns_out.videoStreamSettings.codec;
			metaData.profile =  h264Settings.profile;
			metaData.level = h264Settings.level;
			metaData.fps = cam.fps;
			metaData.currentFPS = cam.currentFPS;
			metaData.bandwith = cam.bandwidth;
			metaData.height = cam.height;
			metaData.width = cam.width;
			metaData.keyFrameInterval = cam.keyFrameInterval;
			//Call send() on the ns_out NetStream, Only works on flash media server
			//ns_out.send( "@setDataFrame", "onMetaData", metaData );
			showMetaData(metaData);
			trackStreamInfo();
		}
		
		protected function handleStreamStatus(event:NetStatusEvent):void {
			trace("stream status :", event.info.code);
		}
		
		//Display the outgoing video stream in the UI
		protected function displayPublishingVideo():void
		{
			//Attach the incoming video stream to the vid_out component
			vid_out.attachCamera( cam );
		}
		
		
		//Display the incoming video stream in the UI
		protected function displayPlaybackVideo():void
		{
			//Instantiate the ns_in NetStream
			ns_in = new NetStream( nc_in );
			ns_in.addEventListener(NetStatusEvent.NET_STATUS, handleStreamStatus);
			//Set the client property of ns_in to "this"
			ns_in.client = this;
			//Play the NetStream
			ns_in.play( currSteamName );
			//Attach the incoming video to the incoming NetStream (ns_in)
			vid_in.attachNetStream( ns_in ); 
		}
		
		//Necessary callback function that checks bandwith (remains empty in this case)
		public function onBWDone():void
		{
		}
		
		private var totalBandWidth:Number = 0;
		private var trackTime:Number = 0;
		
		private function trackStreamInfo ():void {
			var trackTimer:Timer = new Timer(1000, 60);
			trackTimer.addEventListener(TimerEvent.TIMER, function (event:TimerEvent):void {
				var currBandWidth:Number = Math.floor(ns_out.info.currentBytesPerSecond / 100);
				totalBandWidth += currBandWidth;
				trackTime ++;
				var avaBandWidth:Number = Math.floor(totalBandWidth / trackTime);
				metaText.appendText("\n" + "current bandWidth : " + currBandWidth + " Kbps avarage bandWidth : " + avaBandWidth +" Kbps \n");
				trace("trackTime : ", trackTime, trackTime === 60);
				if (trackTime === 60) {
					trace("end");
					metaText.appendText("\n");
					metaText.appendText("=================END=================");
				}
				metaText.scrollV = metaText.maxScrollV;
			});
			trackTimer.start();
		}
		
		//Display stream metadata and lays out visual components in the UI
		public function showMetaData(metaData:Object):void	
		{			
			metaText.x = 0;
			metaText.y = 55;
			metaText.width = 400;
			metaText.height = 880;
			metaText.background = true;
			metaText.backgroundColor = 0x1F1F1F;
			metaText.textColor = 0xD9D9D9;
			metaText.border = true;
			metaText.borderColor = 0xDD7500;
			addChild( metaText );
			
			metaTextTitle.text = "\n             - Encoding Settings -";
			var stylr:TextFormat = new TextFormat();
			stylr.size = 18;
			metaTextTitle.setTextFormat( stylr );
			metaTextTitle.textColor = 0xDD7500;
			metaTextTitle.width = 400;
			metaTextTitle.y = 10;
			metaTextTitle.height = 50;
			metaTextTitle.background = true;
			metaTextTitle.backgroundColor = 0x1F1F1F;
			metaTextTitle.border = true;
			metaTextTitle.borderColor = 0xDD7500;
			
			vid_outDescription.text = "\n\n\n\n                 Live video from webcam \n\n" +
			"	            Encoded to H.264 in Flash Player 21 on output";
			vid_outDescription.background = true;
			vid_outDescription.backgroundColor = 0x1F1F1F;
			vid_outDescription.textColor = 0xD9D9D9;
			vid_outDescription.x = 400;
			vid_outDescription.y = cam.height;
			vid_outDescription.width = cam.width;
			vid_outDescription.height = 200;
			vid_outDescription.border = true;
			vid_outDescription.borderColor = 0xDD7500;
			addChild( vid_outDescription );
			addChild( metaTextTitle );
			
			vid_inDescription.text = "\n\n\n\n                  H.264-encoded video \n\n" + 
			"                  Streaming from Flash Media Server";
			vid_inDescription.background = true;
			vid_inDescription.backgroundColor =0x1F1F1F;
			vid_inDescription.textColor = 0xD9D9D9;
			vid_inDescription.x = vid_in.x;
			vid_inDescription.y = cam.height;
			vid_inDescription.width = cam.width;
			vid_inDescription.height = 200;
			vid_inDescription.border = true;
			vid_inDescription.borderColor = 0xDD7500;
			addChild( vid_inDescription );
			
			for ( var settings:String in metaData )
			{
			trace( settings + " = " + metaData[settings] );
			
			metaText.appendText( "\n" + "  " + settings.toUpperCase() + " = " + metaData[settings] + "\n" );
			}
		}
	}
}