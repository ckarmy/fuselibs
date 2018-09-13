using Uno;
using Uno.IO;
using Fuse.Scripting;
using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;
using Uno.Permissions;
using Uno.Threading;

namespace Fuse.FileSystem
{
	public class AndroidPathsWarpper
	{
		Dictionary<string, string> data;
		public AndroidPathsWarpper()
		{
			data = new Dictionary<string, string>();
		}

		public AndroidPathsWarpper(Dictionary<string, string> thedata)
		{
            debug_log "AndroidPathsWarpper Constructor ;)";
			data = thedata;
		}
		public Dictionary<string, string> getData()
		{
            debug_log "AndroidPathsWarpper: Get the Data Constructor ;)";
			return data;
		}
	}
}