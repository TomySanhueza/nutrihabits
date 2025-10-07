# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NutriHabits is a Rails 7.1 nutrition management platform that connects nutritionists with their patients. The application uses AI (via ruby_llm gem) to generate personalized nutrition plans and analyze meal photos.

## Key Technologies

- **Rails 7.1.5** with Ruby 3.3.5
- **PostgreSQL** database
- **Devise** for dual authentication (Nutritionist and Patient models)
<<<<<<< HEAD
- **ruby_llm** gem for AI-powered nutrition analysis and plan generation (configured with OpenAI API)
- **Active Storage** with **Cloudinary** for image storage (meal log photos)
- **Bootstrap 5.3** for UI
- **Hotwire** (Turbo + Stimulus) for frontend interactions
- **Simple Form** with Bootstrap integration
=======
- **ruby_llm** gem (v1.8) for AI-powered nutrition analysis and plan generation
- **Cloudinary** for image storage via Active Storage
- **Bootstrap 5.3** for UI
- **Hotwire** (Turbo + Stimulus) for frontend interactions
- **Simple Form** with Bootstrap integration for forms
>>>>>>> main

## Essential Commands

### Development Setup
```bash
bundle install
bin/rails db:create
bin/rails db:migrate
bin/rails server
```

### Database Operations
```bash
bin/rails db:migrate              # Run pending migrations
bin/rails db:rollback             # Rollback last migration
bin/rails db:schema:load          # Load schema from schema.rb
bin/rails generate migration Name # Create new migration
bin/rails generate model Name     # Create model with migration
```

### Testing
```bash
bin/rails test                    # Run all tests
bin/rails test:system             # Run system tests
bin/rails test test/models/model_name_test.rb  # Run specific test
```

### Console & Debugging
```bash
bin/rails console                 # Interactive Rails console
bin/rails routes                  # Show all routes
```

### Credentials Management
```bash
bin/rails credentials:edit        # Edit encrypted credentials (for Cloudinary config)
```

## Architecture Overview

### Core Domain Models

The application has a dual-user system with distinct hierarchies:

**Nutritionist Hierarchy:**
- `Nutritionist` (Devise authenticated with registration enabled)
  - has_many `patients`
  - has_many `nutrition_plans` (through patients)
  - has_many `patient_histories`
  - has_many `nutritionist_ai_chats`
  - has_many `chats` (for patient communication)

**Patient Hierarchy:**
- `Patient` (Devise authenticated, no registration - created by nutritionists)
  - belongs_to `nutritionist`
  - has_one `profile` (patient health data: weight, height, goals, conditions, lifestyle, diagnosis)
  - has_many `nutrition_plans`
  - has_many `meal_logs` (AI-analyzed meal photos)
  - has_many `weight_patients` (weight tracking over time)
  - has_many `patient_ai_chats`
<<<<<<< HEAD
  - has_many `chats` (for nutritionist communication)
  - Access to `meal_logs` through custom method `meal_logs_through_plans` (meal_logs belong to meals, not patients)
  - Access to available meals (without meal_log) via `available_meals` method
=======
>>>>>>> main

**Nutrition Plan System:**
- `NutritionPlan` (main plan with calories, macros, objectives, dates, ai_rationale)
  - has_many `plans` (daily execution: date, mood, energy_level, activity, notes)
    - has_many `meals` (meal_type, ingredients, recipe, calories, protein, carbs, fat, status)
<<<<<<< HEAD
      - has_one `meal_log` (AI-analyzed meal photo with Active Storage attachment: ai_calories, ai_protein, ai_carbs, ai_fat, ai_health_score, ai_feedback, ai_comparison)
=======
>>>>>>> main

**Chat Systems:**
- `Chat` (nutritionist-patient messaging with title, last_read_at)
  - has_many `messages` (content, role)
- `NutritionistAiChat` (AI chat for nutritionists)
  - has_many `nutritionist_ai_messages` (content, role, metadata as jsonb)
  - context stored as jsonb
- `PatientAiChat` (AI chat for patients)
  - has_many `patient_ai_messages` (content, role, metadata as jsonb)
  - context stored as jsonb

### AI Service Layer

Located in `app/services/`:

1. **`NutritionPlanGeneratorService`**
   - Generates personalized nutrition plans using LLM (Spanish prompts)
   - Takes profile, start_date, end_date
   - Returns structured JSON with daily meal distributions
<<<<<<< HEAD
   - Considers patient history, previous plans, and clinical data from profile
   - System prompt references WHO, ADA, ESPEN guidelines
   - Output includes: objective, calories, macros (protein/fat/carbs in grams), meal_distribution hash keyed by date
   - Each meal in distribution includes: ingredients (with portions), recipe (numbered steps), calories, protein, carbs, fat
   - Meal types: breakfast, lunch, dinner, snacks
   - Handles both new patients and plan updates based on historical data

2. **`MealLogAnalysisService`**
   - Analyzes meal photos using vision-capable LLM (GPT-4o)
   - Takes photo_attachment (Active Storage), meal (with plan and nutrition_plan context)
   - Returns JSON with: ai_calories, ai_protein, ai_carbs, ai_fat, ai_health_score (1-10), ai_feedback, ai_comparison
   - Compares meals against the specific planned meal for that day and meal type
   - ai_comparison field is stored as jsonb for structured comparison data
