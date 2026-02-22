# OPA Helper Functions
package terraform.controltower.helpers

import future.keywords.contains
import future.keywords.if
import future.keywords.in

# ============================================================================
# Resource Query Helpers
# ============================================================================

# Get all resources of a specific type
resources_by_type(type) := [resource |
    resource := input.planned_values.root_module.resources[_]
    resource.type == type
]

# Get all child modules
child_modules := [module |
    module := input.planned_values.root_module.child_modules[_]
]

# Get all resources across all modules
all_resources := array.concat(
    input.planned_values.root_module.resources,
    [resource |
        module := input.planned_values.root_module.child_modules[_]
        resource := module.resources[_]
    ]
)

# ============================================================================
# Tag Helpers
# ============================================================================

# Check if resource has required tags
has_required_tags(resource, required_tags) {
    resource.values.tags
    missing := [tag | tag := required_tags[_]; not resource.values.tags[tag]]
    count(missing) == 0
}

# Get missing tags for a resource
missing_tags(resource, required_tags) := missing {
    resource.values.tags
    missing := [tag | tag := required_tags[_]; not resource.values.tags[tag]]
}

missing_tags(resource, required_tags) := required_tags {
    not resource.values.tags
}

# ============================================================================
# Environment Helpers
# ============================================================================

# Check if resource is in production environment
is_production(resource) {
    contains(lower(resource.values.tags.Environment), "prod")
}

is_production(resource) {
    contains(lower(resource.address), "prod")
}

# ============================================================================
# String Helpers
# ============================================================================

# Convert to lowercase
lower(str) := lower_str {
    lower_str := lower(str)
}
