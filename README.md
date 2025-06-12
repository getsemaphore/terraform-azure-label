Terraform module designed to generate consistent names and tags for resources. Use `terraform-azure-label` to implement a strict naming convention.

There are 5 inputs considered "labels" or "ID elements" (because the labels are used to construct the ID):
1. namespace
1. name
1. environment
1. location_short
1. attributes

Example: org-app-prod-frc-01

This module generates IDs using the following convention by default: `{namespace}-{name}-{environment}-{location_short}-{attributes}`
However, it is highly configurable. The delimiter (e.g. `-`) is configurable. Each label item is optional (although you must provide at least one).
- The `attributes` input is actually a list of strings and `{attributes}` expands to the list elements joined by the delimiter.
- If you want the label items in a different order, you can specify that, too, with the `label_order` list.

It's recommended to use one `terraform-azure-label` module for every unique resource of a given resource type.
For example, if you have 10 instances, there should be 10 different labels.
However, if you have multiple different kinds of resources (e.g. instances, security groups, file systems, and elastic ips), then they can all share the same label assuming they are logically related.

## License

<a href="https://opensource.org/licenses/Apache-2.0"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=for-the-badge" alt="License"></a>

<details>
<summary>Preamble to the Apache License, Version 2.0</summary>
<br/>
<br/>

Complete license is available in the [`LICENSE`](LICENSE) file.

```text
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
```
</details>

## Trademarks

All other trademarks referenced herein are the property of their respective owners.

---
Copyright © 2017-2025 [Cloud Posse, LLC](https://cpco.io/copyright)
