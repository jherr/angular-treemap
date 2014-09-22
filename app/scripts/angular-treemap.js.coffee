# Copyright 2013 Lithium Technologies, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

angular.module('angular-treemap', []).directive 'treemap', () ->
	elem = angular.element( '<div class="angular-treemap"/>' )
	{
		restrict: 'A'

		scope:
			treemap: '='
			name: '&'
			detail: '&'
			colorlow: '@'
			colormid: '@'
			colorhigh: '@'

		compile: ( tElem ) =>
			tElem.append elem

		controller: ( $scope ) =>
			$scope.find_color_range = (d) ->
				$scope.state.min_color = d.color if d.color < $scope.state.min_color
				$scope.state.max_color = d.color if d.color > $scope.state.max_color
				if d.children
					for c in d.children
						$scope.find_color_range c

			$scope.resize = () ->
				$scope.state.width = $($scope.state.parent).width()
				$scope.state.height = $scope.state.width * 0.6
				$scope.state.host
					.attr
						width: $scope.state.width
						height: $scope.state.height + 20

				$scope.treemap.dx = $scope.state.width
				$scope.treemap.dy = $scope.state.height

				$scope.state.x = d3.scale.linear()
				.domain( [ 0, $scope.state.width ] )
				.range( [ 0, $scope.state.width ] )

				$scope.state.y = d3.scale.linear()
				.domain( [ 0, $scope.state.height ] )
				.range( [ 0, $scope.state.height ] )

				$scope.layout $scope.treemap

				$scope.state.svg
					.selectAll( 'rect.parent' )
					.call ( r ) =>
						$scope.rect( r )

				$scope.state.svg
					.selectAll( 'text.js-label' )
					.call ( text ) =>
						$scope.text( text )

				$scope.state.svg
					.selectAll( 'rect.child' )
					.call ( r ) =>
						$scope.rect( r )

			$scope.accumulate = (d) ->
				if d.children then d.value = d.children.reduce (p, v) =>
					p + $scope.accumulate(v)
				, 0
				else
					d.value

			$scope.layout = (d) ->
				if d.children
					$scope.state.treemap.nodes children: d.children
					for c in d.children
						c.x = d.x + c.x * d.dx
						c.y = d.y + c.y * d.dy
						c.dx *= d.dx
						c.dy *= d.dy
						c.parent = d
						$scope.layout c

			$scope.text = (text) =>
				text.attr
					x: (d) => $scope.state.x(d.x) + 6
					y: (d) => $scope.state.y(d.y) + 6

			$scope.rect = (rect) =>
				rect.attr
					fill: ( d ) =>
						$scope.state.color( d.color )
					x: (d) =>
						$scope.state.x( d.x ) + 1
					y: (d) =>
						$scope.state.y( d.y ) + 1
					width: (d) =>
						w = $scope.state.x(d.x + d.dx) - $scope.state.x(d.x) - 2
						if w >= 0 then w else 0
					height: (d) =>
						h = $scope.state.y(d.y + d.dy) - $scope.state.y(d.y) - 2
						if h >= 0 then h else 0

			$scope.transition = (d,g1) =>
				return if $scope.state.transitioning or not d
				$scope.state.transitioning = true

				g2 = $scope.display(d)

				t1 = g1.transition().duration(750)
				t2 = g2.transition().duration(750)

				$scope.state.x.domain [d.x, d.x + d.dx]
				$scope.state.y.domain [d.y, d.y + d.dy]

				$scope.state.svg.style 'shape-rendering', null

				$scope.state.svg.selectAll('.depth').sort (a, b) ->
					a.depth - b.depth

				g2.selectAll('text').style 'fill-opacity', 0

				t1.selectAll('text').call ( text ) =>
					$scope.text( text ).style 'fill-opacity', 0
				t2.selectAll('text').call ( text ) =>
					$scope.text( text ).style 'fill-opacity', 1
				t1.selectAll('rect').call ( r ) =>
					$scope.rect r
				t2.selectAll('rect').call ( r ) =>
					$scope.rect r

				t1.remove().each 'end', =>
					$scope.state.svg.style 'shape-rendering', 'crispEdges'
					$scope.state.transitioning = false

			$scope.display = (d) =>
				g1 = $scope.state.svg
					.insert( 'g', '.grandparent' )
					.datum( d )
					.attr( 'class', 'depth' )

				$scope.state.grandparent
					.datum(d.parent)
					.on 'click', ( d ) =>
						$scope.transition d, g1
					.select( 'text' )
					.text $scope.formatName(d)

				g = g1
					.selectAll( 'g' )
					.data( d.children )
					.enter()
					.append( 'g' )

				g
					.filter ( d ) ->
						d.children
					.classed( 'children', true )
					.on 'click', ( d ) =>
						$scope.transition d, g1

				g
					.filter ( d ) ->
						!d.children
					.classed( 'children', true )
					.on 'click', ( d ) =>
						$scope.curNode = d
						$scope.$apply "detail({node:curNode})"

				g
					.selectAll( '.child' )
					.data ( d ) ->
						d.children or [ d ]
					.enter()
					.append( 'rect' )
					.attr( 'class', 'child' )
					.call ( r ) => $scope.rect( r )

				g
					.append( 'rect' )
					.attr( 'class', 'parent' )
					.style(
						'fill-opacity': 0.1
						'stroke': 'black'
						'stroke-width': '1'
						'stroke-opacity': '0.8'
					)
					.call ( r ) =>
						$scope.rect( r )
					.append( 'title' )
					.text ( d ) =>
						$scope.state.formatNumber d.value

				g
					.append( 'text' )
					.attr( 'class', 'js-label' )
					.attr( 'dy', '.75em' )
					.text ( d ) ->
						$scope.curName = d.name
						if $scope.name then $scope.$eval("name({name:curName})") else d.name
					.call ( text ) => $scope.text( text )

				g

			$scope.formatName = ( d ) =>
				if d.parent then $scope.formatName( d.parent ) + '.' + d.name else d.name

			$scope.state =
				margin:
					left: 0
					top: 20
				parent: elem
			$scope.state.width = $(elem).width()
			$scope.state.height = $scope.state.width * 0.6
			$scope.state.ratio = $scope.state.height / $scope.state.width * 0.5 * (1 + Math.sqrt(5))

			$scope.$watch 'treemap', ( oldValue, newValue ) =>
				return if oldValue is newValue
				return unless newValue

				$($scope.state.parent).empty()

				$scope.state.min_color = 10000
				$scope.state.max_color = -10000
				$scope.find_color_range( $scope.treemap )

				domain_range = [
					$scope.state.min_color,
					$scope.state.min_color + ( ( $scope.state.max_color - $scope.state.min_color ) / 2 ),
					$scope.state.max_color
				]

				$scope.colorlow = 'red' unless $scope.colorlow?
				$scope.colormid = 'white' unless $scope.colormid?
				$scope.colorhigh = 'green' unless $scope.colorhigh?

				$scope.state.color = d3.scale.linear()
					.domain( domain_range )
					.range( [ $scope.colorlow, $scope.colormid, $scope.colorhigh ] )

				$scope.state.treemap = d3.layout.treemap()
				.children ( d, depth ) ->
					if depth then null else d.children
				.sort ( a, b ) ->
					a.value - b.value
				.ratio( $scope.state.ratio )
				.round( false )
				.sticky( false )

				$scope.state.host = d3
					.select( $scope.state.parent[ 0 ] )
					.append( 'svg' )

				$scope.state.svg = $scope.state.host
					.append( 'g' )
					.attr( 'transform', "translate(#{$scope.state.margin.left},#{$scope.state.margin.top})" )
					.style( 'shape-rendering', 'crispEdges' )

				$scope.state.grandparent = $scope.state.svg.append('g')
				.attr('class', 'grandparent')

				$scope.state.grandparent
					.append('rect')
					.attr(
						y: -$scope.state.margin.top
						width: '100%'
						height: $scope.state.margin.top + 5
					)

				$scope.state.grandparent
					.append('text')
					.attr(
						x: 6
						y: 6 - $scope.state.margin.top
						dy: '0.75em'
					)

				$scope.treemap.x = $scope.treemap.y = 0
				$scope.treemap.depth = 0
				$scope.state.transitioning = undefined
				$scope.state.formatNumber = d3.format(',d')

				$scope.treemap.dx = $scope.state.width
				$scope.treemap.dy = $scope.state.height

				$scope.state.x = d3.scale.linear()
				.domain( [ 0, $scope.state.width ] )
				.range( [ 0, $scope.state.width ] )

				$scope.state.y = d3.scale.linear()
				.domain( [ 0, $scope.state.height ] )
				.range( [ 0, $scope.state.height ] )

				$scope.accumulate( $scope.treemap )
				$scope.layout( $scope.treemap )
				$scope.display( $scope.treemap )
				$scope.resize()
	}
