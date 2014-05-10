ViewFinderView = require './view-finder-view'
path = require 'path'
fs = require 'fs'
pluralize = require 'pluralize'

module.exports =
  activate: (state) ->
    atom.workspaceView.command 'rails-transporter:toggle-view-finder', =>
      @createViewFinderView().toggle()
    atom.workspaceView.command 'rails-transporter:open-model', =>
      @open('model')
    atom.workspaceView.command 'rails-transporter:open-helper', =>
      @open('helper')
    atom.workspaceView.command 'rails-transporter:open-partial-template', =>
      @open('partial')
    atom.workspaceView.command 'rails-transporter:open-spec', =>
      @open('spec')
    atom.workspaceView.command 'rails-transporter:open-asset', =>
      @open('asset')



  deactivate: ->
    if @viewFinderView?
      @viewFinderView.destroy()
      
  createViewFinderView: ->
    unless @viewFinderView?
      @viewFinderView = new ViewFinderView()
      
    @viewFinderView

  open: (type) ->
    editor = atom.workspace.getActiveEditor()
    currentFile = editor.getPath()
    if currentFile.search(/app\/controllers\/.+_controller.rb$/) isnt -1
      resourceName = pluralize.singular(currentFile.match(/([\w]+)_controller\.rb$/)[1])
      if type is 'model'
        targetFile = currentFile.replace('controllers', 'models')
                          .replace(/([\w]+)_controller\.rb$/, "#{resourceName}.rb")
      else if type is 'helper'
        targetFile = currentFile.replace('controllers', 'helpers')
                          .replace('controller.rb', 'helper.rb')
      else if type is 'spec'
        targetFile = currentFile.replace('app/controllers', 'spec/controllers')
                                .replace('controller.rb', 'controller_spec.rb')
                                
    else if currentFile.indexOf("app/models/") isnt -1
      if type is 'spec'
        targetFile = currentFile.replace('app/models', 'spec/models')
                                .replace('.rb', '_spec.rb')
                                
    else if currentFile.indexOf("app/views/") isnt -1
      if type is 'partial'
        line = editor.getCursor().getCurrentBufferLine()
        if line.indexOf("render") isnt -1
          if line.indexOf("partial") is -1
            result = line.match(/render\s+["']([a-zA-Z_/]+)["']/)
            targetFile = @partialFullPath(currentFile, result[1])
          else
            result = line.match(/render\s+\:?partial(\s*=>|:*)\s*["']([a-zA-Z_/]+)["']/)
            targetFile = @partialFullPath(currentFile, result[2])
      else if type is 'asset'
        line = editor.getCursor().getCurrentBufferLine()
        if line.indexOf("javascript_include_tag") isnt -1
          result = line.match(/javascript_include_tag\s*\(?\s*["']([a-zA-Z0-9_\-\./]+)["']/)
          targetFile = @assetJSFullPath(result[1])
        else if line.indexOf("stylesheet_link_tag") isnt -1
          result = line.match(/stylesheet_link_tag\s*\(?\s*["']([a-zA-Z0-9_\-\./]+)["']/)
          targetFile = @assetCSSFullPath(result[1])

    else if currentFile.search(/app\/helpers\/.+_helper.rb$/) isnt -1
      if type is 'spec'
        targetFile = currentFile.replace('app/helpers', 'spec/helpers')
                                .replace('.rb', '_spec.rb')
                                
    return unless targetFile?
    files = if typeof(targetFile) is 'string' then [targetFile] else targetFile
    for file in files
      atom.workspaceView.open(file) if fs.existsSync(file)

  partialFullPath: (currentFile, partialName) ->
    tmplEngine = path.extname(currentFile)
    ext = path.extname(path.basename(currentFile, tmplEngine))
    if partialName.indexOf("/") is -1
      "#{path.dirname(currentFile)}/_#{partialName}#{ext}#{tmplEngine}"
    else
      "#{atom.project.getPath()}/app/views/#{path.dirname(partialName)}/_#{path.basename(partialName)}#{ext}#{tmplEngine}"
  
  assetJSFullPath: (assetName) ->
    if path.extname(assetName) is ""
      fileName = "#{path.basename(assetName)}.js"
    else
      fileName = path.basename(assetName)
      
    if assetName.match(/^\//)
      "#{atom.project.getPath()}/public/#{path.dirname(assetName)}/#{fileName}"
    else
      [
        "#{atom.project.getPath()}/app/assets/javascripts/#{path.dirname(assetName)}/#{fileName}"
        "#{atom.project.getPath()}/vendor/assets/javascripts/#{path.dirname(assetName)}/#{fileName}"
      ]

  assetCSSFullPath: (assetName) ->
    if path.extname(assetName) is ""
      fileName = "#{path.basename(assetName)}.css"
    else
      fileName = path.basename(assetName)
      
    if assetName.match(/^\//)
      "#{atom.project.getPath()}/public/#{path.dirname(assetName)}/#{fileName}"
    else
      [
        "#{atom.project.getPath()}/app/assets/stylesheets/#{path.dirname(assetName)}/#{fileName}"
        "#{atom.project.getPath()}/vendor/assets/stylesheets/#{path.dirname(assetName)}/#{fileName}"
      ]