# Changelog

## 0.1.0 (Unreleased)

### New cops

- `Harness/ControllerMethodLength` - Enforces maximum method length in controllers.
- `Harness/ModelMethodLength` - Enforces maximum method length in models.
- `Harness/RestfulActions` - Controllers should only define the 7 RESTful actions.
- `Harness/ServiceInterface` - Service objects must define `call` or `save`.
- `Harness/NoQueriesInControllers` - No ActiveRecord queries in controllers.
