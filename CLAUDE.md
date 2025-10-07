# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NutriHabits is a Rails 7.1 nutrition management platform that connects nutritionists with their patients. The application uses AI (via ruby_llm gem) to generate personalized nutrition plans and analyze meal photos.

## Key Technologies

- **Rails 7.1.5** with Ruby 3.3.5
- **PostgreSQL** database
- **Devise** for dual authentication (Nutritionist and Patient models)
- **ruby_llm** gem for AI-powered nutrition analysis and plan generation
- **Active Storage** with **Cloudinary** for image storage (meal log photos)
- **Bootstrap 5.3** for UI
- **Hotwire** (Turbo + Stimulus) for frontend interactions

## Essential Commands

### Development Setup
```bash
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

## Architecture Overview

### Core Domain Models

The application has a dual-user system with distinct hierarchies:

**Nutritionist Hierarchy:**
- `Nutritionist` (Devise authenticated)
  - has_many `patients`
  - has_many `nutrition_plans` (through patients)
  - has_many `patient_histories`
  - has_many `nutritionist_ai_chats`

**Patient Hierarchy:**
- `Patient` (Devise authenticated)
  - belongs_to `nutritionist`
  - has_one `profile` (patient health data: weight, height, goals, conditions, lifestyle, diagnosis)
  - has_many `nutrition_plans`
  - has_many `weight_patients` (weight tracking over time)
  - has_many `patient_ai_chats`
  - Access to `meal_logs` through custom method `meal_logs_through_plans` (meal_logs belong to meals, not patients)

**Nutrition Plan System:**
- `NutritionPlan` (main plan with calories, macros, objectives, dates)
  - has_many `plans` (daily execution: date, mood, energy_level, activity, notes)
    - has_many `meals` (meal_type, ingredients, recipe, calories, protein, carbs, fat, status)
      - has_one `meal_log` (AI-analyzed meal photo with Active Storage attachment)

**Chat Systems:**
- `Chat` (nutritionist-patient messaging)
  - has_many `messages`
- Separate AI chat systems for both user types with context and metadata storage

### AI Service Layer

Located in `app/services/`:

1. **`NutritionPlanGeneratorService`**
   - Generates personalized nutrition plans using LLM
   - Takes profile, start_date, end_date
   - Returns structured JSON with daily meal distributions
   - Considers patient history, previous plans, and clinical data
   - Output includes: objective, calories, macros, daily meals (breakfast/lunch/dinner/snacks) with ingredients, recipes, and nutritional breakdown

2. **`MealLogAnalysisService`**
   - Analyzes meal photos using vision-capable LLM (GPT-4o)
   - Takes photo_attachment (Active Storage), meal (with plan and nutrition_plan context)
   - Returns JSON with: ai_calories, ai_protein, ai_carbs, ai_fat, ai_health_score (1-10), ai_feedback, ai_comparison
   - Compares meals against the specific planned meal for that day and meal type

### Authentication & Authorization

- Uses Devise with separate namespaces for `nutritionists` and `patients`
- Nutritionist routes are wrapped in `authenticate :nutritionist` blocks
- Main nutritionist dashboard at `/nutritionist_dashboard`
- Nested resource structure: `nutritionists/:id/patients/:patient_id/...`

### Database Notes

- PostgreSQL with standard Rails conventions
- Most timestamps included via `t.timestamps`
- Foreign keys enforced with `foreign_key: true`
- Weight tracking separated into `weight_patients` table (not using `patient_histories.weight` directly)
- `meals` table recently modified: removed `detail` column, added nutrition fields (ingredients, recipe, calories, protein, carbs, fat)

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
2. Define detailed system prompts with expected JSON structure
3. Parse responses with `JSON.parse(response)`
4. Handle both text rationale and structured data outputs

### Model Relationships

When adding new models related to patients or nutritionists:
- Consider the cascade deletion strategy (`dependent: :destroy` vs `:nullify`)
- Add inverse associations to both models
- Update schema documentation if introducing new patterns

### Routes Structure

Main routing pattern:
```ruby
authenticate :nutritionist do
  resources :patients do
    resources :nested_resource
  end
end
```

## Important Considerations

- The app uses both English (code) and Spanish (UI/AI prompts) - AI prompts and user-facing content are in Spanish
- Cloudinary integration requires proper ENV configuration
- LLM responses are parsed as JSON - always validate structure before persisting (some responses may include markdown code blocks that need stripping)
- Weight tracking uses dedicated `weight_patients` table for historical data points
- Meal nutritional data is stored at meal level, not just plan level
- MealLog photos use Active Storage with Cloudinary backend - access URLs via `photo.blob.url`
