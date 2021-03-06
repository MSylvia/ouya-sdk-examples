﻿package
{
	import flash.desktop.NativeApplication;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
    import flash.display.MovieClip;
	import flash.display.PixelSnapping;
	import flash.events.Event;
	import flash.events.StatusEvent;
	import flash.geom.Matrix;
	import flash.system.System;
	import tv.ouya.console.api.OuyaController;
	import tv.ouya.sdk.OuyaNativeInterface;

    public class Main extends MovieClip
    {
		static var DEVLEOPER_ID:String = "310a8f51-4d6e-4ae5-bda0-b93878e5f5d0";
		
		var INTERVAL_MS_INPUT:Number = 10;
		
		var _mOuyaNativeInterface: OuyaNativeInterface;
		
		var _mInputTimer:Number = 0;
		
		var _mInitialized:Boolean = false;
		
		var _mBtnRequestProductList:Bitmap;
		var _mBtnRequestPurchase:Bitmap;
		var _mBtnRequestReceipts:Bitmap;
		var _mBtnRequestGamerInfo:Bitmap;
		var _mBtnGetGameData:Bitmap;
		var _mBtnPutGameData:Bitmap;
		var _mBtnExit:Bitmap;
		var _mBtnPause:Bitmap;
		
		var _mButtonIndex:int = 0;
		var _mButtonMax:int = 8;
		
		var _mProducts:Array = null;
		
		var _mProductIndex:int = 0;
		
		var _mReceipts:Array = null;
		
		private function fl_EnterFrameHandler_1(event:Event):void
		{
			var date:Date = new Date();
			if (_mInputTimer < date.getTime())
			{
				_mInputTimer = date.getTime() + INTERVAL_MS_INPUT;
				
				UpdateVisibility(_mBtnRequestProductList, _mButtonIndex == 0);
				UpdateVisibility(_mBtnRequestPurchase, _mButtonIndex == 1);
				UpdateVisibility(_mBtnRequestReceipts, _mButtonIndex == 2);
				UpdateVisibility(_mBtnRequestGamerInfo, _mButtonIndex == 3);
				UpdateVisibility(_mBtnGetGameData, _mButtonIndex == 4);
				UpdateVisibility(_mBtnPutGameData, _mButtonIndex == 5);
				UpdateVisibility(_mBtnExit, _mButtonIndex == 6);
				UpdateVisibility(_mBtnPause, _mButtonIndex == 7);
				
				if (_mButtonIndex < 2) {
					DisplayProducts();
				} else if (_mButtonIndex == 2) {
					DisplayReceipts();
				} else {
					LblContent.text = "";
				}
			}
			
			if (!_mInitialized &&
				_mOuyaNativeInterface.IsInitialized()) {
				var deviceName:String = _mOuyaNativeInterface.GetDeviceHardwareName();
				_mOuyaNativeInterface.LogInfo("HardwareDevice: "+_mOuyaNativeInterface.GetDeviceHardwareName());
				LblHello.text = "Running on device: `"+deviceName+"`";
					
				var strButtonO:String = _mOuyaNativeInterface.GetButtonName(OuyaController.BUTTON_O);
				
				LblDirections.text = "Use DPAD to switch between buttons | Press '"+strButtonO+"' to click the button";
					
				_mInitialized = true;
			}
		}
		
		private function Axis(jsonData:String):void
		{
			var json:Object = JSON.parse(jsonData);
			var playerNum:int = json.playerNum;
			var axis:int = json.axis;
			var val:Number = json.value;
			//_mOuyaNativeInterface.LogInfo("Axis: playerNum:"+playerNum+" axis:"+axis+" value:"+val);
		}
		
		private function ButtonDown(jsonData:String):void
		{
			var json:Object = JSON.parse(jsonData);
			var playerNum:int = json.playerNum;
			var button:int = json.button;
			//_mOuyaNativeInterface.LogInfo("ButtonDown: playerNum:"+playerNum+" button:"+button);
		}
		
		private function ButtonUp(jsonData:String):void
		{
			var json:Object = JSON.parse(jsonData);
			var playerNum:int = json.playerNum;
			var button:int = json.button;
			//_mOuyaNativeInterface.LogInfo("ButtonUp: playerNum:"+playerNum+" button:"+button);
			var products:Array = _mProducts;
			if (button == OuyaController.BUTTON_DPAD_LEFT) {
				if (_mButtonIndex > 0) {
					--_mButtonIndex;
				}
			} else if (button == OuyaController.BUTTON_DPAD_RIGHT) {
				if ((_mButtonIndex+2) < _mButtonMax) {
					++_mButtonIndex;
				}
			} else if (button == OuyaController.BUTTON_DPAD_DOWN) {
				if (null != products) {
					if ((_mProductIndex+1) < products.length) {
						++_mProductIndex;
					}
				}
			} else if (button == OuyaController.BUTTON_DPAD_UP) {
				if (_mProductIndex > 0) {
					--_mProductIndex;
				}
			} else if (button == OuyaController.BUTTON_O) {
				if (_mButtonIndex == 0) {
					LblStatus.text = "STATUS: Requesting Product List...";
					_mProductIndex = 0;
					var jsonData:String = "[\"long_sword\",\"sharp_axe\",\"__DECLINED__THIS_PURCHASE\"]";
					_mOuyaNativeInterface.RequestProducts(jsonData);
				} else if (_mButtonIndex == 1) {
					if (_mProductIndex < products.length) {
						LblStatus.text = "STATUS: Requesting Purchase...";
						_mOuyaNativeInterface.RequestPurchase(products[_mProductIndex].identifier);
					} else {
						LblStatus.text = "STATUS: Request products before making a purchase!";
					}
				} else if (_mButtonIndex == 2) {
					LblStatus.text = "STATUS: Requesting Receipts...";
					_mOuyaNativeInterface.RequestReceipts();
				} else if (_mButtonIndex == 3) {
					LblStatus.text = "STATUS: Requesting Gamer Info...";
					_mOuyaNativeInterface.RequestGamerInfo();
				} else if (_mButtonIndex == 4) {
					LblStatus.text = "STATUS: Get Game Data...";
					var result:String = _mOuyaNativeInterface.GetGameData("FULL_GAME_UNLOCK");
					LblStatus.text = "STATUS: Get Game Data: "+result;
				} else if (_mButtonIndex == 5) {
					LblStatus.text = "STATUS: Put Game Data...";
					_mOuyaNativeInterface.PutGameData("FULL_GAME_UNLOCK", "DATA SET");
				} else if (_mButtonIndex == 6) {
					LblStatus.text = "STATUS: Exiting...";
					_mOuyaNativeInterface.Shutdown();
					NativeApplication.nativeApplication.exit();
				}
			}
		}
		
		private function OnGenericError(tag:String, jsonData:String):void
		{
			var json:Object = JSON.parse(jsonData);
			var errorCode:int = json.errorCode;
			var errorMessage:String = json.errorMessage;
			LblStatus.text = "STATUS: "+tag+" errorCode="+errorCode+" errorMessage="+errorMessage;
		}
		
		private function RequestGamerInfoOnSuccess(jsonData:String):void
		{
			var json:Object = JSON.parse(jsonData);
			LblGamerUUID.text = "Gamer UUID: "+json.uuid;
			LblUsername.text = "Gamer Username: "+json.username;
		}
		
		private function RequestProductsOnSuccess(jsonData:String):void
		{
			//LblContent.text = jsonData;
			_mProducts = JSON.parse(jsonData) as Array;
		}
		
		private function RequestPurchaseOnSuccess(jsonData:String):void
		{
			var json:Object = JSON.parse(jsonData);
			LblContent.text = jsonData;
		}
		
		private function RequestReceiptsOnSuccess(jsonData:String):void
		{
			//LblContent.text = jsonData;
			_mReceipts = JSON.parse(jsonData) as Array;
		}
		
		private function onStatusEvent( _event : StatusEvent ) : void 
		{
			if (_event.code == "Axis") {
				Axis(_event.level);
				return;
			} else if (_event.code == "ButtonDown") {
				ButtonDown(_event.level);
				return;
			} else if (_event.code == "ButtonUp") {
				ButtonUp(_event.level);
				return;
			}
			
			LblStatus.text = "STATUS: "+_event.code;
			
			if (_event.code == "RequestGamerInfoOnSuccess") {
				RequestGamerInfoOnSuccess(_event.level);
			} else if (_event.code == "RequestGamerInfoError" ||
				_event.code == "RequestProductsError" ||
				_event.code == "RequestPurchaseError" ||
				_event.code == "RequestReceiptsError" ||
				_event.code == "RequestGamerInfoOnFailure" ||
				_event.code == "RequestProductsOnFailure" ||
				_event.code == "RequestPurchaseOnFailure" ||
				_event.code == "RequestReceiptsOnFailure" ||
				_event.code == "RequestGamerInfoOnCancel" ||
				_event.code == "RequestProductsOnCancel" ||
				_event.code == "RequestPurchaseOnCancel" ||
				_event.code == "RequestReceiptsOnCancel") {
				OnGenericError(_event.code, _event.level);
			} else if (_event.code == "RequestProductsOnSuccess") {
				RequestProductsOnSuccess(_event.level);
			} else if (_event.code == "RequestPurchaseOnSuccess") {
				RequestPurchaseOnSuccess(_event.level);
			} else if (_event.code == "RequestReceiptsOnSuccess") {
				RequestReceiptsOnSuccess(_event.level);
			} else {
				_mOuyaNativeInterface.LogInfo("Code: " + _event.code );
				_mOuyaNativeInterface.LogInfo("Level: " + _event.level );
			}
		}
		
		private function AddBitmap(textField : TextField, bitmap : Bitmap) : Bitmap
		{
			var matrix:Matrix = new Matrix();
			matrix.scale(new Number(textField.width)/bitmap.width, new Number(textField.height)/bitmap.height);

			var resizedBitmapData:BitmapData = new BitmapData(textField.width, textField.height, true, 0x000000);
			resizedBitmapData.draw(bitmap, matrix, null, null, null, true);

			var resizedBitmap = new Bitmap(resizedBitmapData, PixelSnapping.NEVER, true);
			
			resizedBitmap.x = textField.x;
			resizedBitmap.y = textField.y;
			
			addChild(resizedBitmap);
			return resizedBitmap;
		}
		
		private function CreateButton(textField : TextField) : Bitmap
		{
			AddBitmap(textField, new Bitmap(new ImageButtonInactive()));
			var result:Bitmap = AddBitmap(textField, new Bitmap(new ImageButtonActive()));
			
			// put the label on top of the sprites
			setChildIndex(textField, numChildren-1);
			
			return result;
		}
		
		private function UpdateVisibility(bitmap:Bitmap, show:Boolean) : void
		{
			if (show)
			{
				bitmap.alpha = 1;
			}
			else
			{
				bitmap.alpha = 0;
			}
		}
		
		private function DisplayProducts():void
		{
			var json:Array = _mProducts;
			var str:String = "";
			if (null != json) {
				for (var i:int = 0; i < json.length; ++i) {
					if (i == _mProductIndex) {
						str += "* ";
					}
					var description:String = json[i].description;
					var identifier:String = json[i].identifier;
					var name:String = json[i].name;
					var localPrice:Number = json[i].localPrice;
					str += "description="+description;
					str += " identifier="+identifier;
					str += " name="+name;
					str += " localPrice="+localPrice;
					str += "\n";
				}
			}
			LblContent.text = str;
		}
		
		private function DisplayReceipts():void
		{
			var json:Array = _mReceipts;
			var str:String = "";
			if (null != json) {
				for (var i:int = 0; i < json.length; ++i) {
					var currency:String = json[i].currency;
					var identifier:String = json[i].identifier;
					var generatedDate:String = json[i].generatedDate;
					var localPrice:Number = json[i].localPrice;
					str += "currency="+currency;
					str += " identifier="+identifier;
					str += " generatedDate="+generatedDate;
					str += " localPrice="+localPrice;
					str += "\n";
				}
			}
			LblContent.text = str;
		}
		
        public function Main()
        {
			_mOuyaNativeInterface = new OuyaNativeInterface();
			_mOuyaNativeInterface.OuyaInit(DEVLEOPER_ID);
			
			_mBtnRequestProductList = CreateButton(BtnRequestProductList);
			_mBtnRequestPurchase = CreateButton(BtnRequestPurchase);
			_mBtnRequestReceipts = CreateButton(BtnRequestReceipts);
			_mBtnRequestGamerInfo = CreateButton(BtnRequestGamerInfo);
			_mBtnGetGameData = CreateButton(BtnGetGameData);
			_mBtnPutGameData = CreateButton(BtnPutGameData);
			_mBtnExit = CreateButton(BtnExit);
			_mBtnPause = CreateButton(BtnPause);
			
			UpdateVisibility(_mBtnRequestProductList, true);
			UpdateVisibility(_mBtnRequestPurchase, false);
			UpdateVisibility(_mBtnRequestReceipts, false);
			UpdateVisibility(_mBtnRequestGamerInfo, false);
			UpdateVisibility(_mBtnGetGameData, false);
			UpdateVisibility(_mBtnPutGameData, false);
			UpdateVisibility(_mBtnExit, false);
			UpdateVisibility(_mBtnPause, false);
			
			//_mOuyaNativeInterface.LogInfo("***** Add event listener...");			
			addEventListener(Event.ENTER_FRAME, fl_EnterFrameHandler_1);
			
			_mOuyaNativeInterface.GetExtensionContext().addEventListener( StatusEvent.STATUS, onStatusEvent );
        }
    }
}
