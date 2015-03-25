
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
  __promise = null
  __all     = null
  isFn      = (x) -> typeof x is "function"
  isUndef   = (x) -> typeof x is "undefined"

  # Async helper all
  all = (tasks, done) ->

    n = tasks.length
    results = {}

    onComplete = ->
      data = []
      data.push(results[i]) for i in [0...tasks.length]
      done null, data

    onProgress = (pos) ->
      (err, single) ->
        if err then return done err
        results[pos] = single
        if --n is 0 then onComplete()

    task(onProgress(i)) for task, i in tasks


  Warehouse = class Warehouse

    ###

      constructor

      • [Object] stores  : keys should be store names and values the store
      • [Object] plib    : a promise-wrapper (optional) { promise, all }

    ###

    constructor: (stores, plib) ->

      if plib?
        __promise = plib.promise
        __all     = plib.all

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
