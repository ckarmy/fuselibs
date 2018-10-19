using Uno;
using Uno.UX;

using Fuse.Reactive;

namespace Fuse.Controls
{
	public class ScrollViewPagerArgs : EventArgs
	{
	}

	/**
		Paging and loading manager for a list of items. Allows a large, or infinite list, to be displayed in a `ScrollView`.
		
		This controls the `Offset` and `Limit` properties of an `Each` inside a `ScrollView`. It limits the number of items displayed to improve performance.
		
		The setup that works now is with a `StackPanel` (Horizontal or Vertical)
		
			<ScrollView LayoutMode="PreserveVisual">
				<StackPanel>
					<Each Items="{items}" Reuse="Frame" ux:Name="theEach">
						<Panel Color="#AAA">
							<Text Value="{title}"/>
						</Panel>
					</Each>
				</StackPanel>
				
				<ScrollViewPager Each="theEach" ReachedEnd="{loadMore}"/>
			</ScrollView>
			
		It's required to use `LayoutMode="PreserveVisual"`, otherwise the scrolling will not function correctly. `Reuse="Frame"` is optional but recommended: it improves performance by reusing objects.
		
		`ReachedEnd` is called when the true end of the list is reached and more data is required. It's actually called somewhat before the end is reached, thus allowing the loading process to start before the user reaches the end. There is also a `RechedStart` to allow loading when scrolling the opposite direction.  Neither of these callbacks are mandatory; `ScrollViewPager` is also helpful for displaying large static lists.
		
		@experimental
	*/
	public partial class ScrollViewPager : Behavior, IPropertyListener
	{
		int _retain = 3;
		/**
			An approximate number of pages to retain. The size of the visible part of the `ScrollView` is the page size. Enough items to fill multiple amounts of this size are kept around. The rest are discarded.
			
			The default of `3` is about as low as you can go to not interrupt common scrolling. If you have small scrollable list, or expect the user to fling often, you may increase this value.
		*/
		public int Retain
		{
			get { return _retain; }
			set
			{
				if (_retain == value)
					return;
					
				_retain = value;
			}
		}

		/**
			When scrolled to this number of pages from the end the `ReachedStart` or `ReachedEnd` event will be raised.
		*/
		float _endRange = 0.75f;
		public float EndRange
		{
			get { return _endRange; }
			set
			{
				if (_endRange == value)
					return;
				
				_endRange = value;
			}
		}

		int _columnCount = 1;
		/**
			An optional attribute that will maintain the layout in-case of using Grids or any layout seems to be columns.
		*/
		public int ColumnCount
		{
			get { return _columnCount; }
			set
			{
				if (_columnCount == value)
				return;
				
				_columnCount = value;
			}
		}
		
		int _MaxItemsSize = 18;
		/**
			An optional attribute that will maintain the layout in-case of using Grids or any layout seems to be columns.
		*/
		public int MaxItemsSize
		{
			get { return _MaxItemsSize; }
			set
			{
				if (_MaxItemsSize == value)
				return;
				
				_MaxItemsSize = value;
			}
		}

		Each _each;
		/**
			The `Each` instance to control. This property is required.
		*/
		public Each Each 
		{
			get { return _each; }
			set { _each = value; }
		}
		
