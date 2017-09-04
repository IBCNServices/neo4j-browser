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
  .directive('tenguStatusTable', ['Utils', (Utils) ->
      replace: yes
      restrict: 'E'
      link: (scope, elm, attr) ->
        emptyMarker = ->
          '<em>(empty)</em>'

        unbind = scope.$watch attr.tableData, (result) ->
          return unless result
          elm.html(render(result))
          #unbind()

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
        render = (result) ->
          html  = "<h3>Model: "+result.name+"</h3>"

          unknown = "<code>Unknown</code>"

          #Applications
          html += "<h4>Applications</h4>"
          if result.applications? and result.applications.length > 0
            html += "<table class='table data'>"
            html += "<thead><tr><th>Name</th><th>Status</th><th>Exposed</th><th>Charm</th><th>Units</th></tr></thead>"
            html += "<tbody>"
            for app in result.applications
              html += "<tr>"
              html += "<td>" + app.name + "</td>"
              html += "<td>" + app.status.current + " <code>" + app.status.message + "</code></td>"
              html += "<td>" + app.exposed + "</td>"
              html += "<td>" + app.charm + "</td>"
              if app.units? and app.units.length > 0
                html += "<td><ul>"
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
                html += "</ul></td>"
              else
                html += "<td><i>No Units</i></td>"
              html += "</tr>"
            html += "</tbody>"
            html += "</table>"
          else
            html += "<p>No Applications deployed.</p>"

          #Machines
          html += "<h4>Machines</h4>"
          if result.machines? and result.machines.length > 0
            html += "<table class='table data'>"
            html += "<thead><tr><th>ID</th><th>IP</th><th>Hardware</th><th>Series</th><th>Instance-ID</th><th>Containers</th></tr></thead>"
            html += "<tbody>"
            for machine in result.machines
              if machine.name?
                html += "<tr>"
                html += "<td>" + machine.name + "</td>"
                if machine.ip?
                  html += "<td><small>" + machine.ip.internal_ip + ", " + machine.ip.external_ip + "</small></td>"
                else
                  html += "<td>" + unknown + "</td>"
                if machine['hardware-characteristics']?
                  html += "<td><small>cpu cores: " + machine['hardware-characteristics']['cpu-cores'] + ", mem: " + machine['hardware-characteristics']['mem'] + " MiB</small></td>"
                else
                  html += "<td>" + unknown + "</td>"
                html += "<td><div class='token token-label' style='background-color: rgb(104, 189, 246); color: rgb(255, 255, 255);''>" + machine.series + "</div></td>"
                html += "<td>" + machine["instance-id"] + "</td>"
                if machine.containers? and machine.containers != null and machine.containers.length > 0
                  html += "<td><ul>"
                  for container in machine.containers
                    html += "<li>" + container.name + "&nbsp;" + container.series + "&nbsp;" + container.ip + "</li>"
                  html += "</ul></td>"
                else
                  html += "<td><i>None</i></td>"
                html += "</tr>"
              else
                html += "<tr><td colspan='6'>Machine not yet allocated</td></tr>"
            html += "</tbody>"
            html += "</table>"
          else
            html += "<p>No Machines instantiated yet."

          html

  ])
