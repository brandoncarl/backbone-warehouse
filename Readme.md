# Backbone Warehouse

Backbone Warehouse is like RequireJS, but for data, file AND modules. It allows easy access of data
across your application, with features like group loading.

Warehouse uses promises for data fetching, but retains the RequireJS-style callback for its helper
function, `fetchAndLoad`. Underneath, encapsulates Backbone's sync methods for data, and wraps
RequireJS for files and modules.

In all examples, a "Store" refers to *either* a Model or a Collection.


## Installation

```base
$ bower install --save backbone-warehouse requirejs
```

## Setup

```js

  // Construct your collections and models, and pass them in!
  var warehouse = new Warehouse({
    todos    : new Todos(),
    contacts : new Contacts(),
    profile  : new Profile()
  });

```


## Examples

```js

  // We can access a collection or model before fetching, just like in Backbone
  var myTodos = warehouse.get("todos");

  // We can check whether a list of Stores have been fetched. All Stores must be fetched in
  // order to return true.
  var isFetched = warehouse.isFetched("todos contacts profile")
  console.log(isFetched);   // prints false

  // Simple data fetch (assumes Backbone is a global)
  warehouse.fetch("todos contacts profile").then(function(data) {

    // This will not be executed until all data has been fetched
    console.log(data.todos);

  });

  // Data and module-loading (assumes require is a global)
  // This is the only function that uses "async" callbacks, so that modules can be named in
  // the callback function.
  warehouse.fetchAndLoad("todos", ["jquery"], function(data, jquery) {

  });

```


## API

### constructor(Object stores, [promiseWrapper])

### Warehouse.add(Object stores)

Adds instances of data stores.


### Warehouse.get(String name)

Returns a single store (does not check if fetched).


### Warehouse.fetch(String names, [force = false])

Fetches stores, and returns a promise resolving to an object containing the stores by name.


### Warehouse.data

Alias for `fetch`


### Warehouse.isFetched(String names)

Returns whether all specified stores have been fetched.


### Warehouse.fetched

Alias for `isFetched`


### Warehouse.fetchAndLoad(String names, Array modules, callback)

Incorporates both data and RequireJS-based loading.

`callback` should be of form `(data, module1, module2, ...)`

### Warehouse.fetchAll([force = false])

Fetches all collections. Not recommended (time consuming), but a useful shorthand operator upon initialization.
