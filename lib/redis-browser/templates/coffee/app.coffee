app = angular.module('browser', ['ui.bootstrap'])

# app.run ($rootScope) ->

angular.module('browser').factory 'API', ['$http', ($http) ->
  {
    keys: -> $http.get("/keys.json", { isArray: true}).then (e) -> e.data,
    get: (params) -> $http.get("/key.json", { params: params }).then (e) -> e.data
  }
]

@BrowserCtrl = ($scope, API) ->
  $scope.config =
    host: "127.0.0.1"
    port: 6379
    database: 0
    databases: [0..15]
    open: ->
      $scope.config.show = true
    close: ->
      $scope.config.show = false
    save: ->
      $scope.config.close() # TODO: Do something with config
    opts:
      backdropFade: true
      dialogFade: true


  $scope.configure = () ->
    $scope.configuring = true

  $scope.keys = API.keys()
  $scope.key = {type: "empty"}

  $scope.show = (key) ->
    API.get(key: key.full).then (e) ->
      $scope.key = e

      update = ->
        $scope.list.pages = Math.ceil($scope.key.length / $scope.list.per_page)
        $scope.list.start = $scope.list.per_page * ($scope.list.current - 1)
        $scope.list.stop = ($scope.list.per_page * $scope.list.current) - 1

      $scope.setPerPage = (i) ->
        $scope.list.per_page = i
        $scope.list.current = 1
        update()
        fetch()

      fetch = ->
        API.get(
          key:    key.full
          start: $scope.list.start
          stop:  $scope.list.stop
        ).then((e) -> $scope.key = e)

      switch e.type
        when "list"
          $scope.list =
            per_page: 100
            current: 1
            max: 10

          update()

          $scope.$watch "list.current", () ->
            update()
            fetch()