		ScrollViewBase _scrollable;
		protected override void OnRooted()
		{
			base.OnRooted();

			if (Each == null)
			{
				Fuse.Diagnostics.UserError( "Require an Each", this );
				return;
			}
			
			if (!Each.HasLimit)
				Each.Limit = 1;
			
			_scrollable = Parent.FindByType<ScrollViewBase>();
			if (_scrollable == null)
			{
				Fuse.Diagnostics.UserError( "Could not find a Scrollable control.", this );
				return;
			}

			/*
				Search for the parent type, if it is Grid then we have to get Grid Size from it and assign it to ColumnCount value 
				TODO : @ColumnLayout and @GridLayout support !
			*/
			
			Grid _gridContainer = Each.Parent as Grid;
			if (_gridContainer != null)
			{	
				if(_gridContainer.Columns != "")
				{
					var _column_data = _gridContainer.Columns.Split(',');
					if (_column_data.Length > 1)
					{
						ColumnCount = _column_data.Length;
					}
				}
				else if (_gridContainer.ColumnCount > 1)
				{
					ColumnCount = _gridContainer.ColumnCount;
				}
			}
			// debug_log "ColumnCount : "+ColumnCount;
			
			if (_scrollable.LayoutMode == ScrollViewLayoutMode.PreserveScrollPosition) 
			{
				Fuse.Diagnostics.UserError( "The ScrollView should have `LayoutMode=\"PreserveVisual\"` for paging to work correctly", this );
				return;
			}
			
			_scrollable.AddPropertyListener(this);
			_prevActualSize = float2(0);
			_lastActivityPosition = UpdateManager.FrameIndex;
			_lastActivitySizing = UpdateManager.FrameIndex;
		}
		
		protected override void OnUnrooted()
		{
			// debug_log "OnUnrooted";
			if (_scrollable != null)
			{
				_scrollable.RemovePropertyListener(this);
				_scrollable = null;
			}
			
			base.OnUnrooted();
		}
		
		void IPropertyListener.OnPropertyChanged(PropertyObject obj, Selector prop)
		{
			if (obj != _scrollable)
				return;

			// debug_log "UpdateManager.FrameIndex - LastActivityFrame  => "+ (UpdateManager.FrameIndex - LastActivityFrame);
			// debug_log "prop  => "+ (prop);
			if (UpdateManager.FrameIndex - _lastActivityPosition  < 3)
			{
				return;
			}
			// _scrollable.RemovePropertyListener(this);

			if (prop == ScrollView.ScrollPositionName)
			{
				// debug_log "RequestCheckPosition";
				RequestCheckPosition();
				_lastActivityPosition = UpdateManager.FrameIndex;
			}
			else if (prop == ScrollView.SizingChanged)
			{
				// debug_log "RequestCheckSizing";
				RequestCheckSizing();
				_lastActivitySizing = UpdateManager.FrameIndex;
			}
			// _scrollable.AddPropertyListener(this);
		}
		
		bool _pendingPosition;
		void RequestCheckPosition() 
		{
			// debug_log "_pendingPosition"+_pendingPosition;
			// debug_log "_pendingSizing"+_pendingSizing;
			// if (!_pendingPosition && !_pendingSizing)
			// {
				// debug_log "UpdateManager.AddDeferredAction(CheckPosition);";
				UpdateManager.AddDeferredAction(CheckPosition);
				_pendingPosition = true;
			// }
		}
		
		bool _pendingSizing;
		void RequestCheckSizing()
		{
			if (!_pendingSizing)
			{
				UpdateManager.AddDeferredAction(CheckSizing);
				_pendingSizing = true;
			}
		}

		public delegate void ScrollViewPagerHandler(object s, ScrollViewPagerArgs args);
		
		/**
			Raised when the `ScrollView` comes near the end of the data.
			
			When responding to this event from JavaScript it is important to call the `check` method once the loading is completed. This forces the ScrollViewPager to reconsider the position in light of the new data. Otherwise it might not update until the user interacts again.
		*/
		public event ScrollViewPagerHandler ReachedEnd;
		
		/**
			Raised when the `ScrollView` comes near the start of the data.
			
			@see ReachedEnd
		*/
		public event ScrollViewPagerHandler ReachedStart;

		
		/**
			Should be called whenever new data is added in response to `ReachedEnd` or `ReachedStart`. This will ensure the paging is updated even when nothing else would trigger the update.
		*/
		public void Check()
		{
			_nearTrueEnd = false;
			_nearTrueStart = false;
			//we don't set a priority since we want this to happen prior to layout in case there are new items
			//being added. We need to ensure the ScrollView's sizing calculations happen with the new items in place
			UpdateManager.AddDeferredAction(CheckSizing);
		}
		
		int _lastActivityPosition = 0;
		int _lastActivitySizing = 0;
		internal int LastActivityFrame { get { return Math.Max(_lastActivityPosition, _lastActivitySizing);  } }
		
