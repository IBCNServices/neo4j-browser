###!
Copyright (c) 2002-2016 "Neo Technology,"
Network Engine for Objects in Lund AB [http://neotechnology.com]

This file is part of Neo4j.

Neo4j is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
###

'use strict';
angular.module('neo4jApp.directives')
  .directive('tenguUnitStatus', ['Utils', (Utils) ->
      replace: yes
      restrict: 'E'
      link: (scope, elm, attr) ->
        emptyMarker = ->
          '<em>(empty)</em>'

        unbind = scope.$watch attr.tableData, (result) ->
          return unless result
          elm.html(render(result))

        json2html = (obj) ->
          return emptyMarker() unless Object.keys(obj).length
          html  = "<table class='json-object'><tbody>"
          html += "<tr><th>#{k}</th><td>#{cell2html(v)}</td></tr>" for own k, v of obj
          html += "</tbody></table>"
          html

        cell2html = (cell) ->
          if angular.isString(cell)
            return emptyMarker() unless cell.length
            Utils.escapeHTML(cell)
          else if angular.isArray(cell)
            "["+((cell2html(el) for el in cell).join(', '))+"]"
          else if angular.isObject(cell)
            json2html(cell)
          else
            Utils.escapeHTML(JSON.stringify(cell))

        # Manual rendering function due to performance reasons
        # (repeat watchers are expensive)
        render = (app) ->
          html = ""
          if app.units? and app.units.length > 1
            html += "<ul>"
            for unit in app.units
              html += "<li>" + unit.name
              if unit.machine? and unit.machine != ""
                html += " [" + unit.machine + "]"
              if unit['public-ip']? and unit['public-ip'] != ""
                html += " <code><small>" + unit['public-ip']
                if app.exposed and unit.ports? and unit.ports != null and unit.ports.length > 0
                  html += "["
                  for port in unit.ports
                    html += "<a target='_blank' href='http://" + unit['public-ip'] + ":" + port.number + "'>" + port.number + "</a> "
                  html += "]"
                html += " <a target='_blank' href='ssh://ubuntu@" + unit['public-ip'] + "' tooltip='Connect via SSH'><i class='fa fa-terminal' aria-hidden='true'></i></a>"
                html += "</small></code>"
              html += "</li>"
            html += "</ul>"
          else if app.units? and app.units.length == 1
            unit = app.units[0]
            html = unit.name
            if unit.machine? and unit.machine != ""
              html += " [" + unit.machine + "]"
            if unit['public-ip']? and unit['public-ip'] != ""
              html += " <code><small>" + unit['public-ip']
              if app.exposed and unit.ports? and unit.ports != null and unit.ports.length > 0
                html += "["
                for port in unit.ports
                  html += "<a target='_blank' href='http://" + unit['public-ip'] + ":" + port.number + "'>" + port.number + "</a> "
                html += "]"
              html += " <a target='_blank' href='ssh://ubuntu@" + unit['public-ip'] + "' tooltip='Connect via SSH'><i class='fa fa-terminal' aria-hidden='true'></i></a>"
              html += "</small></code>"
          else
            html += "<i>No Units</i>"

          html

  ])