=======
   - Considers patient history, previous plans, and clinical data
   - Output includes: objective, calories, macros, daily meals (breakfast/lunch/dinner/snacks) with ingredients, recipes, and nutritional breakdown
   - Uses default model from RubyLLM configuration

2. **`MealLogAnalysisService`**
   - Analyzes meal photos using vision-capable LLM (GPT-4o)
   - Takes photo_attachment (Active Storage), meal
   - Analyzes Cloudinary URLs from blob.url
   - Returns JSON with: ai_calories, ai_macros (protein/carbs/fat), ai_health_score (1-10), ai_feedback, ai_comparison
   - Compares meals against specific planned meal for that date and meal_type
   - Handles markdown-wrapped JSON responses
>>>>>>> main

### Authentication & Authorization

- Uses Devise with separate namespaces for `nutritionists` and `patients`
- Nutritionists can register (`:registerable`), patients cannot
- Nutritionist routes are wrapped in `authenticate :nutritionist` blocks
- Patient routes are wrapped in `authenticate :patient` blocks
- Main nutritionist dashboard at `/nutritionist_dashboard`
- Nested resource structure for nutritionists: `/patients/:id/profiles`, `/patients/:id/nutrition_plans`, `/patients/:id/patient_histories`
- Nested resource structure for patients: `/meals/:id/meal_logs`
- Root path: `pages#home`

### Database Notes

- PostgreSQL with standard Rails conventions
- All timestamps included via `t.timestamps`
- Foreign keys enforced with `foreign_key: true` on all associations
- Weight tracking separated into `weight_patients` table (patient_id, date, weight) - not using `patient_histories.weight` for time series
- `meals` table stores full nutritional breakdown (ingredients, recipe, calories, protein, carbs, fat)
- `meal_logs` table includes jsonb `ai_comparison` field for structured AI feedback
- AI chat systems use jsonb for `context` and `metadata` fields
- `profiles` table is separate from patients (one-to-one) to keep authentication separate from health data

## Development Patterns

### When Creating Migrations

Always use Rails generators to ensure proper structure:
```bash
bin/rails generate migration AddColumnToTable column:type
bin/rails generate model ModelName field:type field:references
```

After creating migrations, always run:
```bash
bin/rails db:migrate
```

### Working with AI Services

AI services use `RubyLLM.chat` and expect structured JSON responses. Key patterns:

1. Initialize with `@chat = RubyLLM.chat`
2. Define detailed system prompts with expected JSON structure (in Spanish for this app)
3. Parse responses with `JSON.parse(response)`
4. Handle both text rationale and structured data outputs
5. LLM responses may include markdown code blocks (```json) that need stripping before parsing
6. OpenAI API key configured via ENV variable in `config/initializers/ruby_llm.rb`

### Model Relationships

When adding new models related to patients or nutritionists:
- Consider the cascade deletion strategy (`dependent: :destroy` vs `:nullify`)
- Add inverse associations to both models
- Use `accepts_nested_attributes_for` where forms need to create/update related records (see `Plan` model)
- Update schema documentation if introducing new patterns

### Routes Structure

Main routing pattern:
```ruby
authenticate :nutritionist do
  resources :patients do
    resources :nested_resource
  end
end

authenticate :patient do
  resources :meals do
    resources :meal_logs
  end
end
```

### Active Storage Configuration

- Development and production use Cloudinary (configured in `config/storage.yml`)
- Test environment uses local disk storage
- Cloudinary credentials stored in Rails encrypted credentials (access via `bin/rails credentials:edit`)
- Access uploaded file URLs via `photo.blob.url` (returns Cloudinary URL in dev/prod)
- MealLog model uses `has_one_attached :photo` for meal photos

## Important Considerations

<<<<<<< HEAD
- **Bilingual codebase**: Code is in English, but UI and AI prompts are in Spanish
- **Environment variables required**:
  - `OPENAI_API_KEY` for ruby_llm gem
  - Cloudinary credentials in Rails encrypted credentials (cloud_name, api_key, api_secret)
- **JSON parsing**: LLM responses often include markdown code blocks that must be stripped before `JSON.parse`
- **Weight tracking**: Use `weight_patients` table for historical data, not `patient_histories.weight`
- **Meal data storage**: Nutritional data (calories, protein, carbs, fat) stored at meal level, not just plan level
- **Nested attributes**: `Plan` model accepts nested attributes for meals with `allow_destroy: true`
- **Custom model methods**:
  - `Patient#meal_logs_through_plans` - queries meal_logs through the association chain
  - `Patient#available_meals` - finds meals without associated meal_log (left join)
- **No direct patient registration**: Patients are created by nutritionists, not through Devise registration
=======
- The app uses both English (code) and Spanish (UI/AI prompts) - AI prompts and user-facing content are in Spanish
- Cloudinary integration requires proper ENV configuration (CLOUDINARY_URL)
- LLM responses are parsed as JSON - always validate structure before persisting
- LLM configuration requires OPENAI_API_KEY in ENV (see `config/initializers/ruby_llm.rb`)
- Weight tracking uses dedicated `weight_patients` table for historical data points
- Meal nutritional data is stored at meal level, not just plan level
- Patient model has helper methods: `meal_logs_through_plans` and `available_meals` for complex associations
- Active Storage is used for image attachments (meal photos) with Cloudinary as backend
>>>>>>> main
