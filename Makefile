# AstroTrips Blueprint Example
# All blueprint commands run inside the Airflow scheduler container
# so no local Python/Blueprint installation is needed.

SCHEDULER := $(shell docker ps --filter "name=scheduler" --format "{{.Names}}" | head -1)
BLUEPRINT := docker exec $(SCHEDULER) blueprint
DAGS_DIR := dags
SCHEMA_DIR := blueprint/generated-schemas

.PHONY: help list describe lint schemas clean-schemas start stop restart logs

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# --- Airflow lifecycle ---

start: ## Start the Astro project
	astro dev start

stop: ## Stop the Astro project
	astro dev stop

restart: ## Restart the Astro project
	astro dev restart

logs: ## Tail scheduler logs
	astro dev logs -f scheduler

# --- Blueprint discovery ---

list: ## List all available blueprints
	$(BLUEPRINT) list

describe: ## Describe a blueprint (usage: make describe NAME=ingest_bookings)
	$(BLUEPRINT) describe $(NAME)

# --- Validation ---

lint: ## Lint all Dag YAML files
	@for f in $(DAGS_DIR)/*.dag.yaml; do \
		$(BLUEPRINT) lint $$f; \
	done

# --- Schema generation for Astro IDE ---

schemas: ## Generate all JSON schemas for Astro IDE
	@mkdir -p $(SCHEMA_DIR)
	$(BLUEPRINT) schema setup_database -o $(SCHEMA_DIR)/setup_database.schema.json
	$(BLUEPRINT) schema ingest_bookings -o $(SCHEMA_DIR)/ingest_bookings.schema.json
	$(BLUEPRINT) schema planet_report -o $(SCHEMA_DIR)/planet_report.schema.json
	$(BLUEPRINT) schema data_quality_check -o $(SCHEMA_DIR)/data_quality_check.schema.json
	$(BLUEPRINT) schema weather_ingest -o $(SCHEMA_DIR)/weather_ingest.schema.json
	@echo "Schemas written to $(SCHEMA_DIR)/"

clean-schemas: ## Remove generated schemas
	rm -rf $(SCHEMA_DIR)
