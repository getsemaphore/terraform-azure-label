# This module provides common context and naming conventions
# It doesn't create any resources, just transforms and standardizes inputs
# for use by other modules following DRY principles. 

locals {

  defaults = {
    label_order         = ["namespace", "name", "environment", "location_short", "attributes"]
    regex_replace_chars = "/[^-a-zA-Z0-9]/"
    delimiter           = "-"
    replacement         = ""
    id_length_limit     = 0
    id_hash_length      = 5
    label_key_case      = "title"
    label_value_case    = "lower"
  }

  azure_location_shortcodes = {
    "France Central"       = "frc"
    "France South"         = "frs"
    "East US"              = "eus"
    "East US 2"            = "eus2"
    "West US"              = "wus"
    "West US 2"            = "wus2"
    "West US 3"            = "wus3"
    "Central US"           = "cus"
    "North Central US"     = "ncus"
    "South Central US"     = "scus"
    "Brazil South"         = "brs"
    "Brazil Southeast"     = "brse"
    "Canada Central"       = "cac"
    "Canada East"          = "cae"
    "UK South"             = "uks"
    "UK West"              = "ukw"
    "Germany West Central" = "gwc"
    "Germany North"        = "gn"
    "Switzerland North"    = "chn"
    "Switzerland West"     = "chw"
    "Norway East"          = "noe"
    "Norway West"          = "now"
    "North Europe"         = "neu"
    "West Europe"          = "weu"
    "South Africa North"   = "zan"
    "South Africa West"    = "zaw"
    "UAE North"            = "uaen"
    "UAE Central"          = "uaec"
    "Japan East"           = "jpe"
    "Japan West"           = "jpw"
    "Korea Central"        = "krc"
    "Korea South"          = "krs"
    "Australia East"       = "aue"
    "Australia Southeast"  = "ause"
    "Australia Central"    = "auc"
    "Australia Central 2"  = "auc2"
    "Southeast Asia"       = "sea"
    "East Asia"            = "ea"
    "India Central"        = "inc"
    "India South"          = "ins"
    "India West"           = "inw"
    "China North"          = "chn"
    "China East"           = "che"
    "China North 2"        = "chn2"
    "China East 2"         = "che2"
  }

  # So far, we have decided not to allow overriding replacement or id_hash_length
  replacement    = local.defaults.replacement
  id_hash_length = local.defaults.id_hash_length

  # The values provided by variables supersede the values inherited from the context object,
  # except for tags and attributes which are merged.
  input = {
    enabled     = var.enabled == null ? var.context.enabled : var.enabled
    namespace   = var.namespace == null ? var.context.namespace : var.namespace
    environment = var.environment == null ? var.context.environment : var.environment
    location    = var.location == null ? var.context.location : var.location
    name        = var.name == null ? var.context.name : var.name
    delimiter   = var.delimiter == null ? var.context.delimiter : var.delimiter
    # modules tack on attributes (passed by var) to the end of the list (passed by context)
    attributes = compact(distinct(concat(coalesce(var.context.attributes, []), coalesce(var.attributes, []))))
    tags       = merge(var.context.tags, var.tags)

    additional_tag_map  = merge(var.context.additional_tag_map, var.additional_tag_map)
    label_order         = var.label_order == null ? var.context.label_order : var.label_order
    regex_replace_chars = coalesce(var.context.regex_replace_chars, local.defaults.regex_replace_chars)
    id_length_limit     = coalesce(var.context.id_length_limit, local.defaults.id_length_limit)
    label_key_case      = coalesce(var.context.label_key_case, local.defaults.label_key_case)
    label_value_case    = coalesce(var.context.label_value_case, local.defaults.label_value_case)
  }

  enabled             = local.input.enabled
  regex_replace_chars = local.input.regex_replace_chars

  # Convert location to location_short using azure_location_shortcodes
  location_short = local.input.location != null ? lookup(local.azure_location_shortcodes, local.input.location, lower(replace(local.input.location, "/[^a-zA-Z0-9]/", ""))) : ""

  # string_label_names are names of inputs that are strings (not list of strings) used as labels
  string_label_names = ["namespace", "environment", "location", "location_short", "name"]
  normalized_labels = { for k in local.string_label_names : k =>
    k == "location_short" ? local.location_short : (
      local.input[k] == null ? "" : replace(local.input[k], local.regex_replace_chars, local.replacement)
    )
  }
  normalized_attributes = compact(distinct([for v in local.input.attributes : replace(v, local.regex_replace_chars, local.replacement)]))

  formatted_labels = { for k in local.string_label_names : k => local.label_value_case == "none" ? local.normalized_labels[k] :
    local.label_value_case == "title" ? title(lower(local.normalized_labels[k])) :
    local.label_value_case == "upper" ? upper(local.normalized_labels[k]) : lower(local.normalized_labels[k])
  }

  attributes = compact(distinct([
    for v in local.normalized_attributes : (local.label_value_case == "none" ? v :
      local.label_value_case == "title" ? title(lower(v)) :
    local.label_value_case == "upper" ? upper(v) : lower(v))
  ]))

  namespace      = local.formatted_labels["namespace"]
  environment    = local.formatted_labels["environment"]
  location       = local.formatted_labels["location"]
  name           = local.formatted_labels["name"]

  delimiter        = local.input.delimiter == null ? local.defaults.delimiter : local.input.delimiter
  label_order      = local.input.label_order == null ? local.defaults.label_order : coalescelist(local.input.label_order, local.defaults.label_order)
  id_length_limit  = local.input.id_length_limit
  label_key_case   = local.input.label_key_case
  label_value_case = local.input.label_value_case

  additional_tag_map = local.input.additional_tag_map

  tags = merge(local.generated_tags, local.input.tags)

  tags_context = {
    namespace      = local.namespace
    environment    = local.environment
    location       = local.location
    location_short = local.location_short
    # For AWS we need `Name` to be disambiguated since it has a special meaning
    name       = local.id
    attributes = local.id_context.attributes
  }

  generated_tags = {
    for l in keys(local.tags_context) :
    local.label_key_case == "upper" ? upper(l) : (
      local.label_key_case == "lower" ? lower(l) : title(lower(l))
    ) => local.tags_context[l] if length(local.tags_context[l]) > 0
  }

  id_context = {
    namespace      = local.namespace
    environment    = local.environment
    location       = local.location
    location_short = local.location_short
    name           = local.name
    attributes     = join(local.delimiter, local.attributes)
  }

  labels = [for l in local.label_order : local.id_context[l] if length(local.id_context[l]) > 0]

  id_full = join(local.delimiter, local.labels)
  # Create a truncated ID if needed
  delimiter_length = length(local.delimiter)
  # Calculate length of normal part of ID, leaving room for delimiter and hash
  id_truncated_length_limit = local.id_length_limit - (local.id_hash_length + local.delimiter_length)
  # Truncate the ID and ensure a single (not double) trailing delimiter
  id_truncated = local.id_truncated_length_limit <= 0 ? "" : "${trimsuffix(substr(local.id_full, 0, local.id_truncated_length_limit), local.delimiter)}${local.delimiter}"
  # Support usages that disallow numeric characters. Would prefer tr 0-9 q-z but Terraform does not support it.
  id_hash_plus = "${md5(local.id_full)}qrstuvwxyz"
  id_hash_case = local.label_value_case == "title" ? title(local.id_hash_plus) : local.label_value_case == "upper" ? upper(local.id_hash_plus) : local.label_value_case == "lower" ? lower(local.id_hash_plus) : local.id_hash_plus
  id_hash      = replace(local.id_hash_case, local.regex_replace_chars, local.replacement)
  # Create the short ID by adding a hash to the end of the truncated ID
  id_short = substr("${local.id_truncated}${local.id_hash}", 0, local.id_length_limit)
  id       = local.id_length_limit != 0 && length(local.id_full) > local.id_length_limit ? local.id_short : local.id_full

  # Context of this label to pass to other label modules
  output_context = {
    enabled             = local.enabled
    namespace           = local.namespace
    environment         = local.environment
    location            = local.location
    name                = local.name
    delimiter           = local.delimiter
    attributes          = local.attributes
    tags                = local.tags
    additional_tag_map  = local.additional_tag_map
    label_order         = local.label_order
    regex_replace_chars = local.regex_replace_chars
    id_length_limit     = local.id_length_limit
    label_key_case      = local.label_key_case
    label_value_case    = local.label_value_case
  }

} 