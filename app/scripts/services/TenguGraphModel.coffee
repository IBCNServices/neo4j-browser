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

angular.module('neo4jApp.services')
  .service 'TenguGraphModel', () ->

    malformed = (rel) ->
      console.log rel
      new Error('Malformed graph: must add nodes before relationships that connect them')

    @convertNode = () ->
      (node) ->
        return false if node.deleted
        if node.logical
          new neo.models.Node(node.name, ['Logical'], {0: node.name, name: node.name})
        else
          new neo.models.Node(node.name, ['Service'], {0: node.name, name: node.name})

    @convertRelationship = (graph) ->
      (relationship) ->
        return false if relationship.deleted
        source = graph.findNode(relationship.source) or throw malformed(relationship)
        target = graph.findNode(relationship.target) or throw malformed(relationship)
        if relationship.logical
          new neo.models.Relationship(relationship.id, source, target, 'LOGICAL', {})
        else
          new neo.models.Relationship(relationship.id, source, target, relationship.label, {label: relationship.label})

    @filterRelationshipsOnNodes = (relationships, nodes) ->
      # not needed (yet)
      nodeIDs = nodes.map((n) -> n.id)
      relationships.filter((rel) -> nodeIDs.indexOf(rel.startNode) > -1 && nodeIDs.indexOf(rel.endNode) > -1)

    return @
