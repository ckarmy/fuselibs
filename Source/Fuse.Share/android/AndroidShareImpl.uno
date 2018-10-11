using Uno.Compiler.ExportTargetInterop;
using Uno.Threading;

namespace Fuse.Share
{
	[TargetSpecificImplementation]
	[ForeignInclude(Language.Java,
					"android.content.Context",
					"java.io.File",
					"java.io.InputStream",
					"java.io.FileOutputStream",
					"android.net.Uri",
					"android.content.Intent",
					"android.support.v4.content.FileProvider",
					"android.content.Context")]
	public extern(Android) class AndroidShareImpl
	{
		[Foreign(Language.Java)]
		public static void ShareText(string text, string description)
		@{
			Intent sendIntent = new Intent();
			sendIntent.setAction(Intent.ACTION_SEND);
			sendIntent.putExtra(Intent.EXTRA_TEXT, text);
			sendIntent.setType("text/plain");
			com.fuse.Activity.getRootActivity().startActivity(Intent.createChooser(sendIntent, description));
		@}

		[Foreign(Language.Java)]
		public static void ShareFile(string path, string mimeType, string description)
		@{
			Context context = com.fuse.Activity.getRootActivity();
			Intent shareIntent = new Intent();
			shareIntent.setAction(Intent.ACTION_SEND);
			File f = new File(path.replace("file:///",""));
			Uri uri = FileProvider.getUriForFile(
								context, 
								context.getApplicationContext()
								.getPackageName() + ".fileprovider", f);
			shareIntent.putExtra(Intent.EXTRA_STREAM, uri);
			shareIntent.setType(mimeType);
			context.startActivity(Intent.createChooser(shareIntent, description));
		@}
	}
}
