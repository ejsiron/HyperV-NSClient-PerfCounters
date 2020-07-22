# Change Log

## July 21 2020

### BREAKING CHANGES: Changed behavior to write multiple files instead of a singular monolith.

- By default, 50 VMs per performance definition file. Override with -VMsPerFile
- Due to file splitting, the -Append option has been removed. This cmdlet will always overwrite existing files
- When you select VMAsHost, script will emit files just to contain the VMs' host definitions. Each file will contain up to 25 times the value of the VMsPerFile setting.
- "Version" now defaults to 2016

### Non-Breaking Changes

- 2016 mode also includes 2019 and SAC builds
- Fixed failures when running against checkpointed VMs
- Minor script improvements
