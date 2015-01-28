_        = require 'lodash'
Promise  = require 'bluebird'
path     = require 'path'
Request  = require 'request-promise'
Project  = require './project'
API_URL  = process.env.API_URL or 'localhost:1234'
AppInfo  = require './app_info'

class Keys
  constructor: (projectRoot) ->
    if not (@ instanceof Keys)
      return new Keys(projectRoot)

    if not projectRoot
      throw new Error("Instantiating lib/keys requires a projectRoot!")

    @appInfo     = new AppInfo
    @project     = Project(projectRoot)

  _getNewKeyRange: (projectId) ->
    Request.post("http://#{API_URL}/projects/#{projectId}/keys")

  _convertToId: (index) ->
    ival = index.toString(36)
    ## 0 pad number to ensure three digits
    [0,0,0].slice(ival.length).join("") + ival

  _getProjectKeyRange: (id) ->
    @appInfo.getProject(id).get("RANGE")

  ## Lookup the next Test integer and update
  ## offline location of sync
  getNextTestNumber: (projectId) ->
    @_getProjectKeyRange(projectId)
    .then (range) =>
      return @_getNewKeyRange(projectId) if range.start is range.end

      range.start += 1
      range
    .then (range) =>
      range = JSON.parse(range) if _.isString(range)
      @appInfo.updateRange(projectId, range)
      .return(range.start)

  nextKey: ->
    @project.ensureProjectId().bind(@)
    .then (projectId) ->
      @appInfo.ensureExists().bind(@)
      .then -> @appInfo.ensureProject(projectId)
      .then -> @getNextTestNumber(projectId)
      .then @_convertToId

module.exports = Keys
