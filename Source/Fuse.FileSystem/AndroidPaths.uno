using Uno;
using Uno.IO;
using Fuse.Scripting;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.Permissions;
using Uno.Threading;

namespace Fuse.FileSystem
{
	extern(Android) internal class AndroidPaths
	{
		static Promise<AndroidPathsWarpper> dataPromise;

		internal static Dictionary<string, string> GetPathDictionary()
		{
			var dict = new Dictionary<string, string>();
			dict["externalCache"] = GetExternalCacheDirectory();
			dict["externalFiles"] = GetExternalFilesDirectory();
			dict["cache"] = GetCacheDirectory();
			dict["files"] = GetFilesDirectory();
			dict["alarms"] = GetDirectoryAlarms();
			dict["dcim"] = GetDirectoryDcim();
			dict["documents"] = GetDirectoryDocuments();
			dict["downloads"] = GetDirectoryDownloads();
			dict["movies"] = GetDirectoryMovies();
			dict["music"] = GetDirectoryMusic();
			dict["notifications"] = GetDirectoryNotification();
			dict["pictures"] = GetDirectoryPictures();
			dict["podcasts"] = GetDirectoryPodcasts();
			dict["ringtones"] = GetDirectoryRingtones();
			return dict;
		}
		internal static Future<AndroidPathsWarpper>  GetPathDictionaryAsync()
		{
			debug_log "GetPathDictionaryAsync";
			dataPromise = new Promise<AndroidPathsWarpper>();
			Permissions.Request(new PlatformPermission[] { 
				Permissions.Android.WRITE_EXTERNAL_STORAGE, Permissions.Android.READ_EXTERNAL_STORAGE 
				}).Then(OnPermissions, OnRejected);
			return dataPromise;
		}
		static void OnPermissions(PlatformPermission[] grantedPermissions)
		{
			debug_log "OnPermissions";
			if(grantedPermissions.Length == 2)
			{
				var dict = new Dictionary<string, string>();
				dict["externalCache"] = GetExternalCacheDirectory();
				dict["externalFiles"] = GetExternalFilesDirectory();
				dict["cache"] = GetCacheDirectory();
				dict["files"] = GetFilesDirectory();
				dict["alarms"] = GetDirectoryAlarms();
				dict["dcim"] = GetDirectoryDcim();
				dict["documents"] = GetDirectoryDocuments();
				dict["downloads"] = GetDirectoryDownloads();
				dict["movies"] = GetDirectoryMovies();
				dict["music"] = GetDirectoryMusic();
				dict["notifications"] = GetDirectoryNotification();
				dict["pictures"] = GetDirectoryPictures();
				dict["podcasts"] = GetDirectoryPodcasts();
				dict["ringtones"] = GetDirectoryRingtones();
				debug_log "Before Resolve ;)";
				dataPromise.Resolve(new AndroidPathsWarpper(dict));
			}
			else
			{
				dataPromise.Reject(new Exception("No permission "));
			}
		}

		static void OnRejected(Exception e)
		{
			dataPromise.Reject(e);
		}



		[Foreign(Language.Java)]
		static string GetExternalCacheDirectory()
		@{
			return com.fuse.Activity.getRootActivity().getExternalCacheDir().getAbsolutePath();
		@}


		[Foreign(Language.Java)]
		static string GetExternalFilesDirectory()
		@{
			return com.fuse.Activity.getRootActivity().getExternalFilesDir(null).getAbsolutePath();
		@}


		[Foreign(Language.Java)]
		static string GetCacheDirectory()
		@{
			return com.fuse.Activity.getRootActivity().getCacheDir().getAbsolutePath();
		@}


		[Foreign(Language.Java)]
		static string GetFilesDirectory()
		@{
			return com.fuse.Activity.getRootActivity().getFilesDir().getAbsolutePath();
		@}
		
		[Foreign(Language.Java)]
		static string GetDirectoryAlarms()
		@{
			return android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_ALARMS).getAbsolutePath();
		@}

		[Foreign(Language.Java)]
		static string GetDirectoryDcim()
		@{
			return android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DCIM).getAbsolutePath();
		@}

		[Foreign(Language.Java)]
		static string GetDirectoryDocuments()
		@{
			return android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOCUMENTS).getAbsolutePath();
		@}

		[Foreign(Language.Java)]
		static string GetDirectoryDownloads()
		@{
			return android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS).getAbsolutePath();
		@}

		[Foreign(Language.Java)]
		static string GetDirectoryMovies()
		@{
			return android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_MOVIES).getAbsolutePath();
		@}

		[Foreign(Language.Java)]
		static string GetDirectoryMusic()
		@{
			return android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_MUSIC).getAbsolutePath();
		@}

		[Foreign(Language.Java)]
		static string GetDirectoryNotification()
		@{
			return android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_NOTIFICATIONS).getAbsolutePath();
		@}

		[Foreign(Language.Java)]
		static string GetDirectoryPictures()
		@{
			return android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_PICTURES).getAbsolutePath();
		@}

		[Foreign(Language.Java)]
		static string GetDirectoryPodcasts()
		@{
			return android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_PODCASTS).getAbsolutePath();
		@}

		[Foreign(Language.Java)]
		static string GetDirectoryRingtones()
		@{
			return android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_RINGTONES).getAbsolutePath();
		@}
	}
}
