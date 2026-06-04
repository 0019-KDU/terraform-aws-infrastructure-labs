# Terraform Meta-Arguments

Meta-arguments are special arguments that can be used inside any `resource` or `module` block. They are not specific to a provider — they are built into Terraform itself and change **how** Terraform manages a resource, not **what** it creates.

---

## Overview

| Meta-Argument | Purpose | Returns |
|---|---|---|
| `count` | Create N copies of a resource using an index | List (accessed by index `[0]`, `[1]`) |
| `for_each` | Create one resource per item in a map or set | Map (accessed by key `each.key`, `each.value`) |
| `depends_on` | Force explicit dependency between resources | Nothing — only controls order |
| `lifecycle` | Control create/destroy/update behavior | Nothing — only controls behavior |
| `provider` | Override which provider instance to use | Nothing — only controls routing |

This lesson focuses on `count`, `for_each`, and `depends_on`.

---

## 1. `count`

### What it does
Creates **N identical (or near-identical) copies** of a resource. Each copy is identified by its index (`count.index` starts at 0).

### Syntax
```hcl
resource "aws_s3_bucket" "bucket1" {
  count  = 2
  bucket = var.bucket_name[count.index]
  tags   = var.resource_tags
}
```

### How resources are referenced
```hcl
aws_s3_bucket.bucket1[0]   # first bucket
aws_s3_bucket.bucket1[1]   # second bucket
aws_s3_bucket.bucket1[*]   # all buckets (splat expression)
```

### When to use
- You need a **fixed number** of identical or near-identical resources
- The number is known at plan time (not dynamic)
- You are iterating over a **list** (ordered, index-based)
- Simple repetition: create 3 subnets, 2 EC2 instances, etc.

### Benefits
- Simple and readable for fixed counts
- Easy conditional creation: `count = var.create_resource ? 1 : 0`
- Works well with list variables

### Limitations
- If you **remove an item from the middle** of a list, all resources after it get re-indexed — Terraform will **destroy and recreate** them
- All copies share the same configuration structure (only index differs)
- Not suitable when items have distinct identities (use `for_each` instead)

### Best Practices
- Use `count` only when the number is static or conditionally 0/1
- Avoid `count` on ordered lists where items may be inserted or removed — use `for_each` instead
- Use `count = var.enable_feature ? 1 : 0` as a clean on/off toggle for optional resources

---

## 2. `for_each`

### What it does
Creates **one resource per item** in a `map` or `set`. Each copy is identified by its **key** (`each.key`) and can access its **value** (`each.value`).

### Syntax
```hcl
resource "aws_s3_bucket" "bucket2" {
  for_each = var.bucket_name_set

  bucket     = each.key
  tags       = var.resource_tags
  depends_on = [aws_s3_bucket.bucket1]
}
```

### How resources are referenced
```hcl
aws_s3_bucket.bucket2["dev-bucket"]    # by key name
aws_s3_bucket.bucket2["prod-bucket"]
```

### When to use
- You are iterating over a **map or set** (key-based, not index-based)
- Each resource has a **unique identity** (name, ID, environment)
- The set of resources may change — items can be added/removed safely
- You need to pass different values per resource (use a map of objects)

### Benefits
- **Safe to add/remove items** — only the changed resource is affected, others are untouched
- Resources are identified by meaningful keys, not fragile indexes
- Works with complex maps: `map(object({ ... }))` for rich per-resource config
- Easier to read in `terraform plan` output (shows key name, not `[0]`, `[1]`)

### Limitations
- Cannot use a list directly — must convert to set (`toset()`) or map
- All values in a set must be unique
- `each.value` is the full value for map types; for sets, `each.key == each.value`

### Best Practices
- Prefer `for_each` over `count` whenever resources have distinct identities
- Use `toset()` to convert a list of strings to a set: `for_each = toset(var.names)`
- Use a `map(object(...))` when each resource needs different configuration
- Keep keys stable — changing a key destroys and recreates the resource

---

## 3. `depends_on`

### What it does
Explicitly tells Terraform to **wait until another resource is fully created** before creating this one. Terraform usually figures out dependencies automatically from references, but sometimes that is not possible.

### Syntax
```hcl
resource "aws_s3_bucket" "bucket2" {
  for_each   = var.bucket_name_set
  bucket     = each.key
  depends_on = [aws_s3_bucket.bucket1]
}
```

### When to use
- A resource depends on a **side effect** of another resource (not a direct attribute reference)
- Working with **IAM policies** that must exist before an EC2 instance that uses them
- A resource needs to wait for **data to be populated** by another resource (e.g., a database seed script)
- Module-to-module dependencies that Terraform cannot infer automatically
- Working with `null_resource` or `local-exec` provisioners

### Benefits
- Guarantees correct **creation and destruction order**
- Prevents race conditions in complex architectures
- Works across modules and resource types

### Limitations
- Overusing `depends_on` makes plans slower — Terraform must wait even when it could parallelize
- Can hide poor architecture — if you need it on every resource, consider refactoring
- Does not replace proper attribute references — if resource B uses an output of resource A, Terraform already knows the dependency implicitly

### Best Practices
- Use `depends_on` as a **last resort** — prefer implicit dependencies via attribute references
- Document WHY the explicit dependency is needed (it is often non-obvious)
- Avoid creating long chains of `depends_on` — this forces sequential execution and slows applies

---

## count vs for_each — When to Choose Which

| Scenario | Use |
|---|---|
| Create 3 identical subnets | `count = 3` |
| Toggle a resource on/off | `count = var.enabled ? 1 : 0` |
| Create one bucket per environment name | `for_each = toset(["dev", "staging", "prod"])` |
| Create resources with different configs per item | `for_each = var.config_map` |
| List items may be added/removed later | `for_each` (safe re-indexing) |
| Simple numeric repetition, list won't change | `count` |

### Key difference: how Terraform tracks state

```
# count — tracked by index (fragile)
aws_s3_bucket.bucket1[0]
aws_s3_bucket.bucket1[1]

# for_each — tracked by key (stable)
aws_s3_bucket.bucket2["dev-bucket"]
aws_s3_bucket.bucket2["prod-bucket"]
```

If you remove `bucket_name[0]` from a `count` list, `[1]` becomes `[0]` — Terraform destroys and recreates it.
If you remove `"dev-bucket"` from a `for_each` set, only that resource is destroyed — others are untouched.

---

## This Lesson's Example

```hcl
# bucket1 — uses count, creates 2 buckets from a list
resource "aws_s3_bucket" "bucket1" {
  count  = 2
  bucket = var.bucket_name[count.index]
  tags   = var.resource_tags
}

# bucket2 — uses for_each, creates one bucket per set item
#          uses depends_on to wait for bucket1 to exist first
resource "aws_s3_bucket" "bucket2" {
  for_each   = var.bucket_name_set
  bucket     = each.key
  tags       = var.resource_tags
  depends_on = [aws_s3_bucket.bucket1]
}
```

| Resource | Meta-Argument | Why |
|---|---|---|
| `bucket1` | `count = 2` | Creates 2 S3 buckets from an indexed list |
| `bucket2` | `for_each` | Creates one bucket per unique name in the set |
| `bucket2` | `depends_on` | Ensures `bucket1` is fully created before `bucket2` starts |

---

## Summary

- Use **`count`** for simple numeric repetition or conditional on/off resources
- Use **`for_each`** when resources have distinct identities and the set may change over time
- Use **`depends_on`** only when Terraform cannot detect the dependency automatically
- **Never mix `count` and `for_each`** on the same resource block
- Prefer `for_each` over `count` in most real-world scenarios for safer state management
