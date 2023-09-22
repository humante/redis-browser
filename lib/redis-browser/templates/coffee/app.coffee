app = angular.module('browser', ['ui.bootstrap', 'LocalStorageModule'])

app.config ($httpProvider) ->
  funShow = (data, headersGetter) ->
    document.getElementById('http-loader').style.display = "block"
    data

  $httpProvider.defaults.transformRequest.push(funShow)
  $httpProvider.responseInterceptors.push('HttpLoader')

app.factory 'HttpLoader', ['$q', ($q) ->
  (promise) ->
    promise.then (response) ->
      document.getElementById('http-loader').style.display = "none"
      response
    , (response) ->
      document.getElementById('http-loader').style.display = "none"
      response
]

app.factory 'API', ['$http', ($http) ->
  (connection) ->
    ps = {connection: connection}
    {
      exportCSV: (params) -> $http.get("#{jsEnv.root_path}export-csv", {
        params: angular.extend({}, ps, params)
      }).then (e) -> e,

      ping: () -> $http.get("#{jsEnv.root_path}ping.json", {
        params: ps
      }).then (e) -> e.data,

      keys: (namespace) -> $http.get("#{jsEnv.root_path}keys.json", {
        params: angular.extend({}, ps, {namespace: namespace})
      }).then (e) -> e.data,

      get: (params) -> $http.get("#{jsEnv.root_path}key.json", {
        params: angular.extend({}, ps, params)
      }).then (e) -> e.data

      delete: (params) -> $http.delete("#{jsEnv.root_path}key.json", {
        params: angular.extend({}, ps, params)
      })
    }
]

app.directive 'prettyprint', ->
    restrict: 'AE'
    link: (scope, element, attrs) ->
      scope.$watch attrs.prettyprint, (value) ->
        element[0].innerHTML = PR.prettyPrintOne(value)

@BrowserCtrl = ($scope, API, localStorageService, $dialog) ->
  # Internal functions
  fetchValue = ->
    $scope.api.get(
      key:    $scope.key.full
      start:  $scope.list.start
      stop:   $scope.list.stop
    ).then((e) -> $scope.key.values = e.values)

  updateList = ->
    $scope.list.pages = Math.ceil($scope.key.length / $scope.list.per_page)
    $scope.list.start = $scope.list.per_page * ($scope.list.current - 1)
    $scope.list.stop = ($scope.list.per_page * $scope.list.current) - 1


  # Init variables
  $scope.keys = []
  $scope.key = {type: "empty"}
  $scope.list = {}
  $scope.connections = jsEnv.connections
  $scope.config = {connection: jsEnv.connection}

  db = localStorageService

  $scope.config =
    connection: db.get("connection") || $scope.config.connection
    hashView:   db.get("hashView") || "table"

    open: ->
      $scope.config.show = true
    close: ->
      $scope.config.show = false
    save: ->
      # Check connection
      $scope.config.error = null

      test = API($scope.config.connection)
      test.ping().then (resp) ->
        if resp.ok
          db.add("connection", $scope.config.connection)
          $scope.api = API($scope.config.connection)

          $scope.fetchKeys()
          $scope.show($scope.key)

          $scope.config.close()
        else
          $scope.config.error = resp.error

    setHashView: (view) ->
      $scope.config.hashView = view
      db.add("hashView", view)

    modalOpts:
      backdropFade: true
      dialogFade: true

  $scope.export =
    filename: "redis-dump.csv"

    open: ->
      $scope.export.show = true
      $scope.export.include = $scope.key.full || "*"
      $scope.export.exclude = $scope.connections[$scope.config.connection].exclude_pattern

    close: ->
      $scope.export.show = false
      $scope.export.error = null

    run: ->
      $scope.api.exportCSV(
        include: $scope.export.include,
        exclude: $scope.export.exclude
      ).then (response) ->
        $scope.export.error = null

        content = response.data
        if response.headers('Content-Type').includes("text/csv")
          hiddenElement = document.createElement('a')

          hiddenElement.href = 'data:attachment/csv,' + encodeURI(content)
          hiddenElement.target = '_blank'
          hiddenElement.download = $scope.export.filename
          hiddenElement.click()

          $scope.config.close()

          destroyA = setInterval( ->
              hiddenElement.remove()
              clearInterval(destroyA)
            , 5000
          )

        else
          $scope.export.error = content.error

  $scope.api = API($scope.config.connection)


  # Scope functions
  $scope.fetchKeys = ->
    $scope.keys = $scope.api.keys()

  $scope.show = (key) ->
    $scope.keyOpen(key)
    $scope.api.get(key: key.full).then((e) ->
      $scope.key = e

      switch e.type
        when "list"
          $scope.list =
            per_page: db.get("per_page") || 100
            current: 1
            max: 10

          updateList()

        when "hash"
          e.json = {}
          for k,v of e.value
            e.json[k] = v.value
    )

  $scope.keyOpen = (key) ->
    console.log key.children
    if !key.children
      $scope.api.keys(key.full).then (keys) ->
        key.children = keys
        console.log key.children

    key.open = true

  $scope.keyClose = (key) ->
    key.open = false


  $scope.setPerPage = (i) ->
    db.add("per_page", i)
    $scope.list.per_page = i
    $scope.list.current = 1
    updateList()
    fetchValue()

  $scope.deleteKey = (key) ->
    title = "Are you sure?"
    msg = "Are you sure you want to delete key \n #{key.name}"
    btns = [
      {result:'cancel', label: 'Cancel'}
      {result:'delete', label: 'Delete', cssClass: 'btn-danger'}
    ]

    $dialog.messageBox(title, msg, btns)
      .open()
      .then((result) ->
        if result == "delete"
          $scope.api.delete(key: key.name)
          $scope.show($scope.key)
      )

  $scope.deleteAll = ->
    title = "Are you sure?"
    msg = "Are you sure you want to delete ALL keys matching \n #{$scope.key.full}"
    btns = [
      {result:'cancel', label: 'Cancel'}
      {result:'delete', label: 'Delete ALL', cssClass: 'btn-danger'}
    ]

    $dialog.messageBox(title, msg, btns)
      .open()
      .then((result) ->
        if result == "delete"
          $scope.api.delete(key: $scope.key.full)
          $scope.show($scope.key)
      )



  # Scope watchers
  $scope.$watch "list.current", () ->
    if $scope.key.type == "list"
      updateList()
      fetchValue()


  # Init
  $scope.fetchKeys()


  # If user has loaded page from a bookmark of a specific key...
  if ( window.location.hash != null && window.location.hash != "" )
    # Show the selected key
    key = {name: "", full: window.location.hash.substr(2), count: 1, $$hashKey: ""}
    $scope.show( key )
    # TODO: expand tree to show this key
