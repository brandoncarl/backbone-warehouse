
###

  *** Warehouse ***

  The Warehouse class provides easier access to Backbone's collections and models.

  A "store" refers to either a model or a collection. Stores are referenced by name, and maintain
  a state. Although it includes a minimal promise spec, specifying a promise wrapper function will
  wrap all results in the corresponding promise.

  Properties
  • stores       : object containing collections and models

  Public methods
  • add          : adds instances of data stores
  • get          : returns a single store
  • fetch        : fetches a list of data stores (alias: data)
  • isFetched    : returns whether all specified stores have been fetched (alias: fetched)
  • fetchAndLoad : fetches data (like fetch) and modules (like require)

  Private methods
  • keyEvent     : returns the type of event we should listen for
  • fetchOne     : fetches a single data store

###

(->

  # Set up helpers
  isFn      = (x) -> typeof x is "function"
  isUndef   = (x) -> typeof x is "undefined"

  Warehouse = class Warehouse

    ###

      constructor

      • [Object]   stores  : keys should be store names and values the store
      • [Function] wrapper : a promise-wrapper (optional)

    ###

    constructor: (stores, wrapper) ->

      # Allow for all promises to be wrapped
      if wrapper? then Warehouse::wrap = wrapper

      @stores = {}
      @add stores or {}

      return


    ###

      function add

      Adds instances of data stores.

      [Object] stores : keys should be store names and values the store

    ###

    add: (stores) ->

      for own name, store of stores
        @stores[name] = { store : store, state : "new" }

      return


    ###

      function get

      Returns a single store (does not check if fetched).

      <String> name : the key of the desired data store

    ###

    get: (name) -> @stores[name].store


    ###

      function keyEvent

      Returns the type of event we should listen for.

      <Store> store : which store to analyze (can optionally be a string)

    ###

    keyEvent: (store) ->

      # Allow string or store to be passed
      store = @stores[store] if "string" is typeof store

      # With a model, we need to listen for the "sync" event (change isn't fired for a blank results).
      # Collections need to listen for "reset". A Collection is a subclass of a Model, so we must
      # test specifically for the Collection.
      return if store.store instanceof Backbone.Collection then "reset" else "sync"


    ###

      function fetch (alias: data)

      Fetches stores, and returns a promise resolving to an object containing the stores by name.

      <String>  names : names of stores, separated by spaces
      <Boolean> force : whether to force a refresh of the stores

    ###

    fetch: (names = "", force = false) ->

      if names is "" then return Warehouse::wrap _P.resolve({})

      # Convert string to array
      names = names.trim().split(/\s+/) if "string" is typeof names

      # Map promises
      promises = (@fetchOne(name, force) for name in names)

      Warehouse::wrap _P.all(promises).then (arr) ->
        obj = {}
        obj[name] = arr[i] for name, i in names
        _P.resolve obj


    data: (names = "", force = false) -> @fetch names, force


    ###

      function fetchOne

      Fetches a single data store and returns a promises containing said store.

      <String>   name  : name of store
      <Boolean>  force : whether to force a refresh of the store

    ###

    fetchOne: (name, force = false, done) =>

      store = @stores[name]
      ev    = @keyEvent store

      # Helper function to do the fetching
      fetchOne = ->

        store.state = "fetching"

        Warehouse::wrap new _P (resolve, reject) ->

          store.store.once ev, ->
            store.state = "fetched"
            resolve store.store

          store.store.fetch
            reset : true
            error : reject


      return switch store.state

        when "new"
          fetchOne()

        when "fetched"
          if force then fetchOne() else Warehouse::wrap _P.resolve store.store

        when "fetching"
          Warehouse::wrap new _P (resolve, reject) =>
            store.store.once ev, =>
              if not force then return resolve store.store
              store.state = "fetched"
              @fetchOne name, true


    ###

      function isFetched (alias: fetched)

      Returns whether all specified stores have been fetched.

      <String>  names : names of desired stores, separated by spaces

    ###

    isFetched: (names = "") ->

      # Convert string to array
      names = names.trim().split(/\s+/) if "string" is typeof names

      fetched = true
      for name in names
        if @stores[name].state isnt "fetched"
          fetched = false
          break

      return fetched


    fetched: (names = "") -> @isFetched names


    ###

      function fetchAndLoad

      Incorporates both data and requirejs-based loading.

    ###

    fetchAndLoad: (data = "", modules = [], done)  ->

      done = done or ->

      # Create promises array (starting with data)
      promises = [@fetch(data)]

      # When no modules are required...
      if not modules? or not modules.length
        promises.push _P.resolve []

      # Create promise form of require. We pass the necesary arguments back
      else
        if not requirejs? then throw new Error "RequireJS is needed but missing"

        promises.push new _P (resolve, reject) ->
          requirejs modules, -> resolve [].slice.call(arguments, 0)

      # The requirejs modules (if available) are in the second argument
      Warehouse::wrap _P.all(promises).then (args) -> done.apply null, [args[0]].concat(args[1])


    ###

      function fetchAll

      Fetches all collections

    ###

    fetchAll: (force = false) ->

      names = []

      for own key, val of (@stores or {})
        names.push key

      @fetch names


  ###

    Promiz (and wrappers)

    Very compact promise library. Promiz.js Copyright (c) 2014 Zolmeister: https://github.com/Zolmeister/promiz
    Updated to use Promiz with no global by removing module.exports and globals at end

  ###

  `!function(){function a(a){global.setImmediate?setImmediate(a):global.importScripts?setTimeout(a):(c++,d[c]=a,global.postMessage(c,"*"))}function b(c){function d(a,b,c,d){if("object"!=typeof j&&"function"!=typeof j||"function"!=typeof a)d();else try{var e=0;a.call(j,function(a){e++||(j=a,b())},function(a){e++||(j=a,c())})}catch(f){j=f,c()}}function e(){var a;try{a=j&&j.then}catch(b){return j=b,i=2,e()}d(a,function(){i=1,e()},function(){i=2,e()},function(){try{1==i&&"function"==typeof f?j=f(j):2==i&&"function"==typeof g&&(j=g(j),i=1)}catch(b){return j=b,l()}j==h?(j=TypeError(),l()):d(a,function(){l(3)},l,function(){l(1==i&&3)})})}if("function"!=typeof c&&void 0!=c)throw TypeError();var f,g,h=this,i=0,j=0,k=[];h.promise=h,h.resolve=function(b){return f=this.fn,g=this.er,i||(j=b,i=1,a(e)),this},h.reject=function(b){return f=this.fn,g=this.er,i||(j=b,i=2,a(e)),this},h.then=function(a,c){var d=new b;return d.fn=a,d.er=c,3==i?d.resolve(j):4==i?d.reject(j):k.push(d),d},h["catch"]=function(a){return h.then(null,a)};var l=function(a){i=a||4,k.map(function(a){3==i&&a.resolve(j)||a.reject(j)})};try{"function"==typeof c&&c(h.resolve,h.reject)}catch(m){h.reject(m)}return h}global=this;var c=1,d={},e=!1;global.setImmediate||global.addEventListener("message",function(b){if(b.source==global)if(e)a(d[b.data]);else{e=!0;try{d[b.data]()}catch(b){}delete d[b.data],e=!1}}),b.resolve=function(a){if(1!=this._d)throw TypeError();return new b(function(b){b(a)})},b.reject=function(a){if(1!=this._d)throw TypeError();return new b(function(b,c){c(a)})},b.all=function(a){function c(b,e){if(e)return d.resolve(e);if(b)return d.reject(b);var f=a.reduce(function(a,b){return b&&b.then?a+1:a},0);0==f&&d.resolve(a),a.map(function(b,d){b&&b.then&&b.then(function(b){return a[d]=b,c(),b},c)})}if(1!=this._d)throw TypeError();if(!(a instanceof Array))return b.reject(TypeError());var d=new b;return c(),d},b.race=function(a){function c(b,e){if(e)return d.resolve(e);if(b)return d.reject(b);var f=a.reduce(function(a,b){return b&&b.then?a+1:a},0);0==f&&d.resolve(a),a.map(function(a){a&&a.then&&a.then(function(a){c(null,a)},c)})}if(1!=this._d)throw TypeError();if(!(a instanceof Array))return b.reject(TypeError());if(0==a.length)return new b;var d=new b;return c(),d},b._d=1,Promiz=b}();`
  _P   = Promiz
  wrap = (x) ->
  Warehouse::wrap = (x) -> x



  ###

    Module-loading code (as used in Lo-dash)

  ###

  objectTypes = { function: true, object : true }

  # Detect free variable `exports`
  freeExports = objectTypes[typeof exports] and exports and not exports.nodeType and exports

  # Detect free variable `module`
  freeModule = objectTypes[typeof module] and module and not module.nodeType and module

  # Detect free variable `global` from Node.js
  freeGlobal = freeExports and freeModule and typeof global is "object" and global

  # Detect free variable `window`
  freeWindow = objectTypes[typeof window] and window

  # Detect the popular CommonJS extension `module.exports
  moduleExports = freeModule and freeModule.exports is freeExports and freeExports

  ###

    Used as a reference to the global object.

    The `this` value is used if it is the global object to avoid Greasemonkey's
    restricted `window` object, otherwise the `window` object is used.

  ###

  root = freeGlobal or ((freeWindow isnt (@ and @window)) and freeWindow) or @

  if typeof define is "function" and typeof define.amd is "object"and define.amd
    define "Warehouse", -> return Warehouse

  # Check for `exports` after `define` in case a build optimizer adds an `exports` object.
  else if freeExports and freeModule
    if moduleExports
      (freeModule.exports = Warehouse).Warehouse = Warehouse
    else
      freeExports.Warehouse = Warehouse
  else
    root.Warehouse = Warehouse

)()
