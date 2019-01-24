using Uno.Threading;
using Uno;
using Uno.Compiler.ExportTargetInterop;
using Android;
using Fuse.ImageTools;
namespace Fuse.Camera
{
	[Require("Source.Include", "CameraHelper.h")]
	public extern(iOS) class iOSCamera
	{
		internal static void TakePicture(Promise<Image> p)
		{
			var cb = new ImagePromiseCallback(p);
			TakePictureInternal(cb.Resolve, cb.Reject);
		}

		[Foreign(Language.ObjC)]
		static void TakePictureInternal(Action<string> onComplete, Action<string> onFail)
		@{
			[[CameraHelper instance] takePictureWithCompletionHandler:onComplete onFail:onFail];
		@}
	}
	internal sealed class ImagePromiseCallback
	{
		Promise<Image> _p;
		public ImagePromiseCallback(Promise<Image> p)
		{
			_p = p;
		}

		public void Resolve(string path)
		{
			_p.Resolve(new Image(path));
		}

		public void Reject(string reason)
		{
			_p.Reject(new Exception(reason));
		}
	}

}
