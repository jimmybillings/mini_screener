#
# Improved viewing of speedpreviews.
# MiniScreener is a tooltip thats placed over a clip on the search and bin page on hover.
# It builds the tooltip by querying a JSON object which holds all the data
# for each clip and parses it into a viewable layout to show the user.
#

class MiniScreener

	constructor:(params) ->

		@_thumbData = thumbDataUnified

		#
		# Sets default options for miniScreener
		# @param clips: video holder
		# @param screener: container that will show and hide the video and other data
		# @param showClass: css class that is applied to screener when in display mode
		#
		@options =
			clips: '.img-holder, .still'
			screener: $j("<div id=\"miniScreener\" class=\"speedview-display\"></div>")
			showClass: 'screenerShow'

		#
		# Overide default options - var screener = new miniScreener({'clips':'.video-holder'})
		#
		if params then @options[option] = value for option, value of params

		# Remove any previous miniScreener Holders
		@_startFresh()
		# Fire up the miniScreener hover Listner!
		@_hoverReady()
		# Remove the miniScreener if user hits the Alt key or scrolls the screen.
		@_screenerHideEvents()


	#
	# Removes any previous screeners and starts fresh to stop any duplicates.
	# This happens on AJAX pages like the bin page where the miniScreener needs 
	# to be instantiated every time a new page of content is injected in. 
	#
	_startFresh: ->
		# Incase there is already a miniScreener container remove it. 
		if $j('#miniScreener').length > 0 then $j('#miniScreener').remove()

		# start fresh!
		@options.screener.appendTo 'body'

	#
	# Initiates the hover listener for the miniScreener to show and hide
	#
	_hoverReady: ->

		# Mouse over event that initializes the miniScreener
		$j(@options.clips)
			.find('a')
			.hoverIntent  (event) => 
				#
				# only fire miniScreener if the alt key isn't down 
				# (alt key is used as a hotkey to select clips so this 
				# helps to stop interference with that operation)
				#
				if !event.altKey
							#
							# When a hover has validated call _buildScreener() and pass in the 
							# current element.
							#
					@_buildScreener $j(event.target)
			, (event) =>


	#
	# Initiates the key listener to stop the miniScreener when the alt key is pressed
	# so that the select clips functionality works from the clip tools menu
	# or the user trys to scroll on the page.
	#		
	_screenerHideEvents: ->
		# remove the screener if alt key is being held down for the select mode.
		$j(document).on 'keydown scroll click', (event) =>
			if event.altKey
				event.preventDefault()
				@_hideScreener()
			else
				@_hideScreener()



	#
	# Gatherers all data for a new screener to display
	# @param 'el' current hovered element
	#
	_buildScreener:(el) ->
		el = el.parent 'a' if !el.is('a')
		screenerType = el.data('itemType') || 'clip'
		assetId =  el.data('video').split("/")[0]
		if screenerType is 'still' then displayData = el.data 'displayData'

		#
		# Use the clip id of the hovered element to
		# query the json object "@_thumbData" and
		# retrieve the meta data object for the
		# current clip
		#

		meta = false

		for key, value of @_thumbData
			if value.clip is assetId
				meta = @_thumbData[key]
				break

		#
		# This is wrapped in an if statement to stop
		# any JS errors for edge case clips that are
		# not it the json object.
		#
		if meta
			# Get the thumb url for current clip
			@thumb = @_getThumb meta
			
			# Get the clip details page url for current clip
			@assetUrl = @_getUrl meta
			
			# builds and returns the flash video for current clip
			@video = @_buildVideo meta, assetId
			
			# builds and returns metadata layout for current clip
			if screenerType is 'clip'
				@_metaLayout = @_buildFlashMetaLayout meta
				#
				# Initializes the build of the container that will hold the 
				# video. !important - it attaches the thumb url as a background
				# image which helps to load the flash video in a smooth manner
				# and avoids any jarring flashes on first load
				#
				@_previewContainer = $j('<div class="img-holder"></div>').css 'background-image', "url('#{@thumb}')"
			else
				@_metaLayout = @_buildMetaLayoutFrom el
				@_previewContainer = @_buildPreviewFrom el
			
			# gets absolute position for miniScreener from the top
			@videoContainerTop = el.offset().top - 24
			
			# gets absolute position for miniScreener from the left
			@videoContainerLeft = el.offset().left - 228
			
			@_showClipScreenerFor screenerType
			
		return

	_buildMetaLayoutFrom: (el) ->
		el.next('.metadata').clone()

	_buildPreviewFrom: (el) ->
		el.clone().addClass 'img-holder'

	#
	# Attaches all layout and data to screener and displays
	#
	_showClipScreenerFor: (type) ->
		#
		# builds the screener for display by attaching 
		# video holder with background image, meta layout,
		# adds the CSS class and absolutley positions it
		# ontop of the hovered element.
		#
		@options.screener
			.html(@_previewContainer)
			.append(@_metaLayout)
			.addClass(@options.showClass)
			.css
				'left' : @videoContainerLeft
				'top' : @videoContainerTop
		
		# on mouseout of the screener hide it.
		@_previewContainer.on 'mouseout', => 
			@_hideScreener()

		return if type is 'still'
		# 
		# Looks for video holder and attaches the video. 
		# This is an important part of the flow as it helps to 
		# display the video smoothly and avoids any jarring flashes 
		# because of the background image of @_previewContainer.
		#
		if !@video
			@options.screener
			.find(@options.clips)
			.html "<a id='overVideo' href=#{@assetUrl} target='_blank'></a>"
		else
			@options.screener
			.find(@options.clips)
			.html @video
		
		#
		# Apply an overlay to the video which links to the clip details
		# page for this clip. The overlay fixes hover problems that were
		# occuring in Firefox.
		#
		@options.screener
			.find('object')
			.before "<a id='overVideo' href=#{@assetUrl} target='_blank'></a>"
		
		return

	#
	# removes the css class that displays screener and empties it's contents.
	#
	_hideScreener: ->
		timer = '';
		@options.screener
				.removeClass(@options.showClass)
		#
		# remove flash player after screener has been hidden. this helps to hide the 
		# screener faster as the flash player slows things down.
		#
		timer = setTimeout =>
			@options.screener
				.empty()
		, 70
		
		return

	#
	# returns clip details page url for clip
	# @param 'meta' json object of current clip holding related metadata
	#
	_getUrl:(meta) ->
		meta.clickTo

	#
	# returns thumb url of clip
	# @param 'meta' json object of current clip holding related metadata
	#
	_getThumb:(meta) ->
		meta.thumb

	#
	# builds the layout with all clip meta data inside.
	# @param 'meta' json object of current clip holding related metadata
	#
	_buildFlashMetaLayout:(meta) ->
		div =  "<div class='attributes'>"
		div +=   "<h6>#{meta.title}</h6>"
		div +=   "<div class='item-desc'>#{meta.itemDescription}</div>"
		div +=   "<div class='item-format-#{meta.itemFormat}'>#{meta.itemFormat}</div>"
		div +=   "<div class='item-audio #{meta.itemHasAudio}'></div>"
		div +=   "<div class='item-duration'>#{meta.itemDuration}</div>"
		div +=   "<div class='item-name'>#{meta.itemName}</div>"
		div += "</div>"
		
		div

	#
	# build arguments to call flash video
	# @param 'meta' json object of current clip holding related metadata
	# @param 'assetId' clip id of hovered element
	#
	_buildVideo:(meta, assetId) ->
		if meta 
			if meta['itemHasSpeedView'] is 'false'
				return video = false
			else  
				return video = @_videoPlayer meta['width'],96,meta['player'],meta['flashVars'],'videoThumb',assetId 

	#
	# returns a flash video
	# @param 'width' width needed for video player
	# @param 'height' height needed for video player
	# @param 'playerUrl' url of video player
	# @param 'flashVars' url for current clip video
	# @param 'name' type of video
	# @param 'id' clip id of hovered element
	#
	_videoPlayer: (width, height, playerUrl, flashVars, name, id)  ->  
		
		div = ""
		div += 	'<object '
		div += 	  'type="application/x-shockwave-flash" '
		div +=	  'id="' + id + '" '
		div +=	  'data="' + playerUrl + '" '
		div += 	  'name="' + name + '" '
		div += 	  'align="middle" '
		div += 	  'height="' + height + '" '
		div += 	  'width="' + width + '">'
		div += 	  '<param name="FlashVars" value="' + flashVars + '">'
		div += 	  '<param value="always" name="allowScriptAccess">'
		div += 	  '<param value="' + playerUrl + '" name="movie">'
		div += 	  '<param value="high" name="quality">'
		div +=	  '<param name="wmode" value="transparent">'
		div +=	  '<param name="AllowScriptAccess" value="always">'
		div += 	  '<param name="bgcolor" value="transparent">'
		div += 	'</object>'
		
		div

exports.MiniScreener = MiniScreener
