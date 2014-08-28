package 
{
	import com.adobe.air.gaming.AIRGamepad;
	import com.adobe.air.gaming.AIRGamepadErrorEvent;
	import com.adobe.air.gaming.AIRGamepadEvent;
	import flash.display.Bitmap;
	import flash.display.JPEGEncoderOptions;
	import flash.display.Sprite;
	import flash.events.AccelerometerEvent;
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author Rhuno
	 */
	public class Main extends Sprite 
	{
		private const MAX_TILT:int		= 6;
		private const MAX_VELOCITY:int	= 18;
		private const GAMEPAD_ID:String = "player";
		
		[Embed(source = "rskin.jpg")]
		private var _skin:Class;
		
		private var _baddies:Array;
		private var _player:Sprite;
		private var _ground:Sprite;
		private var _gamepad:AIRGamepad;
		
		public function Main():void 
		{
			if (!stage)
				addEventListener(Event.ADDED_TO_STAGE, init);
			else
				init();
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			initPlayer();
			initGround();
			initBaddies();
			
			_ground.y = stage.stageHeight - _ground.height;
			_player.y = _ground.y - _player.height;
			
			_gamepad = AIRGamepad.getGamepad(GAMEPAD_ID);
			
			if (_gamepad)
			{
				addGamepadListeners();
				_gamepad.connect(stage, "Rhuno", "http://www.rhuno.com/flashblog");				
			}
		}
		
		private function update(e:Event):void 
		{
			for each(var s:Sprite in _baddies)
			{
				s.y += s.tabIndex; // using tabIndex as velocity (see resetBaddy method)
				
				// player collision
				if (s.hitTestObject(_player) == true)
				{
					resetBaddy(s);
					_gamepad.vibrate(100);
					trace('hit!');
				}
				
				// ground collision
				if (s.y >= _ground.y)
					resetBaddy(s);
			}
		}
		
		private function resetBaddy($badguy:Sprite):void
		{
			$badguy.x			= Math.random() * (stage.stageWidth - $badguy.width);
			$badguy.y  			= Math.random() * 250 * -1;
			$badguy.tabIndex	= Math.random() * 12 + 4; // used as velocity (see update method)
		}
		
		private function addGamepadListeners():void
		{
			_gamepad.addEventListener(AIRGamepadEvent.CONNECT, onGamePadConnected);
			_gamepad.addEventListener(AIRGamepadErrorEvent.CONNECT_ERROR, onConnectError);
			_gamepad.addEventListener(AIRGamepadEvent.DISCONNECT, onGamePadDisconnected);
			_gamepad.addEventListener(AccelerometerEvent.UPDATE, onAccData);
			_gamepad.addEventListener(AIRGamepadErrorEvent.DRAW_ERROR, onDrawError);
		}
		
		private function initPlayer():void
		{
			_player		= new Sprite();
			_player.graphics.beginFill(0xffae3a);
			_player.graphics.drawRect(0, 0, 30, 100);
			_player.graphics.endFill();
			addChild(_player);
		}
		
		private function initGround():void
		{
			_ground		= new Sprite();
			_ground.graphics.beginFill(0x009b00);
			_ground.graphics.drawRect(0, 0, stage.stageWidth, 50);
			_ground.graphics.endFill();
			addChild(_ground);
		}
		
		private function initBaddies():void
		{
			_baddies	= [];
			var sp:Sprite;
			for (var i:int = 0; i < 10; i++)
			{
				sp = new Sprite();
				sp.graphics.beginFill(0xcc0000);
				sp.graphics.drawCircle(0, 0, 4);
				resetBaddy(sp);
				_baddies.push(sp);
				addChild(sp);
			}
		}
		
		private function onAccData(e:AccelerometerEvent):void 
		{
			var percent:Number;
			var move:Number;
			var tilt:Number = e.accelerationX;
			
			percent 	= Math.abs(tilt) / MAX_TILT;
			move		= percent * MAX_VELOCITY;
			
			// android devices give negative values if tilting to the right, positive if tilting to the left
			// so we need to move right if the value is negative, left if positive
			if(tilt < 0)
				_player.x += move;
			else
				_player.x -= move;
				
			// keep player on screen
			if (_player.x < 0)
				_player.x = 0;
				
			if (_player.x + _player.width > stage.stageWidth)
				_player.x = stage.stageWidth - _player.width;
		}
		
		/**************************/
		/* Gamepad Event Handlers */
		/**************************/
		private function onGamePadDisconnected(e:AIRGamepadEvent):void 
		{
			trace('onGamePadDisconnected');
			removeEventListener(Event.ENTER_FRAME, update);
		}
		
		private function onConnectError(e:AIRGamepadErrorEvent):void 
		{
			trace("onConnectError");
		}
		
		private function onDrawError(e:AIRGamepadErrorEvent):void
		{
			trace("onDrawError", e.text, e.errorID);
		}
		
		private function onGamePadConnected(e:AIRGamepadEvent):void 
		{
			trace("Gamepad Connected");
			
			if (_gamepad.hasVibrator)
				_gamepad.vibrate(250);
			
			var bmp:Bitmap 			= new _skin() as Bitmap;
			var bytes:ByteArray		= new ByteArray();			
			bmp.bitmapData.encode(bmp.getBounds(stage), new JPEGEncoderOptions(80) , bytes);
			_gamepad.drawImage(bytes);	// draw skin graphic to the android device
			
			// start the game
			addEventListener(Event.ENTER_FRAME, update);
		}
	}
}