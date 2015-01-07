app = angular.module 'materia'
app.service 'selectedWidgetSrv', ($rootScope, $q) ->

	STORAGE_TABLE_MAX_ROWS_SHOWN = 100

	selectedData = null
	storageData = null
	instId = null

	# Refactored variables
	_widget = null
	_dateRanges = null
	_BEARD_MODE = false
	_noWidgetsFlag = false
	_scoreData = null
	_hasStorage = false
	_storageData = null

	# get and set _widget
	set = (widget) ->
		_scoreData = null
		_hasStorage = false
		_storageData = null
		_widget = widget
		$rootScope.$broadcast 'selectedWidget.update'

	get = ->
		_widget

	getSelectedId = ->
		_widget.id

	noWidgets = ->
		_noWidgetsFlag

	setNoWidgets = (bool) ->
		_noWidgetsFlag = bool
		$rootScope.$broadcast 'selectedWidget.noWidgets'

		if bool is true
			# This is temporary, we should look for an alternative to qtip
			# Or just a cleaner, more angular-y implementation in general
			$('header nav ul li:first-child').qtip
				content: 'Click here to start making a new widget!'
				position:
					corner:
						target: 'bottomMiddle'
						tooltip: 'topMiddle'
					adjust:
						y: 15
				style:
					background: '#b944cc'
					color: '#ffffff'
					padding: 10
					border:
						width: 2
						radius: 5
						color: '#b944cc'
					tip:
						corner: 'topMiddle'
						size:
							width: 15
							height: 10
				show:
					ready: true

	getScoreSummaries = ->
		deferred = $q.defer()

		if _scoreData then deferred.resolve _scoreData
		else
			Materia.Coms.Json.send 'score_summary_get', [_widget.id, true], (data) ->

				_scoreData =
					list: []
					map: {}
					last: undefined

				if data isnt null and data.length > 0
					o = {}
					last = data[0].id
					for d in data
						o[d.id] = d

					## START DUMMY SEMESTER CODE ##
					# Leaving this in until old semester support is properly tested!
					# for index in [1..5]
					# 	dataClone = {}
					# 	angular.copy data[0], dataClone

					# 	dataClone.year = "200" + index

					# 	data[index] = dataClone
					## END DUMMY SEMESTER CODE ##

					_scoreData =
						list: data
						map: o
						last: data[0]

				deferred.resolve _scoreData

		deferred.promise

	getUserPermissions = ->
		deferred = $q.defer()
		Materia.Coms.Json.send 'permissions_get', [0, _widget.id], (perms) ->
			permsObject =
				user : perms.user_perms
				widget: perms.widget_user_perms

			deferred.resolve permsObject

		deferred.promise

	getPlayLogsForSemester = (term, year) ->
		deferred = $q.defer()

		Materia.Coms.Json.send 'play_logs_get', [_widget.id, term, year], (logs) ->

			semesterKey = "#{year}#{term.toLowerCase()}"

			logsForSemester = []

			angular.forEach logs, (log, key) ->

				timestamp = log.time
				logMeta = getSemesterFromTimestamp(timestamp)
				semesterString = logMeta.year + logMeta.semester.toLowerCase()

				if semesterString == semesterKey
					logsForSemester.push log

			deferred.resolve logsForSemester
		deferred.promise

	getDateRanges = ->
		deferred = $q.defer()
		unless _dateRanges?
			Materia.Coms.Json.send 'semester_date_ranges_get', [], (data) ->
				_dateRanges = data
				deferred.resolve data
		else
			deferred.resolve _dateRanges
		deferred.promise

	# getCurrentSemester = ->
	# 	return selectedData.year + ' ' + selectedData.term

	getSemesterFromTimestamp = (timestamp) ->
		for range in _dateRanges
			return range if timestamp >= parseInt(range.start, 10) && timestamp <= parseInt(range.end, 10)
		return undefined

	setStorageFlag = (flag) ->
		_hasStorage = flag

		if flag
			$rootScope.$broadcast 'selectedWidget.hasStorage'

	getStorageFlag = ->
		_hasStorage

	getStorageData = ->

		deferred = $q.defer()

		if _storageData? then deferred.resolve _storageData
		else
			Materia.Coms.Json.send 'play_storage_get', [_widget.id], (data) ->

				_storageData = {}

				temp = {}

				# process semester data and organize by table name
				angular.forEach data, (tableData, tableName) ->

					temp[tableName] = processDataIntoSemesters tableData

				# have to loop through each table present in the storage data
				angular.forEach temp, (semesters, tableName) ->

					# have to loop through each semester contained within each table
					angular.forEach semesters, (semesterData, semesterId) ->

						if typeof _storageData[semesterId] == 'undefined'
							_storageData[semesterId] = {}

						if semesterData.length > STORAGE_TABLE_MAX_ROWS_SHOWN
							_storageData[semesterId][tableName] = {truncated:true, total:semesterData.length, data:semesterData.slice(0, STORAGE_TABLE_MAX_ROWS_SHOWN)}
						else
							_storageData[semesterId][tableName] = {truncated:false, data:semesterData}

						_storageData[semesterId][tableName].data = normalizeStorageDataColumns _storageData[semesterId][tableName].data

				deferred.resolve _storageData

		deferred.promise

	processDataIntoSemesters = (logs) ->
		semesters = {}
		timestamp = null

		angular.forEach logs, (log, index) ->

			timestamp = log.play.time
			logMeta = getSemesterFromTimestamp timestamp
			semesterString = logMeta.year + ' ' + logMeta.semester.toLowerCase()

			unless semesters[semesterString]
				semesters[semesterString] = []
			semesters[semesterString].push log

		semesters

	#  storage data doesn't really enforce a schema.
	#  this function determines every field used throughout the
	#  storage data and then applies that schema to each item.
	normalizeStorageDataColumns = (rows) ->
		#  go through all the rows and collect the fields used:
		curRow
		fields = {}
		for r in rows
			curRow = r.data
			for j in curRow
				if typeof j == 'undefined'
					j = null

		#  now go through each row again and add in the missing fields
		for r in rows
			r.data = $.extend({}, fields, r.data)

		rows

	getMaxRows = ->
		STORAGE_TABLE_MAX_ROWS_SHOWN

	updateAvailability = (attempts, open_at, close_at) ->
		_widget.attempts = attempts
		_widget.open_at = open_at
		_widget.close_at = close_at
		$rootScope.$broadcast 'selectedWidget.update'

	noAccess = ->
		$rootScope.$broadcast 'selectedWidget.noAccess'

	set : set
	get : get
	getSelectedId: getSelectedId
	# setSelectedId: setSelectedId
	noWidgets: noWidgets
	setNoWidgets: setNoWidgets
	getScoreSummaries: getScoreSummaries
	getUserPermissions: getUserPermissions
	getPlayLogsForSemester: getPlayLogsForSemester
	getDateRanges: getDateRanges
	# getCurrentSemester: getCurrentSemester
	getSemesterFromTimestamp: getSemesterFromTimestamp
	getStorageData : getStorageData
	setStorageFlag : setStorageFlag
	getStorageData: getStorageData
	getMaxRows : getMaxRows
	updateAvailability: updateAvailability
	noAccess: noAccess
