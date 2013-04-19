app = angular.module('browser', ['ui.bootstrap'])

# app.run ($rootScope) ->

angular.module('browser').factory 'API', ['$http', ($http) ->
  {
    keys: -> $http.get("/keys.json", { isArray: true}).then (e) -> e.data,
    get: (params) -> $http.get("/key.json", { params: params }).then (e) -> e.data
  }
]

@BrowserCtrl = ($scope, API) ->
  $scope.keys = API.keys()

  $scope.show = (key) ->
    API.get(key: key.full).then (e) ->
      $scope.key = e

      update_start_stop = ->
        $scope.list.start = per_page * ($scope.list.current - 1)
        $scope.list.stop = (per_page * $scope.list.current) - 1

      switch e.type
        when "list"
          per_page = 100
          $scope.list =
            pages:    parseInt(e.length / 100)
            current:  1
            max:      10
          update_start_stop()

      $scope.$watch "list.current", () ->
        update_start_stop()
        API.get(
          key:    key.full
          start: $scope.list.start
          stop:  $scope.list.stop
        ).then((e) -> $scope.key = e)


