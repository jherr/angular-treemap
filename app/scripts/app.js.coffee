"use strict"
angular.module("treemapApp", ['angular-treemap']).controller 'treeCtl', ( $scope, $http ) ->
	$scope.formatName = ( name ) =>
		name

	$scope.onDetail = ( node ) =>
		console.log node

	$http.get('/flare_with_color.json').success ( data ) =>
		$scope.tree = data

	$scope.tree = {}