		bool _nearTrueEnd;
		bool _nearTrueStart;

		void CheckPosition()
		{
			// debug_log "_pendingSizing "+_pendingSizing;
			// debug_log "_scrollable "+_scrollable;
			if (_scrollable == null)
				return;
			_lastActivityPosition = UpdateManager.FrameIndex;
			
			_pendingPosition = false;
			var nearEnd = _scrollable.ToScalarPosition( (_scrollable.MaxScroll - _scrollable.ScrollPosition) /
				_scrollable.ActualSize) < EndRange;
			var nearStart = _scrollable.ToScalarPosition( (_scrollable.ScrollPosition - _scrollable.MinScroll) /
				_scrollable.ActualSize) < EndRange;
			// debug_log "nearEnd : "+nearEnd;
			// debug_log "EndRange : "+EndRange;
			// debug_log "_scrollable.ToScalarPosition( (_scrollable.MaxScroll - _scrollable.ScrollPosition) /	_scrollable.ActualSize) : "+EndRange;

			var nearTrueEnd = false;
			var nearTrueStart = false;

			if (nearEnd && nearStart)
			{
				//nothing, otherwise we'd flip back and forth
				nearTrueEnd = true;
				nearTrueStart = true;
			}
			else if (nearEnd)
			{
				var offset = Each.Offset;
				var limit = Each.Limit;
				var count = Each.DataCount;
				
				if (offset + limit < count)
					Each.Offset = offset + ColumnCount;
				else
					nearTrueEnd = true;
			}
			else if (nearStart)
			{
				var offset = Each.Offset;
				if (offset > 0)
					Each.Offset = offset - ColumnCount;
				else
					nearTrueStart = true;
			}
			
			if (nearTrueStart != _nearTrueStart && nearTrueStart)
			{	
				if (ReachedStart != null)
					ReachedStart(this, new ScrollViewPagerArgs());
			}
			_nearTrueStart = nearTrueStart;
			
			if (nearTrueEnd != _nearTrueEnd &&  nearTrueEnd)
			{
				if (ReachedEnd != null)
					ReachedEnd(this, new ScrollViewPagerArgs());
			}
			_nearTrueEnd = nearTrueEnd;
		}

		float2 _prevActualSize;
		void CheckSizing()
		{
			if (_scrollable == null)
				return;
				
			_lastActivitySizing = UpdateManager.FrameIndex;
			
			_pendingSizing = false;
			var pages = _scrollable.ContentMarginSize / _scrollable.ActualSize;

			var scalarPages = _scrollable.ToScalarPosition(pages);
			var changed = false;
			
			if (scalarPages < Retain)
			{
				var count = Each.DataCount;
				var offset = Each.Offset;
				var limit = Each.Limit;
				
				if (offset + limit < count)
				{
					Each.Limit = limit + ColumnCount;
					if(Each.Limit > MaxItemsSize)
						Each.Limit = MaxItemsSize;
					changed = true;
				}
			}
			else if (scalarPages > Retain &&
				_scrollable.ToScalarPosition(_scrollable.ActualSize) < _scrollable.ToScalarPosition(_prevActualSize) )
			{
				//only reduce when the ScrollView itself is being shrunk in size, otherwise we run the risk
				//of flickering between to sizes for an element that pushes it back/forth over the limit
				var limit = Each.Limit;
				
				if (limit > 1)
				{
					Each.Limit = limit - ColumnCount;
					if(Each.Limit > MaxItemsSize)
						Each.Limit = MaxItemsSize;
					changed = true;
				}
			}
			
			if (!changed)
			{
				//only check once the sizing is done to prevent needless event calls while still doing layout
				//of several items.
				CheckPosition();
				// debug_log "CheckPosition(); again ;)";
				return;
			}

			//force a check next frame in the odd case the size doesn't actually change
			// debug_log "force a check next frame in the odd case the size doesn't actually change";
			_pendingSizing = true;
			// UpdateManager.PerformNextFrame(CheckPosition);
			UpdateManager.PerformNextFrame(CheckSizing);
		}
		
	}
}
