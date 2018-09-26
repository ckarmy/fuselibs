using Uno;
using Uno.UX;
using Uno.Collections;
using Fuse;
using Fuse.Scripting;
using Fuse.Controls;
namespace Fuse
{
	public partial class Node
	{
		static Node()
		{
			ScriptClass.Register(typeof(Node),
				new ScriptMethod<Node>("_createWatcher", _createWatcher),
				new ScriptMethod<Node>("_destroyWatcher", _destroyWatcher),
				new ScriptMethod<Node>("addElement", _addElement),
				new ScriptMethodInline("findData", "function(key) { return Observable._getDataObserver(this, key); }"));
		}

		static object _createWatcher(Context c, Node n, object[] args)
		{
			var key = (string)args[0];
			var callback = (Scripting.Function)args[1];
			return new External(new DataWatcher(n, c, callback, key));			
		}
		static public string GetObjectPath( object data )
		{
			debug_log "GetObjectPath : "+ data;
			string path = null;
			var obj = data as IObject;
			var keys = obj.Keys;

			for (int i=0; i < keys.Length; ++i)
			{
				debug_log String.Format("keys[{0}] is {1} = {2}",i,keys[i],obj[keys[i]]);
			}

			if (obj != null && obj.ContainsKey("$__fuse_classname")) //set implicitly by Model API
			{
				path = Marshal.ToType<string>(obj["$__fuse_classname"]);
				debug_log "$__fuse_classname : "+ obj["$__fuse_classname"];

			}
			if (obj != null && obj.ContainsKey("$path"))
			{	
				path = Marshal.ToType<string>(obj["$path"]);
				debug_log "$path : "+ obj["$path"];
			}
			debug_log "path : "+path;
			return path;
		}

		static object _addElement(Context c, Node n, object[] args)
		{
			debug_log "ElementType : "+(args[0].GetType().BaseType.GetElementType());
			var template = ((Visual)n).FindTemplate(GetObjectPath(args[0]));
			debug_log "template : "+template;
			var v = template.New() as Visual;
			((Visual)n).Children.Add(v);
			return v;
		}

		static object _destroyWatcher(Context c, Node n, object[] args)
		{
			if (args[0] != null)
			{
				var watcher = (DataWatcher)((External)args[0]).Object;
				watcher.Dispose();
			}

			return null;
		}

		class DataWatcher: IDataListener
		{
			Node _node;
			Scripting.Context _context;
			Scripting.Function _updateCallback;
			NodeDataSubscription _dataSub;
			string _key;

			public DataWatcher(Node node, Scripting.Context context, Scripting.Function updateCallback, string key)
			{
				_key = key;
				_node = node;
				_context = context;
				_updateCallback = updateCallback;

				UpdateManager.PostAction(Subscribe);
			}

			void Subscribe()
			{
				_dataSub = _node.SubscribeData(_key, this);
				if (_dataSub.HasData)
					((IDataListener)this).OnDataChanged();
			}

			public void Dispose()
			{
				if (_dataSub != null)
				{
					_dataSub.Dispose();
					_dataSub = null;
				}
			}

			object _data;
			void IDataListener.OnDataChanged()
			{
				_data = _dataSub.Data;
				_context.ThreadWorker.Invoke(Update);
			}

			void Update(Scripting.Context context)
			{
				_updateCallback.Call(context, context.Unwrap(_data));
			}
		}
	}
}
