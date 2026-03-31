# Changelog

## 0.3.0

### New cops

- `Harness/JobMethodLength` - Enforces maximum method length in jobs. Jobs should be thin and delegate to service objects.
- `Harness/NoPresentationInModels` - Flags presentation logic (HTML generation, route helpers, ActionController helpers) in models.

## 0.2.0

### Changed

- Aligned cop messaging with layered design principles. Model cops no longer suggest extracting to services; query cops suggest model scopes first.

## 0.1.0

### New cops

- `Harness/ControllerMethodLength` - Enforces maximum method length in controllers.
- `Harness/ModelMethodLength` - Enforces maximum method length in models.
- `Harness/RestfulActions` - Controllers should only define the 7 RESTful actions.
- `Harness/ServiceInterface` - Service objects must define `call` or `save`.
- `Harness/NoQueriesInControllers` - No ActiveRecord queries in controllers.
