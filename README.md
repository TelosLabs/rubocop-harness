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
object in app/services/.
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
| `Harness/ModelMethodLength` | Max: 7 | Models own domain logic, but methods should be small. Decompose into smaller methods, concerns, or value objects. |
| `Harness/RestfulActions` | Enabled | Controllers should only define the 7 RESTful actions (index, show, new, create, edit, update, destroy). |
| `Harness/ServiceInterface` | Enabled | Service objects must define a `call` or `save` instance method. |
| `Harness/NoQueriesInControllers` | Enabled | No ActiveRecord query methods in controllers. Move to model scopes or query objects. `find` and `find_by` allowed by default. |
| `Harness/JobMethodLength` | Max: 7 | Jobs should be thin. Delegate to a service object. |
| `Harness/NoPresentationInModels` | Enabled | No presentation logic (HTML, route helpers) in models. Move to presenters or view helpers. |

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

Enforces a maximum method length in `app/models/`. Default max is 7 (stricter than controllers because model methods should be small and focused). Models own domain logic, but long methods should be decomposed into smaller private methods, concerns, or value objects.

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

Flags ActiveRecord query methods (`where`, `joins`, `includes`, `order`, `pluck`, `destroy_all`, etc.) in controller files. Controllers are the presentation layer — query construction belongs in the domain layer (model scopes) or application layer (services).

```ruby
# bad — query building in the controller
def index
  @users = User.where(active: true).order(:name)
end

# good — model scope (preferred for simple filtering/ordering)
def index
  @users = User.active.ordered_by_name
end

# good — service object (for multi-model orchestration or side effects)
def index
  @users = ListUsersService.new(filters: params[:filters]).call
end
```

`find` and `find_by` are allowed by default since `@resource = Model.find(params[:id])` is a standard Rails pattern. Set `AllowedMethods: []` to flag them too.

### Harness/JobMethodLength

Enforces a maximum method length in `app/jobs/`. Jobs should delegate to services, not contain business logic.

```ruby
# bad - business logic in the job
def perform(user_id)
  user = User.find(user_id)
  user.update!(onboarded: true)
  WelcomeMailer.with(user: user).welcome.deliver_later
  Analytics.track("user_onboarded", user_id: user.id)
  user.projects.create!(name: "My First Project")
  Slack::NotifyChannel.call("#signups", "New user: #{user.email}")
  AuditLog.record(:onboard, user: user)
  user.update!(onboarded_at: Time.current)
end

# good - delegate to a service
def perform(user_id)
  user = User.find(user_id)
  OnboardUserService.new(user).call
end
```

### Harness/NoPresentationInModels

Flags presentation logic in models — HTML generation, route helpers, and ActionController helpers belong in presenters, decorators, or view helpers, not in the domain layer.

```ruby
# bad - HTML in the model
def badge
  content_tag(:span, role_name, class: "badge")
end

# bad - route helpers in the model
class User < ApplicationRecord
  include Rails.application.routes.url_helpers
end

# good - use a presenter
class UserPresenter
  def badge
    content_tag(:span, user.role_name, class: "badge")
  end
end
```

## Design Philosophy

These cops enforce **layered architecture boundaries**, not style preferences. Inspired by [Layered Design for Ruby on Rails Applications](https://www.packtpub.com/en-us/product/layered-design-for-ruby-on-rails-applications-9781801813785) (Dementyev, 2023), they ensure code stays in the right layer:

- **Presentation layer** (controllers/views): request handling only — no query building, no business logic
- **Application layer** (services): orchestration across models, external integrations, side effects
- **Domain layer** (models): business rules, validations, scopes, state transitions

These cops fill gaps that rubocop-shopify and rubocop-rails don't cover:

- rubocop-shopify **disables** all Metrics cops. rubocop-harness applies different limits per architectural layer.
- rubocop-rails enforces action **ordering** (`Rails/ActionOrder`). rubocop-harness enforces that only RESTful actions **exist**.
- Neither enforces service object interfaces, query-free controllers, or layer-specific method size limits.

The cop messages are deliberately written for AI agents to parse and act on. When an agent sees `[Harness] ... Move query logic to a model scope or query object.`, it knows exactly what to do without additional context.

## Development

```bash
bundle install
bundle exec rspec
```

## License

MIT
