# rubocop-harness

Architectural boundary enforcement for Rails apps with agent-readable remediation messages.

Part of the [harness engineering](https://alicia-paz.medium.com/from-spicy-autocompletion-to-agentic-engineering-82f467fcc6ed) toolkit -- custom RuboCop cops that enforce Rails conventions and communicate fixes to both humans and AI coding agents.

## Why

Standard RuboCop tells you *what's wrong*. rubocop-harness tells your AI agent *how to fix it*:

```
# Standard RuboCop
Method has too many lines. [15/10]

# rubocop-harness
[Harness] `create` is 15 lines (max 10). Extract logic into a service
object in app/services/. Use Pattern A (call) or Pattern B (save).
```

Every offense message includes:
- What's wrong
- Where to put the fix
- Which pattern to use

Your linter becomes a communication channel to the robot.

## Installation

Add to your Gemfile:

```ruby
group :development, :test do
  gem "rubocop-harness", github: "TelosLabs/rubocop-harness", require: false
end
```

Then in `.rubocop.yml`:

```yaml
plugins:
  - rubocop-harness
```

## Cops

| Cop | Default | Description |
|-----|---------|-------------|
| `Harness/ControllerMethodLength` | Max: 10 | Controllers should be thin. Extract long methods into service objects. |
| `Harness/ModelMethodLength` | Max: 7 | Models should focus on persistence. Extract business logic into services. |
| `Harness/RestfulActions` | Enabled | Controllers should only define the 7 RESTful actions (index, show, new, create, edit, update, destroy). |
| `Harness/ServiceInterface` | Enabled | Service objects must define a `call` or `save` instance method. |
| `Harness/NoQueriesInControllers` | Enabled | No ActiveRecord query methods in controllers. Move to service objects or model scopes. `find` and `find_by` allowed by default. |

All cops are enabled by default with `warning` severity.

## Configuration

Override any cop in your `.rubocop.yml`:

```yaml
# Adjust method length limits
Harness/ControllerMethodLength:
  Max: 15

Harness/ModelMethodLength:
  Max: 10

# Allow specific non-RESTful actions
Harness/RestfulActions:
  AllowedMethods:
    - search
    - export

# Require only `call` (not `save`)
Harness/ServiceInterface:
  RequiredMethods:
    - call

# Also flag find and find_by
Harness/NoQueriesInControllers:
  AllowedMethods: []
```

## Cop Details

### Harness/ControllerMethodLength

Enforces a maximum method length in `app/controllers/`. Skips concerns.

```ruby
# bad - 11+ lines
def create
  @user = User.new(user_params)
  @user.role = determine_role(params[:role])
  @user.team = Team.find(params[:team_id])
  # ... 8 more lines
end

# good - delegate to a service
def create
  result = CreateUserService.new(user_params).call
  respond_with result
end
```

### Harness/ModelMethodLength

Enforces a maximum method length in `app/models/`. Default max is 7 (stricter than controllers because models should focus on persistence).

### Harness/RestfulActions

Flags any public method in a controller that isn't one of the 7 RESTful actions.

```ruby
# bad
class UsersController < ApplicationController
  def archive  # not RESTful
  end
end

# good - extract to a new controller
class Users::ArchivesController < ApplicationController
  def create
  end
end
```

Private and protected methods are ignored -- helper methods in controllers are fine.

### Harness/ServiceInterface

Services in `app/services/` must define `call` or `save`:

```ruby
# bad
class OrderProcessor < ApplicationService
  def process  # non-standard interface
  end
end

# good - Pattern A
class OrderProcessor < ApplicationService
  def call
    # returns data
  end
end

# good - Pattern B
class OrderCreator < ApplicationService
  def save
    # persists data, returns true/false
  end
end
```

### Harness/NoQueriesInControllers

Flags ActiveRecord query methods (`where`, `joins`, `includes`, `order`, `pluck`, `destroy_all`, etc.) in controller files.

```ruby
# bad
def index
  @users = User.where(active: true).order(:name)
end

# good – use a service object
def index
  @users = ListUsersService.new(filters: params[:filters]).call
end

# good – use model scopes
def index
  @users = User.active.ordered_by_name
end
```

`find` and `find_by` are allowed by default since `@resource = Model.find(params[:id])` is a standard Rails pattern. Set `AllowedMethods: []` to flag them too.

## Design Philosophy

These cops enforce **architectural boundaries**, not style preferences. They fill gaps that rubocop-shopify and rubocop-rails don't cover:

- rubocop-shopify **disables** all Metrics cops. rubocop-harness applies different limits per architectural layer.
- rubocop-rails enforces action **ordering** (`Rails/ActionOrder`). rubocop-harness enforces that only RESTful actions **exist**.
- Neither enforces service object interfaces, query-free controllers, or layer-specific method size limits.

The cop messages are deliberately written for AI agents to parse and act on. When an agent sees `[Harness] ... Move query logic to a service object in app/services/ or a scope in the model.`, it knows exactly what to do without additional context.

## Development

```bash
bundle install
bundle exec rspec
```

## License

MIT
